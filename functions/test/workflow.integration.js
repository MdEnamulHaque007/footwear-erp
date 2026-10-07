'use strict';
const test=require('node:test');const assert=require('node:assert/strict');
const fs=require('node:fs');const path=require('node:path');
const {initializeTestEnvironment,assertFails}=require('@firebase/rules-unit-testing');
const {doc,setDoc}=require('firebase/firestore');
const {getFirestore,Timestamp}=require('firebase-admin/firestore');
const {mutateBusiness,bootstrapAdmin}=require('../workflow');
const {recordActivity}=require('../index');
let env,db;
const auth=uid=>({uid,token:{email:`${uid}@example.com`,name:uid}});
const request=(collection,action,id,data,uid='admin')=>({auth:auth(uid),data:{collection,action,id,data}});
const date='2026-10-07T00:00:00Z';
const master=(tagNo,q=100,value=1000)=>({tagNo,masterLcDate:date,masterLcQuantity:q,masterLcValue:value});
const po=(tagNo,poNo,q=100)=>({tagNo,poNo,poDate:date,company:'Company',project:'Project',lineItems:[{article:'A',color:'B',poQuantity:q,unitPrice:1}]});
const stage=(tagNo,poNo,collection,q)=>({tagNo,poNo,article:'A',color:'B',voucherNo:collection+'-1',unitPrice:1,[{cuttings:'cuttingDate',sewings:'sewingDate',productions:'productionDate',issues:'issueDate',exports:'exportDate'}[collection]]:date,[{cuttings:'cuttingQuantity',sewings:'sewingQuantity',productions:'quantity',issues:'issueQuantity',exports:'exportQuantity'}[collection]]:q});
test.before(async()=>{
 env=await initializeTestEnvironment({projectId:'demo-footwear-activity',firestore:{rules:fs.readFileSync(path.join(__dirname,'../../firestore.rules'),'utf8')}});db=getFirestore();
 await db.doc('users/admin').set({role:'admin',isActive:true,email:'admin@example.com',displayName:'Administrator'});
 await db.doc('users/editor').set({role:'editor',isActive:true,email:'editor@example.com',displayName:'Editor',permissions:{cutting:{create:true,edit:true,delete:true,view:true}}});
 await db.doc('users/disabled').set({role:'admin',isActive:false});
});
test.after(async()=>env?.cleanup());
async function chain(prefix){await mutateBusiness(db,request('master_lc','create',prefix,master(prefix)));await mutateBusiness(db,request('purchase_orders','create',prefix,po(prefix,prefix)));for(const collection of ['cuttings','sewings','productions'])await mutateBusiness(db,request(collection,'create',prefix,stage(prefix,prefix,collection,100)));}
test('client writes and self-selected admin registration are denied',async()=>{
 const client=env.authenticatedContext('editor',{email:'editor@example.com'}).firestore();
 await assertFails(setDoc(doc(client,'cuttings/direct'),stage('T1','P1','cuttings',10)));
 await assertFails(setDoc(doc(client,'_system/workflow'),{version:0}));
 const fresh=env.authenticatedContext('new-user',{email:'new@example.com'}).firestore();await assertFails(setDoc(doc(fresh,'users/new-user'),{role:'admin',isActive:true,displayName:'Fake',email:'new@example.com'}));
});
test('concurrent issue entries cannot overconsume the same production balance',async()=>{
 await chain('concurrent');
 const results=await Promise.allSettled([1,2].map(i=>mutateBusiness(db,request('issues','create',`concurrent-${i}`,stage('concurrent','concurrent','issues',70)))));
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);
 assert.match(results.find(r=>r.status==='rejected').reason.message,/exceeds/);
 const records=await db.collection('issues').where('poNo','==','concurrent').get();assert.equal(records.docs.reduce((t,d)=>t+d.data().issueQuantity,0),70);
});
test('concurrent POs cannot exceed one Master LC',async()=>{
 await mutateBusiness(db,request('master_lc','create','po-race',master('po-race',100,100)));
 const results=await Promise.allSettled([1,2].map(i=>mutateBusiness(db,request('purchase_orders','create',`po-race-${i}`,po('po-race',`PO-RACE-${i}`,70)))));
 assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.match(results.find(r=>r.status==='rejected').reason.message,/exceeds Master LC/);
});
test('upstream edit/delete and Master LC shrink are rejected with downstream data',async()=>{
 await chain('downstream');await mutateBusiness(db,request('issues','create','downstream',stage('downstream','downstream','issues',60)));
 await assert.rejects(mutateBusiness(db,request('productions','delete','downstream')),/exceeds/);
 await assert.rejects(mutateBusiness(db,request('productions','update','downstream',stage('downstream','downstream','productions',50))),/exceeds/);
 await assert.rejects(mutateBusiness(db,request('master_lc','update','downstream',master('downstream',50))),/exceeds/);
 await assert.rejects(mutateBusiness(db,request('purchase_orders','delete','downstream')),/production entries/);
 assert.equal((await db.doc('productions/downstream').get()).data().quantity,100);
});
test('permission checks run in the server transaction; disabled/admin cannot bypass',async()=>{
 await assert.rejects(mutateBusiness(db,request('master_lc','create','denied',master('denied'),'editor')),/permission/);
 await assert.rejects(mutateBusiness(db,request('master_lc','create','disabled',master('disabled'),'disabled')),/permission/);
 await assert.rejects(mutateBusiness(db,{data:{}}),/Sign in/);
});
test('serial numbers/creation date are preserved and history keeps the real caller',async()=>{
 await mutateBusiness(db,request('master_lc','create','metadata',master('metadata')));
 const before=await db.doc('master_lc/metadata').get();
 await mutateBusiness(db,request('master_lc','update','metadata',{...master('metadata',200),sl:999,createdAt:'forged'}));
 const after=await db.doc('master_lc/metadata').get();assert.equal(after.data().sl,before.data().sl);assert.equal(after.data().createdAt.toMillis(),before.data().createdAt.toMillis());
 const logs=await db.collection('audit_logs').where('documentPath','==','master_lc/metadata').get();assert.equal(logs.size,2);assert.ok(logs.docs.every(d=>d.data().actorUid==='admin'&&d.data().source==='server_crud'));
 await recordActivity.run({id:'duplicate-trigger',time:'2026-10-07T00:00:00Z',authType:'system',params:{documentPath:after.ref.path},data:{before,after}});
 assert.equal((await db.collection('audit_logs').where('documentPath','==',after.ref.path).get()).size,2);
});
test('server delete history is not duplicated by the Firestore trigger',async()=>{
 await mutateBusiness(db,request('master_lc','create','deletable',master('deletable')));
 const before=await db.doc('master_lc/deletable').get();await mutateBusiness(db,request('master_lc','delete','deletable'));const after=await before.ref.get();
 await recordActivity.run({id:'delete-trigger',time:'2026-10-07T00:00:00Z',authType:'system',params:{documentPath:before.ref.path},data:{before,after}});
 const logs=await db.collection('audit_logs').where('documentPath','==',before.ref.path).get();assert.equal(logs.size,2);assert.ok(logs.docs.some(d=>d.data().action==='delete'&&d.data().actorUid==='admin'));
});
test('bootstrap requires owner claim, respects existing admins, and only one concurrent claimant wins',async()=>{
 await assert.rejects(bootstrapAdmin(db,{auth:auth('owner1'),data:{displayName:'Owner'}}),/erpBootstrap/);
 const owner=uid=>({auth:{uid,token:{erpBootstrap:true,email:`${uid}@example.com`}},data:{displayName:'Owner'}});
 await assert.rejects(bootstrapAdmin(db,owner('owner1')),/already exists/);
 await db.doc('users/admin').delete();await db.doc('users/disabled').delete();
 const results=await Promise.allSettled(['owner1','owner2'].map(uid=>bootstrapAdmin(db,owner(uid))));assert.equal(results.filter(r=>r.status==='fulfilled').length,1);assert.equal((await db.collection('users').where('role','==','admin').get()).size,1);
});

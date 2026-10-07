'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertSucceeds, assertFails} = require('@firebase/rules-unit-testing');
const {doc, setDoc, getDocs, collection, updateDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
const {getFirestore} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const {recordActivity} = require('../index');
const {eventLogId} = require('../activity');
const projectId = 'demo-footwear-activity';
let env;
test.before(async () => {
  env = await initializeTestEnvironment({projectId,firestore:{rules:fs.readFileSync(path.join(__dirname,'../../firestore.rules'),'utf8')}});
  await getAuth().createUser({uid:'editor',email:'editor@example.com',displayName:'Editor'});
  await env.withSecurityRulesDisabled(async context => {
    const db=context.firestore();
    await setDoc(doc(db,'users/admin'),{role:'admin',isActive:true,email:'admin@example.com',displayName:'Admin'});
    await setDoc(doc(db,'users/editor'),{role:'editor',isActive:true,email:'editor@example.com',displayName:'Editor',permissions:{cutting:{view:true,create:true,edit:true,delete:true}}});
    await setDoc(doc(db,'users/viewer'),{role:'viewer',isActive:true,email:'viewer@example.com',displayName:'Viewer',permissions:{}});
  });
});
test.after(async()=>env?.cleanup());
function readPayload(uid='editor') {
  return {schemaVersion:1,source:'app_read',action:'read',module:'cutting',operation:'getCuttingList',documentId:'',actorUid:uid,actorName:'Editor',actorEmail:'editor@example.com',status:'success',resultCount:1,createdAt:serverTimestamp()};
}
test('active editor can append own read log but cannot forge write/actor/time/fields', async () => {
  const db=env.authenticatedContext('editor',{email:'editor@example.com'}).firestore();
  await assertSucceeds(setDoc(doc(db,'audit_logs/read-ok'),readPayload()));
  for (const [id,patch] of Object.entries({actor:{actorUid:'admin'},action:{action:'delete'},source:{source:'firestore_trigger'},time:{createdAt:new Date('2000-01-01')},fields:{before:{secret:'x'}},email:{actorEmail:'admin@example.com'}})) {
    await assertFails(setDoc(doc(db,`audit_logs/forged-${id}`),{...readPayload(),...patch}));
  }
});
test('logs are admin-readable and immutable even for an admin', async () => {
  const admin=env.authenticatedContext('admin',{email:'admin@example.com'}).firestore();
  const editor=env.authenticatedContext('editor',{email:'editor@example.com'}).firestore();
  await assertSucceeds(getDocs(collection(admin,'audit_logs')));
  await assertFails(getDocs(collection(editor,'audit_logs')));
  await assertFails(updateDoc(doc(admin,'audit_logs/read-ok'),{actorUid:'another'}));
  await assertFails(deleteDoc(doc(admin,'audit_logs/read-ok')));
  await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(),'audit_logs/anonymous'),readPayload()));
});
test('real Firestore C/U/D snapshots run through the production trigger and retain history once', async () => {
  const db=getFirestore();
  const ref=db.doc('cuttings/trigger-record');
  let before=await ref.get();
  await ref.set({voucherNo:'C-1',quantity:10});
  let after=await ref.get();
  const event=(id,b,a)=>({id,time:'2026-10-07T07:00:00Z',authId:'editor',authType:'unknown',params:{documentPath:ref.path},data:{before:b,after:a}});
  await recordActivity.run(event('create-test',before,after));
  await recordActivity.run(event('create-test',before,after));
  const created=(await db.doc(`audit_logs/${eventLogId('create-test')}`).get()).data();
  assert.equal(created.actorUid,'editor'); assert.equal(created.actorName,'Editor'); assert.equal(created.actorEmail,'editor@example.com');
  assert.equal(created.action,'create'); assert.equal(created.after.quantity,10);
  before=after; await ref.update({quantity:20}); after=await ref.get();
  await recordActivity.run(event('update-test',before,after));
  const updated=(await db.doc(`audit_logs/${eventLogId('update-test')}`).get()).data();
  assert.equal(updated.before.quantity,10); assert.equal(updated.after.quantity,20);
  before=after; await ref.delete(); after=await ref.get();
  await recordActivity.run(event('delete-test',before,after));
  const deleted=(await db.doc(`audit_logs/${eventLogId('delete-test')}`).get()).data();
  assert.equal(deleted.action,'delete'); assert.equal(deleted.before.quantity,20);
  assert.equal((await db.collection('audit_logs').where('eventId','==','create-test').get()).size,1);
});

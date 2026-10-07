'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {buildActivity, moduleForPath, persistActivity, eventLogId} = require('../activity');
const base = {eventId:'event-1',path:'cuttings/a',authId:'u1',authType:'unknown',actor:{uid:'u1',displayName:'Enamul',email:'a@example.com'},createdAt:'2026-10-07'};

test('create has authenticated actor, record label and after snapshot', () => {
  const log = buildActivity({...base,before:null,after:{voucherNo:'C-1',quantity:10}});
  assert.equal(log.action,'create'); assert.equal(log.module,'cutting');
  assert.equal(log.actorUid,'u1'); assert.equal(log.actorName,'Enamul');
  assert.equal(log.recordLabel,'C-1'); assert.equal(log.before,null);
  assert.deepEqual(log.after,{voucherNo:'C-1',quantity:10});
});
test('update records before, after, removed keys and nested changes', () => {
  const log=buildActivity({...base,before:{quantity:10,note:'old',permissions:{cutting:{view:true}}},after:{quantity:20,permissions:{cutting:{view:false}}}});
  assert.equal(log.action,'update'); assert.deepEqual(log.changedFields,['quantity','note','permissions']);
  assert.equal(log.before.quantity,10); assert.equal(log.after.quantity,20);
});
test('delete retains the removed record', () => {
  const log=buildActivity({...base,before:{voucherNo:'C-1',quantity:10},after:null});
  assert.equal(log.action,'delete'); assert.equal(log.after,null); assert.equal(log.before.quantity,10);
});
test('no-op changes and absent snapshots create no log', () => {
  assert.equal(buildActivity({...base,before:{q:1},after:{q:1}}),null);
  assert.equal(buildActivity({...base,before:null,after:null}),null);
});
test('all business modules, roles, users, settings and nested preferences are covered', () => {
  for (const path of ['master_lc/a','purchase_orders/a','cuttings/a','sewings/a','productions/a','issues/a','exports/a','users/a','roles/a','settings/business','users/a/preferences/app']) assert.ok(moduleForPath(path),path);
});
test('audit logs, counters and unrelated nested documents never recurse', () => {
  for (const path of ['audit_logs/a','_counters/a','unknown/a','users/a/other/b']) assert.equal(moduleForPath(path),null);
});
test('system actions retain principal rather than inventing an ERP user', () => {
  const log=buildActivity({...base,actor:null,authId:'importer@project.iam.gserviceaccount.com',authType:'service_account',before:null,after:{q:1}});
  assert.equal(log.authType,'service_account'); assert.equal(log.actorUid,'importer@project.iam.gserviceaccount.com');
});
test('secrets are recursively redacted and timestamps are readable', () => {
  const log=buildActivity({...base,before:null,after:{password:'bad',nested:{apiToken:'secret'},createdAt:{toDate:()=>new Date('2026-10-07T00:00:00Z')}}});
  assert.equal(log.after.password,'[redacted]'); assert.equal(log.after.nested.apiToken,'[redacted]'); assert.equal(log.after.createdAt,'2026-10-07T00:00:00.000Z');
});
test('large snapshots are bounded below Firestore document limit', () => {
  const log=buildActivity({...base,before:null,after:Object.fromEntries(Array.from({length:100},(_,i)=>['k'+i,'😀'.repeat(2000)]))});
  assert.equal(log.after.truncated,true); assert.ok(Buffer.byteLength(JSON.stringify(log))<150000);
});
test('stable event ID makes retries idempotent', async () => {
  const records=new Map();
  const db={collection:name=>{assert.equal(name,'audit_logs');return {doc:id=>({create:async value=>{if(records.has(id))throw Object.assign(new Error('duplicate'),{code:6});records.set(id,value);}})}}};
  await persistActivity(db,'event-1',{action:'create'}); await persistActivity(db,'event-1',{action:'create'});
  assert.equal(records.size,1); assert.ok(records.has(eventLogId('event-1')));
});
test('write failures propagate to enable trigger retry', async () => {
  const db={collection:()=>({doc:()=>({create:async()=>{throw Object.assign(new Error('offline'),{code:14});}})})};
  await assert.rejects(persistActivity(db,'event-1',{}),/offline/);
});

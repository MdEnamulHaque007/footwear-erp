'use strict';
const test=require('node:test');const assert=require('node:assert/strict');
const {normalizePayload,validateStages,poTotals,canWrite}=require('../workflow');
const stages=()=>({cuttings:[],sewings:[],productions:[],issues:[],exports:[]});
const line={poNo:'P1',tagNo:'T1',article:'A',color:'Black'};
function entry(stage,q,date='2026-10-07') {const dateKey={cuttings:'cuttingDate',sewings:'sewingDate',productions:'productionDate',issues:'issueDate',exports:'exportDate'}[stage];const qtyKey={cuttings:'cuttingQuantity',sewings:'sewingQuantity',productions:'quantity',issues:'issueQuantity',exports:'exportQuantity'}[stage];return {...line,[dateKey]:date,[qtyKey]:q};}
test('each stage respects its predecessor, while Cutting may exceed a PO',()=>{
 const data=stages(); data.cuttings=[entry('cuttings',150)];data.sewings=[entry('sewings',140)];data.productions=[entry('productions',130)];data.issues=[entry('issues',120)];data.exports=[entry('exports',110)];assert.doesNotThrow(()=>validateStages(data));
 for(const [stage,q] of [['sewings',151],['productions',141],['issues',131],['exports',121]]) {const changed={...data,[stage]:[entry(stage,q)]};assert.throws(()=>validateStages(changed),/exceeds/);}
});
test('a later upstream record cannot fund a backdated downstream record',()=>{
 const data=stages();data.cuttings=[entry('cuttings',10,'2026-10-08')];data.sewings=[entry('sewings',1,'2026-10-07')];assert.throws(()=>validateStages(data),/exceeds/);
});
test('reducing/deleting an upstream quantity with existing downstream records is rejected',()=>{
 const data=stages();data.cuttings=[entry('cuttings',10)];data.sewings=[entry('sewings',8)];
 assert.throws(()=>validateStages({...data,cuttings:[entry('cuttings',7)]}),/exceeds/);
 assert.throws(()=>validateStages({...data,cuttings:[]}),/exceeds/);
});
test('line matching ignores case and whitespace, without mixing colors',()=>{
 const data=stages();data.cuttings=[entry('cuttings',10)];data.sewings=[{...entry('sewings',10),poNo:' p1 ',article:'a',color:' black '}];assert.doesNotThrow(()=>validateStages(data));
 data.sewings[0].color='Red';assert.throws(()=>validateStages(data),/exceeds/);
});
test('PO headers are computed from lines and cannot be forged',()=>{
 const po=normalizePayload('purchase_orders',{poNo:'P1',tagNo:'T1',poDate:'2026-10-07',totalQuantity:1,totalValue:1,lineItems:[{article:'A',color:'B',poQuantity:10,unitPrice:2}]});assert.equal(po.totalQuantity,10);assert.equal(po.totalValue,20);assert.deepEqual(poTotals(po),{quantity:10,value:20});
});
test('duplicate PO lines and invalid quantities are rejected',()=>{
 const base={poNo:'P1',tagNo:'T1',poDate:'2026-10-07',lineItems:[{article:'A',color:'B',poQuantity:10,unitPrice:2},{article:' a ',color:'b',poQuantity:1,unitPrice:1}]};assert.throws(()=>normalizePayload('purchase_orders',base),/distinct/);
 for(const q of [0,-1,1.5,'NaN'])assert.throws(()=>normalizePayload('issues',{...line,issueDate:'2026-10-07',issueQuantity:q}),/positive/);
});
test('canonical quantity/value aliases agree and client creation metadata is discarded',()=>{
 const data=normalizePayload('issues',{...line,issueDate:{__erpTimestamp:Date.parse('2026-10-07')},issueQuantity:10,quantity:999,unitPrice:2,issueValue:999,sl:999,createdAt:'fake',_activityMutationId:'forged'});assert.equal(data.quantity,10);assert.equal(data.issueValue,20);assert.equal(data.createdAt,undefined);assert.equal(data.sl,undefined);assert.equal(data._activityMutationId,undefined);
});
test('inactive and unauthorized profiles never gain access through the server',()=>{
 assert.equal(canWrite(null,'issue','create'),false);assert.equal(canWrite({role:'admin',isActive:false},'issue','create'),false);
 assert.equal(canWrite({role:'viewer',permissions:{issue:{edit:true}}},'issue','update'),true);assert.equal(canWrite({role:'viewer',permissions:{issue:{edit:true}}},'issue','delete'),false);
});

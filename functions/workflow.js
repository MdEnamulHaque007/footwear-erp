'use strict';
const {createHash} = require('node:crypto');
const {Timestamp, FieldValue} = require('firebase-admin/firestore');
const {HttpsError} = require('firebase-functions/v2/https');
const {buildActivity, eventLogId} = require('./activity');
const stages = ['cuttings','sewings','productions','issues','exports'];
const configs = {
  master_lc:{module:'master_lc',date:'masterLcDate'},
  purchase_orders:{module:'purchase_order',date:'poDate'},
  cuttings:{module:'cutting',date:'cuttingDate',qty:'cuttingQuantity'},
  sewings:{module:'sewing',date:'sewingDate',qty:'sewingQuantity'},
  productions:{module:'production',date:'productionDate',qty:'quantity'},
  issues:{module:'issue',date:'issueDate',qty:'issueQuantity'},
  exports:{module:'export',date:'exportDate',qty:'exportQuantity'},
};
const norm = value => String(value ?? '').trim().toLowerCase();
const number = value => {const n=Number(value ?? 0); return Number.isFinite(n) ? n : 0;};
const tag = data => String(data?.tagNo || data?.poTagNo || '').trim();
const fail = message => {throw new HttpsError('failed-precondition',message);};
const invalid = message => {throw new HttpsError('invalid-argument',message);};
function quantity(collection,data) { return number(data[configs[collection].qty] ?? data.quantity ?? data.productionQuantity); }
function lineKey(data) {return [norm(data.poNo) || `tag:${norm(tag(data))}`,norm(data.article),norm(data.color)].join('|');}
function day(value) {
  const ms=value?.toMillis ? value.toMillis() : value instanceof Date ? value.getTime() : Date.parse(value);
  // Business dates are Bangladesh calendar days, independent of runtime TZ.
  return Number.isFinite(ms) ? Math.floor((ms+6*3600000)/86400000) : -Infinity;
}
function poLines(data) {
  const lines=Array.isArray(data.lineItems) && data.lineItems.length ? data.lineItems : [data];
  return lines.map(line=>({article:String(line.article || line.articleNo || '').trim(),color:String(line.color || line.colour || '').trim(),poQuantity:number(line.poQuantity ?? line.quantity),unitPrice:number(line.unitPrice)}));
}
function poTotals(data) {
  const lines=poLines(data);
  return {quantity:lines.reduce((t,l)=>t+l.poQuantity,0),value:lines.reduce((t,l)=>t+l.poQuantity*l.unitPrice,0)};
}
function normalizePayload(collection,input) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) invalid('Record data is required.');
  const data={...input};
  for (const key of ['createdAt','updatedAt','id','sl','_activityMutationId']) delete data[key];
  const config=configs[collection];
  const raw=data[config.date];
  const millis=raw && typeof raw==='object' ? raw.__erpTimestamp : typeof raw==='number' ? raw : Date.parse(raw);
  if (!Number.isFinite(millis)) invalid('A valid record date is required.');
  data[config.date]=Timestamp.fromMillis(millis);
  data.tagNo=tag(data);
  if (!data.tagNo) invalid('Tag No is required.');
  if (collection==='master_lc') {
    for (const field of ['masterLcQuantity','masterLcValue']) {
      const value=Number(data[field]);
      if (!Number.isFinite(value) || value<=0 || (field==='masterLcQuantity' && !Number.isInteger(value))) invalid('Master LC quantity and value must be positive.');
      data[field]=value;
    }
  } else if (collection==='purchase_orders') {
    data.poNo=String(data.poNo ?? '').trim();
    if (!data.poNo) invalid('PO No is required.');
    const seen=new Set();
    data.lineItems=poLines(data).map(line=>{
      const key=norm(line.article)+'|'+norm(line.color);
      if (!line.article || !line.color || !Number.isInteger(line.poQuantity) || line.poQuantity<=0 || !Number.isFinite(Number(line.unitPrice)) || line.unitPrice<0 || seen.has(key)) invalid('PO lines require distinct article/color, positive whole quantity and a non-negative price.');
      seen.add(key);return {...line,poValue:line.poQuantity*line.unitPrice};
    });
    const totals=poTotals(data);data.totalQuantity=totals.quantity;data.totalValue=totals.value; data.poQuantity=totals.quantity;data.poValue=totals.value;
  } else {
    for (const field of ['poNo','article','color']) {
      data[field]=String(data[field] ?? '').trim(); if (!data[field]) invalid(`${field} is required.`);
    }
    const q=Number(data[config.qty] ?? data.quantity);
    if (!Number.isSafeInteger(q) || q<=0) invalid('Quantity must be a positive whole number.');
    data[config.qty]=q;data.quantity=q;data.poTagNo=data.tagNo;
    if (collection==='productions')data.productionQuantity=q;
    if (['productions','issues','exports'].includes(collection)) {
      const price=Number(data.unitPrice ?? 0);if (!Number.isFinite(price) || price<0) invalid('Unit price must be non-negative.');
      data.unitPrice=price;data[{productions:'productionValue',issues:'issueValue',exports:'exportValue'}[collection]]=q*price;
    }
  }
  return data;
}
// Every date boundary must respect the preceding stage, including after an
// upstream edit/delete or moving a record onto a different PO line/date.
function validateStages(records) {
  const keys=new Set(stages.flatMap(c=>records[c].map(lineKey)));
  for(const key of keys) {
    for(let i=1;i<stages.length;i++) {
      const upstream=records[stages[i-1]].filter(d=>lineKey(d)===key);
      const downstream=records[stages[i]].filter(d=>lineKey(d)===key);
      const dates=new Set(downstream.map(d=>day(d[configs[stages[i]].date])));
      for(const cutoff of dates) {
        const available=upstream.filter(d=>day(d[configs[stages[i-1]].date])<=cutoff).reduce((t,d)=>t+quantity(stages[i-1],d),0);
        const used=downstream.filter(d=>day(d[configs[stages[i]].date])<=cutoff).reduce((t,d)=>t+quantity(stages[i],d),0);
        if(used>available)fail(`${configs[stages[i]].module} quantity exceeds ${configs[stages[i-1]].module} availability for ${key}. Correct downstream quantities/dates first.`);
      }
    }
  }
}
async function scopedRecords(db,tx,collection,tags,poNos=[]) {
  const docs=new Map();
  for(const value of tags) {
    for(const field of collection==='purchase_orders'?['tagNo']:['tagNo','poTagNo']) {
      const snapshot=await tx.get(db.collection(collection).where(field,'==',value));
      for(const doc of snapshot.docs)docs.set(doc.id,{...doc.data(),_id:doc.id});
    }
  }
  for(const poNo of poNos) {
    const snapshot=await tx.get(db.collection(collection).where('poNo','==',poNo));
    for(const doc of snapshot.docs)docs.set(doc.id,{...doc.data(),_id:doc.id});
  }
  return [...docs.values()];
}
function canWrite(profile,module,action) {
  return Boolean(profile && profile.isActive!==false && (profile.role==='admin' || profile.permissions?.[module]?.[action==='update'?'edit':action]===true));
}
function deletionReceiptId(path,updateTime) {
  return createHash('sha256').update(`${path}:${updateTime.seconds}:${updateTime.nanoseconds}`).digest('hex');
}
async function mutateBusiness(db,request) {
  if(!request.auth)throw new HttpsError('unauthenticated','Sign in before changing records.');
  const {collection,action,id,data:input}=request.data || {};
  if(!configs[collection] || !['create','update','delete'].includes(action) || typeof id!=='string' || !id || id.includes('/') || id.length>500) invalid('Invalid business operation.');
  const candidate=action==='delete'?null:normalizePayload(collection,input);
  const ref=db.collection(collection).doc(id);
  const mutationId=db.collection('audit_logs').doc().id;
  const lock=db.doc('_system/workflow');
  return db.runTransaction(async tx=>{
    // The shared lock serializes phantom inserts and all affected stage writes.
    // It must be read before quantities, and written in the same commit.
    const guard=await tx.get(lock);
    const profileDoc=await tx.get(db.doc(`users/${request.auth.uid}`));
    const profile=profileDoc.data();
    if(!canWrite(profile,configs[collection].module,action))throw new HttpsError('permission-denied','You do not have permission for this operation.');
    const oldDoc=await tx.get(ref);const before=oldDoc.exists?oldDoc.data():null;
    if(action==='create' && before)throw new HttpsError('already-exists','Record already exists.');
    if(action!=='create' && !before)throw new HttpsError('not-found','Record no longer exists.');
    const after=candidate?{...before,...candidate}:null;
    const allMaster=await tx.get(db.collection('master_lc'));
    let masters=allMaster.docs.map(d=>({...d.data(),_id:d.id}));
    if(after && collection!=='master_lc') {
      const canonical=masters.find(m=>norm(tag(m))===norm(tag(after)));
      if(!canonical)fail('A matching Master LC is required.');
      after.tagNo=tag(canonical); if(stages.includes(collection))after.poTagNo=after.tagNo;
      after.company=canonical.company || after.company || '';after.project=canonical.project || after.project || '';
    }
    const tags=[...new Set([tag(before),tag(after)].filter(Boolean))];
    const allPO=collection==='master_lc'||collection==='purchase_orders'?await tx.get(db.collection('purchase_orders')):null;
    let pos=allPO?allPO.docs.map(d=>({...d.data(),_id:d.id})):await scopedRecords(db,tx,'purchase_orders',tags);
    const records={};
    for(const stage of stages)records[stage]=await scopedRecords(db,tx,stage,tags,pos.filter(p=>tags.some(t=>norm(t)===norm(tag(p)))).map(p=>p.poNo));
    if(collection==='master_lc') {
      if(before && tag(before)!==tag(after) && pos.some(p=>norm(tag(p))===norm(tag(before))))fail('Cannot rename/delete a Master LC used by purchase orders.');
      masters=masters.filter(d=>d._id!==id);if(after)masters.push({...after,_id:id});
      if(after && masters.some(d=>d._id!==id && norm(tag(d))===norm(tag(after))))fail('Master LC Tag No must be unique.');
    } else if(collection==='purchase_orders') {
      const linked=stages.flatMap(c=>records[c]).filter(d=>norm(d.poNo)===norm(before?.poNo));
      if(linked.length && (!after || norm(after.poNo)!==norm(before.poNo) || tag(after)!==tag(before)))fail('Cannot delete/move a PO with production entries.');
      if(after && linked.some(d=>!poLines(after).some(l=>norm(l.article)===norm(d.article)&&norm(l.color)===norm(d.color))))fail('Cannot remove a PO line used by production entries.');
      pos=pos.filter(p=>p._id!==id);if(after)pos.push({...after,_id:id});
      if(after && pos.some(p=>p._id!==id && norm(p.poNo)===norm(after.poNo)))fail('PO No must be unique.');
    } else {
      if(after) {
        const po=pos.find(p=>norm(p.poNo)===norm(after.poNo));
        if(!po || norm(tag(po))!==norm(tag(after)) || !poLines(po).some(l=>norm(l.article)===norm(after.article)&&norm(l.color)===norm(after.color)))fail('Select an existing PO article/color line and its correct Tag No.');
        after.poNo=po.poNo;after.company=po.company || after.company || '';after.project=po.project || after.project || '';
        const selectedLine=poLines(po).find(l=>norm(l.article)===norm(after.article)&&norm(l.color)===norm(after.color));
        after.poQuantity=selectedLine.poQuantity;
        if(['productions','issues','exports'].includes(collection)) {
          after.unitPrice=selectedLine.unitPrice;
          after[{productions:'productionValue',issues:'issueValue',exports:'exportValue'}[collection]]=quantity(collection,after)*selectedLine.unitPrice;
        }
        const previous=stages[stages.indexOf(collection)-1];
        if(previous) {
          const total=records[previous].filter(d=>lineKey(d)===lineKey(after)&&day(d[configs[previous].date])<=day(after[configs[collection].date])).reduce((t,d)=>t+quantity(previous,d),0);
          after[{sewings:'cuttingQuantity',productions:'sewingQuantity',issues:'productionQuantity',exports:'issueQuantity'}[collection]]=total;
        }

      }
      records[collection]=records[collection].filter(d=>d._id!==id);if(after)records[collection].push({...after,_id:id});
      validateStages(records);
    }
    for(const value of tags) {
      const orders=pos.filter(p=>norm(tag(p))===norm(value));
      if(!orders.length)continue;
      const master=masters.find(m=>norm(tag(m))===norm(value));
      if(!master)fail('A matching Master LC is required.');
      const total=orders.map(poTotals).reduce((t,v)=>({quantity:t.quantity+v.quantity,value:t.value+v.value}),{quantity:0,value:0});
      if(total.quantity>number(master.masterLcQuantity)||total.value>number(master.masterLcValue)+0.000001)fail('Combined PO quantity/value exceeds Master LC.');
    }
    // All reads complete before writes. Preserve original creation date/Sl.
    let counterRef,counterValue;
    if(after && action==='create') {
      counterRef=db.doc(`_counters/${collection}`);
      const counter=await tx.get(counterRef);
      const latest=await tx.get(db.collection(collection).orderBy('sl','desc').limit(1));
      counterValue=Math.max(number(counter.data()?.value),number(latest.docs[0]?.data().sl))+1;
      after.sl=counterValue;after.createdAt=Timestamp.now();
    }
    if(after) {
      after.updatedAt=Timestamp.now();after._activityMutationId=mutationId;
      if(before){after.sl=before.sl ?? 0;after.createdAt=before.createdAt ?? Timestamp.now();}
    }
    const actor={uid:request.auth.uid,displayName:profile.displayName || request.auth.token?.name || '',email:profile.email || request.auth.token?.email || ''};
    const history=buildActivity({eventId:mutationId,path:ref.path,before,after,authId:actor.uid,authType:'firebase_user',actor,createdAt:Timestamp.now()});
    if(history){history.source='server_crud';tx.create(db.collection('audit_logs').doc(eventLogId(mutationId)),history);}
    if(action==='delete') {
      tx.set(db.collection('_activity_deletions').doc(deletionReceiptId(ref.path,oldDoc.updateTime)),{documentPath:ref.path,mutationId});
      tx.delete(ref);
    } else tx.set(ref,after);
    if(counterRef)tx.set(counterRef,{value:counterValue});
    tx.set(lock,{version:number(guard.data()?.version)+1,updatedAt:FieldValue.serverTimestamp()});
    return {id,sl:after?.sl ?? before?.sl ?? 0};
  });
}
// First admin is allowlisted by Firebase Auth custom claim, not self-selected.
// An existing admin must grant later users access through User Management.
async function bootstrapAdmin(db,request) {
  if(!request.auth)throw new HttpsError('unauthenticated','Sign in first.');
  if(request.auth.token?.erpBootstrap!==true)throw new HttpsError('permission-denied','Initial administrator setup requires the erpBootstrap custom claim. Ask the Firebase project owner.');
  const name=String(request.data?.displayName || '').trim();if(!name || name.length>100)invalid('A display name of 1–100 characters is required.');
  return db.runTransaction(async tx=>{
    const marker=db.doc('_system/admin_bootstrap');const claimed=await tx.get(marker);
    const admins=await tx.get(db.collection('users').where('role','==','admin').limit(1));
    const ref=db.doc(`users/${request.auth.uid}`);const existing=await tx.get(ref);
    if(claimed.exists || !admins.empty)throw new HttpsError('already-exists','An administrator already exists.');
    if(existing.exists && existing.data().role!=='viewer')throw new HttpsError('failed-precondition','This profile cannot be bootstrapped.');
    const data={...existing.data(),uid:request.auth.uid,email:request.auth.token.email || '',displayName:name,role:'admin',permissions:{},isActive:true,isEmailVerified:request.auth.token.email_verified===true,createdAt:existing.data()?.createdAt || Timestamp.now(),lastLogin:Timestamp.now()};
    tx.set(ref,data);tx.create(marker,{uid:request.auth.uid,createdAt:Timestamp.now()});
    return {uid:request.auth.uid};
  });
}
module.exports={mutateBusiness,bootstrapAdmin,validateStages,normalizePayload,poTotals,lineKey,canWrite,deletionReceiptId};

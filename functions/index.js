'use strict';
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {onDocumentWrittenWithAuthContext} = require('firebase-functions/v2/firestore');
const {buildActivity, moduleForPath, persistActivity} = require('./activity');
initializeApp();

exports.recordActivity = onDocumentWrittenWithAuthContext({
  document: '{documentPath=**}', retry: true,
}, async event => {
  const path = event.data?.after?.ref.path || event.data?.before?.ref.path;
  // Excludes audit_logs and counters to avoid recursion and internal noise.
  if (!path || !moduleForPath(path)) return;
  // Server CRUD writes an attributed history entry atomically. Do not record
  // the same Admin SDK mutation a second time as a service-account action.
  const before = event.data.before;
  const after = event.data.after;
  const mutationId = after.exists ? after.data()._activityMutationId : null;
  if (mutationId && (!before.exists || before.data()._activityMutationId !== mutationId)) {
    const recorded = await getFirestore().doc(`audit_logs/${require('./activity').eventLogId(mutationId)}`).get();
    if (recorded.exists && recorded.data().documentPath === path && recorded.data().source === 'server_crud') return;
  }
  if (!after.exists && before.exists) {
    const receipt = await getFirestore().doc(`_activity_deletions/${deletionReceiptId(path,before.updateTime)}`).get();
    if (receipt.exists) return;
  }

  let actor;
  if (event.authId && !['system', 'service_account', 'unauthenticated'].includes(event.authType)) {
    try {
      actor = await getAuth().getUser(event.authId);
    } catch (error) {
      if (error.code !== 'auth/user-not-found' && error.code !== 'auth/invalid-uid') throw error;
      // Auth context may identify an email principal rather than a Firebase UID.
      if (event.authId.includes('@')) {
        try { actor = await getAuth().getUserByEmail(event.authId); }
        catch (lookupError) {
          if (lookupError.code !== 'auth/user-not-found' && lookupError.code !== 'auth/invalid-email') throw lookupError;
        }
      }
    }
  }
  const activity = buildActivity({
    eventId: event.id, path, authId: event.authId, authType: event.authType, actor,
    before: event.data.before.exists ? event.data.before.data() : null,
    after: event.data.after.exists ? event.data.after.data() : null,
    createdAt: Timestamp.fromDate(new Date(event.time)),
  });
  await persistActivity(getFirestore(), event.id, activity);
});

const {onCall} = require('firebase-functions/v2/https');
const {mutateBusiness, bootstrapAdmin, deletionReceiptId} = require('./workflow');
exports.mutateBusiness = onCall({timeoutSeconds:120}, request => mutateBusiness(getFirestore(),request));
exports.bootstrapAdmin = onCall(request => bootstrapAdmin(getFirestore(),request));

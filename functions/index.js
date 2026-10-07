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

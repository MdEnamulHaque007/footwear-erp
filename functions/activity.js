'use strict';
const {createHash} = require('node:crypto');
const {isDeepStrictEqual} = require('node:util');

const modules = Object.freeze({
  master_lc: 'master_lc', purchase_orders: 'purchase_order',
  cuttings: 'cutting', sewings: 'sewing', productions: 'production',
  issues: 'issue', exports: 'export', users: 'user_management',
  roles: 'role_management', settings: 'settings',
});
const sensitive = /password|token|secret|credential|privatekey|authorization/i;

// Snapshot size is bounded independently of the business document size.
// Firestore timestamps/references are represented as readable JSON values.
function sanitize(value, depth = 0) {
  if (depth > 8) return '[depth limit]';
  if (value == null || typeof value === 'boolean' || typeof value === 'number') return value;
  if (typeof value === 'string') return value.slice(0, 2000);
  if (typeof value.toDate === 'function') return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (typeof value.path === 'string' && typeof value.get === 'function') return value.path;
  if (Buffer.isBuffer(value) || value instanceof Uint8Array) return '[binary]';
  if (Array.isArray(value)) return value.slice(0, 100).map(v => sanitize(v, depth + 1));
  if (typeof value === 'object') {
    return Object.fromEntries(Object.entries(value).slice(0, 100).map(([key, v]) =>
      [key, sensitive.test(key) ? '[redacted]' : sanitize(v, depth + 1)]));
  }
  return String(value);
}
function boundedSnapshot(value) {
  const clean = sanitize(value);
  return Buffer.byteLength(JSON.stringify(clean), 'utf8') <= 60000
    ? clean : {truncated: true, preview: JSON.stringify(clean).slice(0, 12000)};
}
function moduleForPath(path) {
  const parts = path.split('/');
  if (parts.length === 4 && parts[0] === 'users' && parts[2] === 'preferences') return 'settings';
  return parts.length === 2 ? modules[parts[0]] || null : null;
}
function buildActivity({eventId, path, before, after, authId, authType, actor, createdAt}) {
  const module = moduleForPath(path);
  if (!module || (!before && !after)) return null;
  const action = !before ? 'create' : !after ? 'delete' : 'update';
  const changedFields = Object.keys({...before, ...after}).filter(key =>
    !isDeepStrictEqual(before?.[key], after?.[key]));
  if (action === 'update' && changedFields.length === 0) return null;
  const record = after || before;
  return {
    schemaVersion: 1, eventId, source: 'firestore_trigger', action, module,
    documentPath: path, documentId: path.split('/').at(-1),
    recordLabel: String(record.voucherNo || record.poNo || record.tagNo || record.roleName || path.split('/').at(-1)).slice(0, 300),
    actorUid: actor?.uid || authId || '', actorName: actor?.displayName || authId || 'System / unknown',
    actorEmail: actor?.email || '', authType: authType || 'unknown',
    createdAt, changedFields: changedFields.slice(0, 100),
    before: before ? boundedSnapshot(before) : null,
    after: after ? boundedSnapshot(after) : null,
  };
}
function eventLogId(eventId) {
  return createHash('sha256').update(eventId).digest('hex');
}
// Event delivery may be repeated. Atomic create + stable ID keeps one record.
async function persistActivity(db, eventId, activity) {
  if (!activity) return;
  try {
    await db.collection('audit_logs').doc(eventLogId(eventId)).create(activity);
  } catch (error) {
    if (error.code !== 6 && error.code !== 'already-exists') throw error;
  }
}
module.exports = {buildActivity, moduleForPath, sanitize, eventLogId, persistActivity};

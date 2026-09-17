/*
 * Footwear ERP demo-data seeder.
 *
 * Creates a realistic, internally consistent chain in EVERY business module:
 *   Master LC -> Purchase Orders -> Cutting -> Sewing -> Production -> Issue -> Export
 *
 * Default: 3,000 documents PER module (21,000 total).
 * Allowed: 3,000..5,000 per module.
 *
 * IMPORTANT: this script intentionally uses firebase-admin, so Firestore Rules are
 * bypassed. Use it only against a development/staging Firebase project or the
 * Firebase Emulator. Never point it at production data.
 *
 * Usage:
 *   npm install
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json npm run seed:demo
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/service-account.json node scripts/seed_demo_data.js --count 5000
 *   node scripts/seed_demo_data.js --count 3000 --clear
 *
 * Emulator:
 *   FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 GCLOUD_PROJECT=footwear-9d10e npm run seed:demo
 */

'use strict';

const admin = require('firebase-admin');

const DEFAULT_COUNT = 3000;
const MIN_COUNT = 3000;
const MAX_COUNT = 5000;
const BATCH_SIZE = 450;
const DEMO_MARKER = 'footwear-erp-demo-v1';

const companies = [
  'AERO CLUB',
  'AVISEN INT.Co.LTD.',
  'BEVAFORM SERVICE + HANDELS GES.M.B.H.',
  'BOSEN IMPORT & EXPORT CO. LIMITED',
  'BRIGHT HEART CORPORATION LIMITED',
  'HANG YUE TONG COMPANY LTD.',
  'IVY-ATLAS INTERNATIONAL LIMITED',
  'LIFESTYLE',
  'MIRZA INTERNATIONAL LIMITED',
  'NOVI FOOTWEAR LTD.',
  'REDTAPE LIMITED',
  'RTS FASHION FZE',
  'SKYLINE GROUP ASIA LIMITED',
  'TONSEN INTERNATIONAL CORPORATION LTD.',
  'UPTOP TRADING LTD.',
  'WOODLAND GCCFZCO',
];

const projects = ['IALT', 'UPTOP'];
const brands = ['Apex', 'UrbanStep', 'WalkPro', 'ComfortX', 'Stride'];
const articles = ['FT-1001', 'FT-1002', 'FT-1003', 'FT-2001', 'FT-2002', 'FT-3001'];
const colors = ['Black', 'White', 'Navy', 'Brown', 'Tan', 'Grey', 'Red'];
const factories = ['Factory-A', 'Factory-B', 'Factory-C', 'Factory-D'];
const entryPeople = ['Demo Admin', 'Demo Manager', 'Demo Operator', 'Demo QA'];

function argValue(name, fallback = undefined) {
  const prefix = `--${name}=`;
  const arg = process.argv.find((x) => x.startsWith(prefix));
  return arg ? arg.slice(prefix.length) : fallback;
}

function hasFlag(name) {
  return process.argv.includes(`--${name}`);
}

const count = Number(argValue('count', DEFAULT_COUNT));
if (!Number.isInteger(count) || count < MIN_COUNT || count > MAX_COUNT) {
  throw new Error(`--count must be an integer between ${MIN_COUNT} and ${MAX_COUNT}`);
}

if (hasFlag('production')) {
  throw new Error('Refusing to run with --production. Use a development/staging project explicitly.');
}

function pick(list, index, salt = 0) {
  return list[(index + salt) % list.length];
}

function round(value, digits = 2) {
  const factor = 10 ** digits;
  return Math.round(value * factor) / factor;
}

function dateFor(index, stageOffset = 0) {
  // 2025-01-01 onward; downstream stages are later than upstream stages.
  const base = new Date(Date.UTC(2025, 0, 1));
  base.setUTCDate(base.getUTCDate() + (index % 365) + stageOffset);
  return base;
}

function timestamp(value) {
  return admin.firestore.Timestamp.fromDate(value);
}

function baseFields(index, createdAt) {
  return {
    demoSeed: DEMO_MARKER,
    demoIndex: index,
    createdAt: timestamp(createdAt),
    updatedAt: timestamp(createdAt),
    source: 'demo_seed',
    syncStatus: 'synced',
  };
}

function docId(prefix, index) {
  return `demo-${prefix}-${String(index + 1).padStart(5, '0')}`;
}

function buildRecords(i) {
  const company = pick(companies, i, 3);
  const project = pick(projects, i);
  const brand = pick(brands, i, 1);
  const article = pick(articles, i, 2);
  const color = pick(colors, i, 1);
  const factory = pick(factories, i, 2);
  const entryPerson = pick(entryPeople, i);
  const unitPrice = round(18 + ((i * 7) % 900) / 100, 2);

  // A single PO line per demo record keeps the relationship easy to inspect.
  // Quantities strictly decrease down the production chain.
  const poQuantity = 1200 + (i % 1801); // 1,200..3,000
  const cuttingQuantity = Math.max(1, poQuantity - 80 - (i % 121));
  const sewingQuantity = Math.max(1, cuttingQuantity - 70 - (i % 101));
  const productionQuantity = Math.max(1, sewingQuantity - 60 - (i % 81));
  const issueQuantity = Math.max(1, productionQuantity - 50 - (i % 61));
  const exportQuantity = Math.max(1, issueQuantity - 40 - (i % 51));

  const poNo = `DEMO-PO-${String(i + 1).padStart(5, '0')}`;
  const tagNo = `DEMO-TAG-${String(i + 1).padStart(5, '0')}`;
  const lcNo = `DEMO-LC-${String(i + 1).padStart(5, '0')}`;
  const scNo = `DEMO-SC-${String(i + 1).padStart(5, '0')}`;
  const ttNo = `DEMO-TT-${String(i + 1).padStart(5, '0')}`;

  const masterDate = dateFor(i, 0);
  const poDate = dateFor(i, 2);
  const cuttingDate = dateFor(i, 7);
  const sewingDate = dateFor(i, 14);
  const productionDate = dateFor(i, 21);
  const issueDate = dateFor(i, 28);
  const exportDate = dateFor(i, 35);
  const createdAt = exportDate;

  const common = {
    company,
    project,
    article,
    color,
    factoryName: factory,
    entryPerson,
    poNo,
    tagNo,
    unitPrice,
  };

  const masterLc = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    masterLcDate: timestamp(masterDate),
    tagNo,
    project,
    company,
    scNo,
    lcNo,
    ttNo,
    masterLcQuantity: poQuantity,
    masterLcValue: round(poQuantity * unitPrice, 2),
  };

  const purchaseOrder = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    poDate: timestamp(poDate),
    tagNo,
    company,
    project,
    brand,
    poNo,
    entryPerson,
    lineItems: [
      {
        article,
        color,
        poQuantity,
        unitPrice,
        poValue: round(poQuantity * unitPrice, 2),
      },
    ],
    totalQuantity: poQuantity,
    totalValue: round(poQuantity * unitPrice, 2),
  };

  const cutting = {
    ...baseFields(i, createdAt),
    voucherNo: `CUT-DEMO-${String(i + 1).padStart(5, '0')}`,
    cuttingDate: timestamp(cuttingDate),
    poNo,
    tagNo,
    poTagNo: tagNo,
    company,
    project,
    article,
    color,
    poQuantity,
    cuttingQuantity,
    quantity: cuttingQuantity,
    factoryName: factory,
    entryPerson,
    remarks: 'Demo data',
  };

  const sewing = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    voucherNo: `SEW-DEMO-${String(i + 1).padStart(5, '0')}`,
    sewingDate: timestamp(sewingDate),
    poNo,
    tagNo,
    poTagNo: tagNo,
    company,
    project,
    article,
    color,
    cuttingQuantity,
    sewingQuantity,
    quantity: sewingQuantity,
    factoryName: factory,
    entryPerson,
    remarks: 'Demo data',
  };

  const production = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    voucherNo: `PRO-DEMO-${String(i + 1).padStart(5, '0')}`,
    productionDate: timestamp(productionDate),
    poTagNo: tagNo,
    tagNo,
    quantity: productionQuantity,
    productionQuantity,
    entryPerson,
    poNo,
    company,
    project,
    article,
    color,
    factoryName: factory,
    unitPrice,
    productionValue: round(productionQuantity * unitPrice, 2),
    sewingQuantity,
    remarks: 'Demo data',
  };

  const issue = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    voucherNo: `ISS-DEMO-${String(i + 1).padStart(5, '0')}`,
    issueDate: timestamp(issueDate),
    poTagNo: tagNo,
    tagNo,
    quantity: issueQuantity,
    issueQuantity,
    entryPerson,
    poNo,
    company,
    project,
    article,
    color,
    factoryName: factory,
    unitPrice,
    issueValue: round(issueQuantity * unitPrice, 2),
    productionQuantity,
    remarks: 'Demo data',
  };

  const exportRecord = {
    ...baseFields(i, createdAt),
    sl: i + 1,
    voucherNo: `EXP-DEMO-${String(i + 1).padStart(5, '0')}`,
    exportDate: timestamp(exportDate),
    poTagNo: tagNo,
    tagNo,
    quantity: exportQuantity,
    exportQuantity,
    entryPerson,
    poNo,
    company,
    project,
    article,
    color,
    factoryName: factory,
    unitPrice,
    exportValue: round(exportQuantity * unitPrice, 2),
    issueQuantity,
    remarks: 'Demo data',
  };

  return { masterLc, purchaseOrder, cutting, sewing, production, issue, exportRecord, common };
}

async function commitCollection(db, collectionName, records, prefix) {
  let batch = db.batch();
  let pending = 0;
  let committed = 0;

  for (let i = 0; i < records.length; i += 1) {
    const ref = db.collection(collectionName).doc(docId(prefix, i));
    batch.set(ref, records[i]);
    pending += 1;

    if (pending >= BATCH_SIZE || i === records.length - 1) {
      await batch.commit();
      committed += pending;
      process.stdout.write(`\r  ${collectionName}: ${committed}/${records.length}`);
      batch = db.batch();
      pending = 0;
    }
  }
  process.stdout.write('\n');
}

async function clearDemoCollection(db, collectionName) {
  let deleted = 0;
  while (true) {
    const snap = await db.collection(collectionName).where('demoSeed', '==', DEMO_MARKER).limit(BATCH_SIZE).get();
    if (snap.empty) break;

    const batch = db.batch();
    snap.docs.forEach((doc) => batch.delete(doc.ref));
    await batch.commit();
    deleted += snap.size;
    process.stdout.write(`\r  clearing ${collectionName}: ${deleted}`);
  }
  if (deleted) process.stdout.write('\n');
}

async function main() {
  const usingEmulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  const projectId = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || undefined;

  if (usingEmulator && projectId) {
    admin.initializeApp({ projectId });
  } else {
    admin.initializeApp({ projectId });
  }

  const db = admin.firestore();

  console.log('Footwear ERP demo data seeder');
  console.log(`Count per module : ${count}`);
  console.log(`Total documents  : ${count * 7}`);
  console.log(`Target           : ${usingEmulator ? `Firestore Emulator (${process.env.FIRESTORE_EMULATOR_HOST})` : (projectId || 'Application Default Credentials')}`);
  console.log(`Marker           : ${DEMO_MARKER}`);

  if (!usingEmulator) {
    console.warn('\nWARNING: FIRESTORE_EMULATOR_HOST is not set. This will write to a real Firebase project.');
    console.warn('Use a staging project and service account; never use production.\n');
  }

  const collections = [
    ['master_lc', 'masterLc', 'mlc'],
    ['purchase_orders', 'purchaseOrder', 'po'],
    ['cuttings', 'cutting', 'cut'],
    ['sewings', 'sewing', 'sew'],
    ['productions', 'production', 'pro'],
    ['issues', 'issue', 'iss'],
    ['exports', 'exportRecord', 'exp'],
  ];

  if (hasFlag('clear')) {
    console.log('\nRemoving ONLY documents marked by this demo seeder...');
    for (const [collectionName] of collections) {
      await clearDemoCollection(db, collectionName);
    }
  }

  const buckets = Object.fromEntries(collections.map(([collectionName, key]) => [collectionName, []]));

  console.log('\nGenerating relational demo dataset...');
  for (let i = 0; i < count; i += 1) {
    const row = buildRecords(i);
    buckets.master_lc.push(row.masterLc);
    buckets.purchase_orders.push(row.purchaseOrder);
    buckets.cuttings.push(row.cutting);
    buckets.sewings.push(row.sewing);
    buckets.productions.push(row.production);
    buckets.issues.push(row.issue);
    buckets.exports.push(row.exportRecord);
  }

  console.log('Writing in Firestore batches...');
  for (const [collectionName, key, prefix] of collections) {
    await commitCollection(db, collectionName, buckets[collectionName], prefix);
  }

  console.log('\nDone.');
  console.log(`Seeded ${count} documents into each of 7 modules (${count * 7} total).`);
  console.log('Every downstream quantity is lower than its upstream quantity, so the demo dataset is suitable for testing the ERP flow and reports.');
  console.log('To remove only this dataset later: npm run seed:demo -- --count ' + count + ' --clear');
}

main().catch((error) => {
  console.error('\nSeeder failed:', error);
  process.exitCode = 1;
});

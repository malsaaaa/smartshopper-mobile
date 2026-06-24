/**
 * remove_lotus_non_common.js
 *
 * Removes Lotus products (retailerId = 3) from Firestore that don't have a
 * fuzzy name match in either MyDin (1) or myAEON2go (2).
 *
 * Matching strategy: strip all non-alphanumeric chars and lowercase, then
 * check if the normalized name tokens overlap meaningfully.
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const PROJECT = 'smartshopper-mobile-4df1e';
const LOTUS_RETAILER_ID = '3';

// ── Auth ────────────────────────────────────────────────────────────────────
const homeDir = process.env.USERPROFILE || process.env.HOME;
const firebaseConfigPath = path.join(homeDir, '.config', 'configstore', 'firebase-tools.json');
const refreshToken = JSON.parse(fs.readFileSync(firebaseConfigPath, 'utf8')).tokens.refresh_token;

function request(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve({ statusCode: res.statusCode, body: body ? JSON.parse(body) : null }));
    });
    req.on('error', reject);
    if (postData) req.write(JSON.stringify(postData));
    req.end();
  });
}

async function getAccessToken() {
  const res = await request({
    hostname: 'oauth2.googleapis.com',
    path: '/token',
    method: 'POST',
    headers: { 'Content-Type': 'application/json' }
  }, {
    grant_type: 'refresh_token',
    refresh_token: refreshToken,
    client_id: '563584335869-fgrhgmd47bqnekij5i8b5pr03ho849e6.apps.googleusercontent.com',
    client_secret: 'j9iVZfS8kkCEFUPaAeJV0sAi',
  });
  return res.body.access_token;
}

async function fetchCollection(accessToken, colName) {
  let documents = [];
  let pageToken = '';
  do {
    const url = `/v1/projects/${PROJECT}/databases/(default)/documents/${colName}?pageSize=300` + (pageToken ? `&pageToken=${pageToken}` : '');
    const res = await request({
      hostname: 'firestore.googleapis.com',
      path: url,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    if (res.statusCode !== 200) {
      console.error(`Error fetching ${colName}: HTTP ${res.statusCode}`);
      break;
    }
    const docs = res.body.documents || [];
    documents = documents.concat(docs);
    pageToken = res.body.nextPageToken || '';
  } while (pageToken);
  return documents;
}

async function deleteDoc(accessToken, docPath) {
  // docPath is already the full resource path e.g. projects/.../documents/products/xxx
  const relativePath = docPath.replace(/^projects\/[^/]+\/databases\/[^/]+\//, '');
  await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/${docPath}`,
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });
}

// ── Name normalization ───────────────────────────────────────────────────────

/** Strip everything except letters/digits, lowercase */
function normalize(name) {
  return (name || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

/**
 * Simple word-overlap score: 
 * split both names into tokens (min 3 chars), count how many from A appear in B.
 * Returns a ratio [0, 1].
 */
function overlapScore(a, b) {
  const tokensA = a.toLowerCase().split(/\s+/).filter(t => t.length >= 3);
  const tokensB = new Set(b.toLowerCase().split(/\s+/).filter(t => t.length >= 3));
  if (tokensA.length === 0) return 0;
  const matches = tokensA.filter(t => tokensB.has(t)).length;
  return matches / tokensA.length;
}

/** Returns true if a Lotus product name matches any non-Lotus product name */
function hasCommonMatch(lotusName, otherNames) {
  const normLotus = normalize(lotusName);
  // Exact normalized match (most reliable)
  if (otherNames.some(n => normalize(n) === normLotus)) return true;
  // Word-overlap: if ≥ 2/3 of lotus name words appear in another product
  if (otherNames.some(n => overlapScore(lotusName, n) >= 0.67)) return true;
  return false;
}

// ── Main ─────────────────────────────────────────────────────────────────────

async function main() {
  console.log('🔑 Obtaining access token...');
  const accessToken = await getAccessToken();
  console.log('✅ Token obtained.\n');

  // 1. Fetch all data
  console.log('📦 Fetching products collection...');
  const rawProducts = await fetchCollection(accessToken, 'products');
  console.log(`   ${rawProducts.length} product docs found.`);

  console.log('📦 Fetching prices collection...');
  const rawPrices = await fetchCollection(accessToken, 'prices');
  console.log(`   ${rawPrices.length} price docs found.\n`);

  // 2. Parse
  const products = rawProducts.map(doc => {
    const f = doc.fields || {};
    return {
      docPath: doc.name,
      docId: doc.name.split('/').pop(),
      name: f.name?.stringValue || '',
      retailerId: f.id?.stringValue?.split('_')[0] || '',
    };
  });

  const prices = rawPrices.map(doc => {
    const f = doc.fields || {};
    return {
      docPath: doc.name,
      docId: doc.name.split('/').pop(),
      productId: f.productId?.stringValue || '',
      retailerId: f.retailerId?.stringValue || f.retailerId?.integerValue || '',
    };
  });

  // Build productId → product name map
  const productById = {};
  products.forEach(p => { productById[p.docId] = p; });

  // 3. Separate by retailer
  const lotusPrices   = prices.filter(p => String(p.retailerId) === '3');
  const otherPrices   = prices.filter(p => String(p.retailerId) !== '3');

  console.log(`🏪 Lotus price docs: ${lotusPrices.length}`);
  console.log(`🏪 Other retailers price docs: ${otherPrices.length}\n`);

  // Build set of non-Lotus product names
  const otherProductNames = [];
  otherPrices.forEach(p => {
    const prod = productById[p.productId];
    if (prod && prod.name) otherProductNames.push(prod.name);
  });

  // Deduplicate
  const uniqueOtherNames = [...new Set(otherProductNames)];
  console.log(`📋 Unique non-Lotus product names: ${uniqueOtherNames.length}`);
  console.log('   Sample:', uniqueOtherNames.slice(0, 5).join(', '), '\n');

  // 4. Identify which Lotus price/product docs to delete
  const toDeletePaths = new Set();
  let keepCount = 0;
  let removeCount = 0;

  // Track lotus product IDs referenced by price docs
  const lotusProductIdsToDelete = new Set();
  const lotusProductIdsToKeep = new Set();

  for (const lotusPrice of lotusPrices) {
    const prod = productById[lotusPrice.productId];
    const name = prod?.name || lotusPrice.productId;
    
    if (hasCommonMatch(name, uniqueOtherNames)) {
      keepCount++;
      lotusProductIdsToKeep.add(lotusPrice.productId);
      console.log(`  ✅ KEEP: "${name}"`);
    } else {
      removeCount++;
      toDeletePaths.add(lotusPrice.docPath); // delete price doc
      lotusProductIdsToDelete.add(lotusPrice.productId);
      console.log(`  ❌ REMOVE: "${name}"`);
    }
  }

  // Only delete product docs that are ONLY referenced by removed prices
  // (don't delete if also kept by another price doc)
  for (const productId of lotusProductIdsToDelete) {
    if (!lotusProductIdsToKeep.has(productId)) {
      const prod = productById[productId];
      if (prod) toDeletePaths.add(prod.docPath);
    }
  }

  // Also find any Lotus product docs that have no price doc at all (orphans)
  const allLotusProductIds = new Set(lotusPrices.map(p => p.productId));
  products.forEach(p => {
    // Lotus products use stable key format: "3_<name_key>"
    if (p.docId.startsWith('3_') && !allLotusProductIds.has(p.docId)) {
      toDeletePaths.add(p.docPath);
      console.log(`  ❌ REMOVE ORPHAN: "${p.name || p.docId}"`);
    }
  });

  console.log(`\n${'='.repeat(60)}`);
  console.log(`  ✅ Lotus products to KEEP:   ${keepCount}`);
  console.log(`  ❌ Lotus products to REMOVE:  ${removeCount}`);
  console.log(`  📄 Total docs to delete:     ${toDeletePaths.size}`);
  console.log('='.repeat(60));

  if (toDeletePaths.size === 0) {
    console.log('\nNothing to delete!');
    return;
  }

  // 5. Confirm then delete
  console.log('\n🗑️  Starting deletion...');
  const pathsList = [...toDeletePaths];
  for (let i = 0; i < pathsList.length; i++) {
    await deleteDoc(accessToken, pathsList[i]);
    if ((i + 1) % 10 === 0 || i === pathsList.length - 1) {
      process.stdout.write(`\r   Deleted ${i + 1}/${pathsList.length} docs...`);
    }
  }
  console.log('\n\n✅ Done! Lotus cleanup complete.');
  console.log(`   Kept ${keepCount} common products, removed ${removeCount} Lotus-exclusive products.`);
}

main().catch(console.error);

/**
 * check_cart_prices.js
 */
const https = require('https');
const fs = require('fs');
const path = require('path');

const PROJECT = 'smartshopper-mobile-4df1e';

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

function getProductMatchKey(name) {
  return (name || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

async function main() {
  const token = await getAccessToken();
  const products = await fetchCollection(token, 'products');
  const prices = await fetchCollection(token, 'prices');

  const targetNames = [
    'Buruh Cooking Oil 1kg',
    'Milo Activ-Go Powder 1.8kg',
    'Moghul Faiza Basmathi Rice 1kg'
  ];

  const targetKeys = targetNames.map(getProductMatchKey);

  console.log('Target Keys:', targetKeys);

  // Find all products matching these keys
  const matchingProducts = [];
  const productIds = new Set();
  for (const doc of products) {
    const name = doc.fields.name ? doc.fields.name.stringValue : '';
    const matchKey = getProductMatchKey(name);
    if (targetKeys.includes(matchKey)) {
      const parts = doc.name.split('/');
      const docId = parts[parts.length - 1];
      console.log(`Matching Product - Doc ID: ${docId}, Name: "${name}"`);
      matchingProducts.push({ docId, name });
      productIds.add(docId);
    }
  }

  // Find all prices for these product IDs
  console.log('\n--- PRICES FOR MATCHING PRODUCTS ---');
  for (const doc of prices) {
    const fields = doc.fields;
    if (!fields) continue;
    const productId = fields.productId ? fields.productId.stringValue : '';
    if (productIds.has(productId)) {
      const price = fields.price ? parseFloat(fields.price.doubleValue || fields.price.integerValue) : 0.0;
      const retailerId = fields.retailerId ? fields.retailerId.stringValue : '';
      console.log(`Price Doc: ${doc.name.split('/').pop()} | Product ID: ${productId} | Retailer ID: ${retailerId} | Price: RM${price.toFixed(2)}`);
    }
  }
}

main();

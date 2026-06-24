/**
 * diagnose_lotus_prices.js
 *
 * Fetches all products and prices from Firestore, normalizes product names using
 * _getProductMatchKey logic, and prints cases where there are multiple prices for Lotus (retailerId = 3)
 * under the same match key.
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
  try {
    console.log('Fetching access token...');
    const token = await getAccessToken();

    console.log('Fetching products...');
    const productDocs = await fetchCollection(token, 'products');
    console.log(`Fetched ${productDocs.length} products.`);

    console.log('Fetching prices...');
    const priceDocs = await fetchCollection(token, 'prices');
    console.log(`Fetched ${priceDocs.length} prices.`);

    // Map products by ID
    const productMap = {};
    for (const doc of productDocs) {
      const parts = doc.name.split('/');
      const idStr = parts[parts.length - 1];
      const fields = doc.fields;
      if (!fields) continue;
      const id = fields.id ? parseInt(fields.id.integerValue) : null;
      const name = fields.name ? fields.name.stringValue : '';
      const brand = fields.brand ? fields.brand.stringValue : '';
      const category = fields.category ? fields.category.stringValue : '';
      
      productMap[id] = { id, name, brand, category, docName: doc.name };
    }

    // Map prices by product ID and retailer
    const pricesByProduct = {};
    for (const doc of priceDocs) {
      const fields = doc.fields;
      if (!fields) continue;
      
      const productId = fields.productId ? parseInt(fields.productId.integerValue) : null;
      const retailerId = fields.retailerId ? fields.retailerId.stringValue : '';
      const price = fields.price ? parseFloat(fields.price.doubleValue || fields.price.integerValue) : 0.0;
      
      if (!pricesByProduct[productId]) {
        pricesByProduct[productId] = [];
      }
      pricesByProduct[productId].push({ retailerId, price });
    }

    // Group by match key
    const groups = {};
    for (const id in productMap) {
      const product = productMap[id];
      const matchKey = getProductMatchKey(product.name);
      if (!groups[matchKey]) {
        groups[matchKey] = {
          matchKey,
          products: [],
          prices: []
        };
      }
      groups[matchKey].products.push(product);
      
      const prodPrices = pricesByProduct[id] || [];
      for (const p of prodPrices) {
        groups[matchKey].prices.push({
          productId: id,
          productName: product.name,
          retailerId: p.retailerId,
          price: p.price
        });
      }
    }

    console.log('\n--- GROUPS WITH MULTIPLE LOTUS PRICES (retailerId = 3) ---');
    let count = 0;
    for (const key in groups) {
      const group = groups[key];
      const lotusPrices = group.prices.filter(p => p.retailerId === '3');
      if (lotusPrices.length > 1) {
        count++;
        console.log(`\nGroup Match Key: "${key}"`);
        console.log('Products in this group:');
        group.products.forEach(p => {
          console.log(`  - ID: ${p.id}, Name: "${p.name}", Brand: "${p.brand}", Category: "${p.category}"`);
        });
        console.log('Lotus\'s Prices in this group:');
        lotusPrices.forEach(p => {
          console.log(`  - Product ID: ${p.productId}, Name: "${p.productName}", Price: RM${p.price.toFixed(2)}`);
        });
        console.log('Other Prices in this group:');
        const otherPrices = group.prices.filter(p => p.retailerId !== '3');
        otherPrices.forEach(p => {
          console.log(`  - Retailer: ${p.retailerId}, Product ID: ${p.productId}, Name: "${p.productName}", Price: RM${p.price.toFixed(2)}`);
        });
      }
    }
    console.log(`\nFound ${count} groups with multiple Lotus's prices.`);

  } catch (err) {
    console.error('Error:', err);
  }
}

main();

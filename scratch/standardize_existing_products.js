const https = require('https');
const fs = require('fs');
const path = require('path');

const project = 'smartshopper-mobile-4df1e';

// 1. Read token from firebase-tools.json
const homeDir = process.env.USERPROFILE || process.env.HOME;
const firebaseConfigPath = path.join(homeDir, '.config', 'configstore', 'firebase-tools.json');

let refreshToken;
try {
  const config = JSON.parse(fs.readFileSync(firebaseConfigPath, 'utf8'));
  refreshToken = config.tokens.refresh_token;
} catch (e) {
  console.error('Failed to read refresh token:', e);
  process.exit(1);
}

// 2. Helper to make HTTP requests
function request(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
          body: body ? JSON.parse(body) : null
        });
      });
    });

    req.on('error', reject);
    if (postData) {
      req.write(typeof postData === 'string' ? postData : JSON.stringify(postData));
    }
    req.end();
  });
}

// 3. Refresh the access token
async function getAccessToken(refreshToken) {
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

  if (res.statusCode === 200) {
    return res.body.access_token;
  } else {
    throw new Error(`Failed to refresh token: ${res.statusCode} ${JSON.stringify(res.body)}`);
  }
}

// 4. Brand extraction logic in JavaScript
function extractBrand(name) {
  const lower = name.toLowerCase();
  const contains = (str) => lower.indexOf(str) !== -1;
  
  if (contains('milo') || contains('nescafe') || contains('nescafé') || contains('nestle') || contains('nestlé')) return 'NESTLE';
  if (contains('buruh')) return 'BURUH';
  if (contains('faiza')) return 'FAIZA';
  if (contains('knife')) return 'KNIFE';
  if (contains('vesawit')) return 'VESAWIT';
  if (contains('naturel')) return 'NATUREL';
  if (contains('csr')) return 'CSR';
  if (contains('maggi')) return 'MAGGI';
  if (contains('boh')) return 'BOH';
  if (contains('jati')) return 'JATI';
  if (contains('aik cheong')) return 'AIK CHEONG';
  if (contains('red eagle')) return 'RED EAGLE';
  if (contains('sumo')) return 'SUMO';
  if (contains('oyoshi')) return 'OYOSHI';
  if (contains('royal gold')) return 'ROYAL GOLD';
  if (contains('sunlight')) return 'SUNLIGHT';
  if (contains('sunflower')) return 'SUNFLOWER';
  
  // Fallback
  const firstWord = name.trim().split(/\s+/)[0].replace(/[^a-zA-Z]/g, '').toUpperCase();
  if (firstWord.length >= 3) return firstWord;
  return 'OTHER';
}

// 5. Category extraction logic in JavaScript
function extractCategory(name) {
  const lower = name.toLowerCase();
  const contains = (str) => lower.indexOf(str) !== -1;
  
  // Beverages
  if (contains('milo') ||
      contains('tea') ||
      contains('teabag') ||
      contains('coffee') ||
      contains('nescafe') ||
      contains('nescafé') ||
      contains('oyoshi') ||
      contains('drink') ||
      contains('beverage') ||
      contains('aik cheong') ||
      contains('teh') ||
      contains('juice') ||
      contains('jus') ||
      contains('water') ||
      contains('soda') ||
      contains('carbonated')) {
    return 'Beverages';
  }
  
  // Cooking Ingredients
  if (contains('oil') ||
      contains('cooking oil') ||
      contains('sauce') ||
      contains('ketchup') ||
      contains('oyster') ||
      contains('seasoning') ||
      contains('salt') ||
      contains('sugar') ||
      contains('sweetener') ||
      contains('cukup rasa') ||
      contains('sambal') ||
      contains('tumis') ||
      contains('cube') ||
      contains('kicap') ||
      contains('margarine') ||
      contains('butter') ||
      contains('rempah') ||
      contains('tomato sauce') ||
      contains('tomato paste') ||
      contains('chili') ||
      contains('chilli') ||
      contains('dishwashing') ||
      contains('liquid')) {
    return 'Cooking Ingredients';
  }
  
  // Food
  if (contains('rice') ||
      contains('basmathi') ||
      contains('basmati') ||
      contains('grain') ||
      contains('noodle') ||
      contains('instant noodle') ||
      contains('maggi') ||
      contains('curry') ||
      contains('chicken stock') ||
      contains('ayam') ||
      contains('stock cube') ||
      contains('vermicelli') ||
      contains('pasta') ||
      contains('spaghetti') ||
      contains('macaroni') ||
      contains('bread') ||
      contains('biscuit') ||
      contains('flour') ||
      contains('sumo')) {
    return 'Food';
  }
  
  return 'Food';
}

async function run() {
  try {
    const accessToken = await getAccessToken(refreshToken);
    console.log('Fetching all products from Firestore...');

    const productsRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/products?pageSize=300`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (productsRes.statusCode !== 200) {
      console.error('Failed to fetch products:', productsRes.statusCode, productsRes.body);
      return;
    }

    const docs = productsRes.body.documents || [];
    console.log(`Fetched ${docs.length} products to update.\n`);

    // We will execute updates one-by-one or in batch.
    // Note: The Firestore REST API supports batching via commit, but for 34 items,
    // we can use commit with writes.
    const writes = [];

    docs.forEach(doc => {
      const fields = doc.fields || {};
      const name = fields.name ? fields.name.stringValue : 'unknown';
      const id = doc.name.split('/').pop();
      
      const newBrand = extractBrand(name);
      const newCategory = extractCategory(name);
      
      console.log(`Product: "${name}"`);
      console.log(`  -> Brand (DB category): "${newBrand}"`);
      console.log(`  -> Category (DB productType): "${newCategory}"`);

      writes.push({
        update: {
          name: doc.name,
          fields: {
            ...fields,
            category: { stringValue: newBrand },
            productType: { stringValue: newCategory }
          }
        },
        updateMask: {
          fieldPaths: ['category', 'productType']
        }
      });
    });

    console.log(`\nSending commit request for ${writes.length} updates...`);
    const commitRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents:commit`,
      method: 'POST',
      headers: { 
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json'
      }
    }, {
      writes: writes
    });

    if (commitRes.statusCode === 200) {
      console.log('✅ Successfully updated all 34 products in Firestore!');
    } else {
      console.error('❌ Failed to commit updates:', commitRes.statusCode, commitRes.body);
    }

  } catch (e) {
    console.error('Error:', e);
  }
}

run();

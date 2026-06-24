const https = require('https');
const fs = require('fs');
const path = require('path');

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

function getProductMatchKey(name) {
  return name.toLowerCase().replace(/[^a-z0-9]/g, '');
}

async function findCommonProducts() {
  try {
    console.log('Obtaining access token...');
    const accessToken = await getAccessToken(refreshToken);
    const project = 'smartshopper-mobile-4df1e';

    console.log('Fetching all products from Firestore...');
    const productsRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/products?pageSize=500`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (productsRes.statusCode !== 200) {
      console.error(`Failed to fetch products: ${productsRes.statusCode}`, productsRes.body);
      return;
    }

    const products = (productsRes.body.documents || []).map(doc => {
      const fields = doc.fields || {};
      const id = doc.name.split('/').pop();
      const name = fields.name ? fields.name.stringValue : 'Unknown';
      return { id, name };
    });

    console.log(`Loaded ${products.length} products.`);

    console.log('Fetching all prices from Firestore...');
    const pricesRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/prices?pageSize=1000`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (pricesRes.statusCode !== 200) {
      console.error(`Failed to fetch prices: ${pricesRes.statusCode}`, pricesRes.body);
      return;
    }

    const prices = (pricesRes.body.documents || []).map(doc => {
      const fields = doc.fields || {};
      const productId = fields.productId ? fields.productId.stringValue : '';
      const retailerId = fields.retailerId ? fields.retailerId.stringValue : '';
      const price = fields.price ? parseFloat(fields.price.doubleValue || fields.price.integerValue || '0') : 0.0;
      return { productId, retailerId, price };
    });

    console.log(`Loaded ${prices.length} prices.`);

    // Map product ID to product object
    const productMap = {};
    products.forEach(p => {
      productMap[p.id] = p;
    });

    // Group prices by normalized product name (match key)
    const grouped = {}; // matchKey -> { name, mydin: [], myaeon: [] }
    
    prices.forEach(price => {
      const product = productMap[price.productId];
      if (!product) return;

      const matchKey = getProductMatchKey(product.name);
      if (!grouped[matchKey]) {
        grouped[matchKey] = {
          name: product.name,
          mydin: [],
          myaeon: []
        };
      }

      if (price.retailerId === '1') {
        grouped[matchKey].mydin.push(price.price);
      } else if (price.retailerId === '2') {
        grouped[matchKey].myaeon.push(price.price);
      }
    });

    console.log('\n======================================================');
    console.log('PRODUCTS IN COMMON BETWEEN MYDIN AND MYAEON2GO');
    console.log('======================================================');

    let commonCount = 0;
    const commonList = [];

    for (const key of Object.keys(grouped)) {
      const group = grouped[key];
      if (group.mydin.length > 0 && group.myaeon.length > 0) {
        commonCount++;
        const mydinMin = Math.min(...group.mydin);
        const myaeonMin = Math.min(...group.myaeon);
        const diff = Math.abs(mydinMin - myaeonMin);
        const cheaper = mydinMin < myaeonMin ? 'MyDin' : 'myAEON2go';
        commonList.push({
          name: group.name,
          mydinPrice: mydinMin,
          myaeonPrice: myaeonMin,
          diff: diff,
          cheaper: cheaper
        });
      }
    }

    // Sort by name
    commonList.sort((a, b) => a.name.localeCompare(b.name));

    commonList.forEach((item, index) => {
      console.log(`${index + 1}. ${item.name}`);
      console.log(`   - MyDin Price:     RM ${item.mydinPrice.toFixed(2)}`);
      console.log(`   - myAEON2go Price: RM ${item.myaeonPrice.toFixed(2)}`);
      console.log(`   - Difference:      RM ${item.diff.toFixed(2)} (Cheaper at ${item.cheaper})`);
      console.log('------------------------------------------------------');
    });

    console.log(`\nTotal products in common: ${commonCount}`);

  } catch (e) {
    console.error('Error during execution:', e);
  }
}

findCommonProducts();

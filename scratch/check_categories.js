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
    console.log(`Found ${docs.length} products in database.`);

    const brands = new Set();
    const categories = new Set();
    const productList = [];

    docs.forEach(doc => {
      const fields = doc.fields || {};
      const name = fields.name ? fields.name.stringValue : 'unknown';
      const category = fields.category ? fields.category.stringValue : 'none'; // brand
      const productType = fields.productType ? fields.productType.stringValue : 'none'; // category
      const id = doc.name.split('/').pop();
      
      brands.add(category);
      categories.add(productType);
      productList.push({ id, name, brand: category, category: productType });
    });

    console.log('\nUnique Brands (category field in DB) in Firestore:');
    brands.forEach(b => console.log(` - "${b}"`));

    console.log('\nUnique Product Types (productType field in DB) in Firestore:');
    categories.forEach(c => console.log(` - "${c}"`));

    console.log('\nSample products list (first 10):');
    productList.slice(0, 10).forEach(p => {
      console.log(`ID: ${p.id} | Name: ${p.name} | Brand (DB category): ${p.brand} | Category (DB productType): ${p.category}`);
    });

  } catch (e) {
    console.error('Error:', e);
  }
}

run();

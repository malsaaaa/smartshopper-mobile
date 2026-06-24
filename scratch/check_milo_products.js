const https = require('https');
const fs = require('fs');
const path = require('path');

// Read token
const homeDir = process.env.USERPROFILE || process.env.HOME;
const firebaseConfigPath = path.join(homeDir, '.config', 'configstore', 'firebase-tools.json');
let refreshToken = JSON.parse(fs.readFileSync(firebaseConfigPath, 'utf8')).tokens.refresh_token;

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

async function main() {
  const token = await getAccessToken();
  const project = 'smartshopper-mobile-4df1e';
  
  // Fetch products
  let products = [];
  let pageToken = '';
  do {
    const res = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/products?pageSize=100` + (pageToken ? `&pageToken=${pageToken}` : ''),
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });
    const docs = res.body.documents || [];
    products = products.concat(docs);
    pageToken = res.body.nextPageToken || '';
  } while (pageToken);
  
  console.log(`Total products: ${products.length}`);
  const miloProds = products.filter(p => {
    const name = p.fields.name ? p.fields.name.stringValue.toLowerCase() : '';
    return name.includes('milo');
  });
  
  console.log(`\n=== Milo Products in DB (${miloProds.length}) ===`);
  miloProds.forEach(p => {
    const fields = p.fields || {};
    const name = fields.name ? fields.name.stringValue : 'Unknown';
    const category = fields.category ? fields.category.stringValue : 'Unknown';
    console.log(` - [Category/Retailer: ${category}] ${name} (ID: ${p.name.split('/').pop()})`);
  });
}

main();

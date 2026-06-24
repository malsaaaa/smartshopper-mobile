/**
 * print_all_products.js
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

async function main() {
  const token = await getAccessToken();
  const products = await fetchCollection(token, 'products');
  console.log(`Total products: ${products.length}`);
  for (const doc of products) {
    const parts = doc.name.split('/');
    const docId = parts[parts.length - 1];
    const fields = doc.fields;
    const name = fields.name ? fields.name.stringValue : '';
    const id = fields.id ? (fields.id.integerValue || fields.id.stringValue) : '';
    console.log(`Doc ID: ${docId} | Field ID: ${id} | Name: "${name}"`);
  }
}

main();

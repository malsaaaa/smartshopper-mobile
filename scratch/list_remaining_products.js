const https = require('https');
const fs = require('fs');
const path = require('path');

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
  
  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${project}/databases/(default)/documents/products?pageSize=100`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  const documents = res.body.documents || [];
  console.log(`\n=== Remaining Products in Firestore (${documents.length}) ===`);
  documents.forEach((doc, idx) => {
    const fields = doc.fields || {};
    const name = fields.name ? fields.name.stringValue : 'Unknown';
    console.log(` ${idx + 1}. ${name}`);
  });
}

main();

const https = require('https');
const fs = require('fs');
const path = require('path');

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

function request(options, postData = null) {
  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body ? JSON.parse(body) : null
        });
      });
    });
    req.on('error', reject);
    if (postData) {
      req.write(JSON.stringify(postData));
    }
    req.end();
  });
}

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
  return res.body.access_token;
}

async function checkRetailers() {
  try {
    const token = await getAccessToken(refreshToken);
    const project = 'smartshopper-mobile-4df1e';
    const res = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/retailers`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${token}` }
    });

    if (res.statusCode === 200) {
      const docs = res.body.documents || [];
      console.log(`Found ${docs.length} retailers:`);
      docs.forEach(doc => {
        const id = doc.name.split('/').pop();
        const fields = doc.fields || {};
        const name = fields.name ? fields.name.stringValue : 'N/A';
        const latitude = fields.latitude ? (fields.latitude.doubleValue || fields.latitude.integerValue) : 'N/A';
        const longitude = fields.longitude ? (fields.longitude.doubleValue || fields.longitude.integerValue) : 'N/A';
        console.log(`Retailer ID: ${id} | Name: ${name} | Latitude: ${latitude} | Longitude: ${longitude}`);
      });
    } else {
      console.error('Failed to get retailers:', res.statusCode, res.body);
    }
  } catch (err) {
    console.error('Error:', err);
  }
}

checkRetailers();

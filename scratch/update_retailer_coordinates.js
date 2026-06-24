/**
 * update_retailer_coordinates.js
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

async function updateRetailer(accessToken, id, lat, lng) {
  const url = `/v1/projects/${PROJECT}/databases/(default)/documents/retailers/${id}?updateMask.fieldPaths=latitude&updateMask.fieldPaths=longitude&updateMask.fieldPaths=updatedAt`;
  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: url,
    method: 'PATCH',
    headers: { 
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  }, {
    fields: {
      latitude: { doubleValue: lat },
      longitude: { doubleValue: lng },
      updatedAt: { stringValue: new Date().toISOString() } // simplified write
    }
  });
  
  if (res.statusCode === 200) {
    console.log(`✅ Successfully updated Retailer ${id} coordinates to (${lat}, ${lng})`);
  } else {
    console.error(`❌ Failed to update Retailer ${id}: HTTP ${res.statusCode}`, JSON.stringify(res.body));
  }
}

async function main() {
  try {
    const token = await getAccessToken();
    
    // 1. Mydin Jasin, Melaka
    await updateRetailer(token, '1', 2.2803761059533056, 102.39131648465751);
    
    // 2. AEON Melaka
    await updateRetailer(token, '2', 2.2365657630638127, 102.28151321103672);
    
    // 3. Lotus's Melaka
    await updateRetailer(token, '3', 2.218421926517962, 102.2471096807353);

  } catch (err) {
    console.error('Error:', err);
  }
}

main();

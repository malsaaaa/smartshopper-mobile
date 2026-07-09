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

async function readLogs() {
  const token = await getAccessToken(refreshToken);
  const project = 'smartshopper-mobile-4df1e';
  
  // Fetch logs
  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${project}/databases/(default)/documents/scraper_logs?pageSize=15&orderBy=timestamp%20desc`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${token}` }
  });

  if (res.statusCode !== 200) {
    console.error(`Failed to load logs: ${res.statusCode}`, res.body);
    return;
  }

  const documents = res.body.documents || [];
  console.log(`\nLast 15 Scraper Logs from Firestore:`);
  console.log(`==================================================`);
  for (const doc of documents) {
    const fields = doc.fields || {};
    const level = fields.level?.stringValue || 'INFO';
    const retailer = fields.retailer?.stringValue || 'UNKNOWN';
    const message = fields.message?.stringValue || '';
    const time = fields.timestamp?.timestampValue || '';
    
    console.log(`[${time}] [${level}] [${retailer}] ${message}`);
  }
}

readLogs().catch(err => {
  console.error("Error reading logs:", err);
});

const https = require('https');
const fs = require('fs');
const path = require('path');

const apiKey = "AIzaSyBoFmctT8jtsis5qRT_hLwY8mynoXqkauw";
const project = 'smartshopper-mobile-4df1e';
const targetEmail = 'asfa@gmail.com';
const newPassword = 'admin123';

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
    console.log('Obtaining access token...');
    const accessToken = await getAccessToken(refreshToken);

    console.log('Fetching users from Firestore...');
    const usersRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/users`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (usersRes.statusCode !== 200) {
      console.error('Failed to fetch users:', usersRes.statusCode, usersRes.body);
      return;
    }

    const docs = usersRes.body.documents || [];
    let targetUid = null;

    docs.forEach(doc => {
      const fields = doc.fields || {};
      const email = fields.email ? fields.email.stringValue : 'unknown';
      const uid = doc.name.split('/').pop();
      console.log(`User: ${email} | UID: ${uid}`);
      if (email === targetEmail) {
        targetUid = uid;
      }
    });

    if (!targetUid) {
      console.error(`Target user ${targetEmail} not found!`);
      return;
    }

    console.log(`\nUpdating password for user ${targetEmail} (UID: ${targetUid}) to "${newPassword}"...`);
    
    // Call the Google Identity Toolkit accounts:update API using the project-specific admin endpoint
    const updateRes = await request({
      hostname: 'identitytoolkit.googleapis.com',
      path: `/v1/projects/${project}/accounts:update`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      }
    }, {
      localId: targetUid,
      password: newPassword
    });

    if (updateRes.statusCode === 200) {
      console.log('Password updated successfully!');
      console.log('Response:', updateRes.body);
    } else {
      console.error('Failed to update password:', updateRes.statusCode, updateRes.body);
    }

  } catch (e) {
    console.error('Error:', e);
  }
}

run();

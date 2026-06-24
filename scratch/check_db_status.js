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

// 4. Check status of all collections
async function checkStatus() {
  try {
    console.log('Obtaining access token...');
    const accessToken = await getAccessToken(refreshToken);
    const project = 'smartshopper-mobile-4df1e';

    console.log('\n--- Checking Scraper Jobs ---');
    const jobsRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/scraper_jobs`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (jobsRes.statusCode === 200) {
      const docs = jobsRes.body.documents || [];
      console.log(`Found ${docs.length} jobs:`);
      docs.forEach(doc => {
        const fields = doc.fields || {};
        const id = doc.name.split('/').pop();
        const status = fields.status ? fields.status.stringValue : 'unknown';
        const retailerName = fields.retailerName ? fields.retailerName.stringValue : 'unknown';
        const targetUrl = fields.targetUrl ? fields.targetUrl.stringValue : 'unknown';
        console.log(`Job ID: ${id} | Retailer: ${retailerName} | Status: ${status} | Target: ${targetUrl}`);
      });
    } else {
      console.error(`Failed to fetch scraper jobs: ${jobsRes.statusCode}`, jobsRes.body);
    }

    console.log('\n--- Checking Admin/SuperAdmin Users ---');
    const usersRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/projects/${project}/databases/(default)/documents/users`,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (usersRes.statusCode === 200) {
      const docs = usersRes.body.documents || [];
      console.log(`Found ${docs.length} total users in database.`);
      const admins = [];
      docs.forEach(doc => {
        const fields = doc.fields || {};
        const email = fields.email ? fields.email.stringValue : 'unknown';
        const isAdmin = fields.isAdmin ? fields.isAdmin.booleanValue : false;
        const isSuperAdmin = fields.isSuperAdmin ? fields.isSuperAdmin.booleanValue : false;
        if (isAdmin || isSuperAdmin) {
          admins.push({ email, isAdmin, isSuperAdmin });
        }
      });
      if (admins.length > 0) {
        console.log('Admins found:');
        admins.forEach(admin => {
          console.log(` - ${admin.email} (isAdmin: ${admin.isAdmin}, isSuperAdmin: ${admin.isSuperAdmin})`);
        });
      } else {
        console.log('No admin users found in database!');
      }
    } else {
      console.error(`Failed to fetch users: ${usersRes.statusCode}`, usersRes.body);
    }

  } catch (e) {
    console.error('Error during execution:', e);
  }
}

checkStatus();

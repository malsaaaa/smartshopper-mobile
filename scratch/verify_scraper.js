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

// 4. Delete all documents in a Firestore collection
async function clearCollection(accessToken, colName) {
  const project = 'smartshopper-mobile-4df1e';
  console.log(`Clearing collection: ${colName}...`);

  // Get all documents in the collection
  const listRes = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${project}/databases/(default)/documents/${colName}?pageSize=300`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });

  if (listRes.statusCode !== 200) {
    console.log(`Collection ${colName} is empty or failed to load: ${listRes.statusCode}`);
    return;
  }

  const documents = listRes.body.documents || [];
  console.log(`Found ${documents.length} documents in ${colName}. Deleting...`);

  for (const doc of documents) {
    // Document name format is projects/{project}/databases/(default)/documents/{colName}/{docId}
    const docPath = doc.name;
    const delRes = await request({
      hostname: 'firestore.googleapis.com',
      path: `/v1/${docPath}`,
      method: 'DELETE',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    if (delRes.statusCode !== 200 && delRes.statusCode !== 204) {
      console.error(`Failed to delete ${docPath}: ${delRes.statusCode}`);
    }
  }
  console.log(`Cleared ${colName}.`);
}

// 5. Trigger scraper job
async function triggerScraper(accessToken, jobId) {
  const project = 'smartshopper-mobile-4df1e';
  const documentPath = `projects/${project}/databases/(default)/documents/scraper_jobs/${jobId}`;
  
  console.log(`Setting status of ${jobId} to pending...`);
  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/${documentPath}?updateMask.fieldPaths=status`,
    method: 'PATCH',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json'
    }
  }, {
    fields: {
      status: { stringValue: 'pending' }
    }
  });

  if (res.statusCode === 200) {
    console.log(`Job ${jobId} status successfully set to pending!`);
  } else {
    throw new Error(`Failed to update job status: ${res.statusCode} ${JSON.stringify(res.body)}`);
  }
}

// 6. Verify products are scraped
async function verifyProducts(accessToken) {
  const project = 'smartshopper-mobile-4df1e';
  
  console.log('Querying scraped products from Firestore...');
  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/projects/${project}/databases/(default)/documents/products?pageSize=50`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });

  if (res.statusCode !== 200) {
    console.error(`Failed to get products: ${res.statusCode}`);
    return 0;
  }

  const documents = res.body.documents || [];
  console.log(`Verified! Found ${documents.length} products in Firestore.`);
  if (documents.length > 0) {
    console.log('Sample scraped products:');
    documents.slice(0, 5).forEach(doc => {
      const fields = doc.fields || {};
      const name = fields.name ? fields.name.stringValue : 'Unknown';
      const category = fields.category ? fields.category.stringValue : 'Unknown';
      console.log(` - [${category}] ${name}`);
    });
  }
  return documents.length;
}

// 7. Check job status
async function checkJobStatus(accessToken, jobId) {
  const project = 'smartshopper-mobile-4df1e';
  const documentPath = `projects/${project}/databases/(default)/documents/scraper_jobs/${jobId}`;

  const res = await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/${documentPath}`,
    method: 'GET',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });

  if (res.statusCode === 200) {
    const fields = res.body.fields || {};
    return {
      status: fields.status ? fields.status.stringValue : 'unknown',
      itemsScraped: fields.itemsScraped ? parseInt(fields.itemsScraped.integerValue) : 0
    };
  }
  return null;
}

async function main() {
  try {
    console.log('Obtaining access token...');
    const accessToken = await getAccessToken(refreshToken);
    console.log('Token obtained.');

    // Step 1: Clear database
    console.log('\n--- Step 1: Clearing database ---');
    await clearCollection(accessToken, 'products');
    await clearCollection(accessToken, 'prices');
    await clearCollection(accessToken, 'retailers');

    // Step 2: Trigger MyDin Scraper
    console.log('\n--- Step 2: Triggering Scraper ---');
    await triggerScraper(accessToken, 'job_mydin');

    // Step 3: Wait and monitor status
    console.log('\n--- Step 3: Waiting for Local Client Scraper to Run (45 seconds) ---');
    for (let i = 1; i <= 9; i++) {
      await new Promise(r => setTimeout(r, 5000));
      const job = await checkJobStatus(accessToken, 'job_mydin');
      if (job) {
        console.log(`[${i * 5}s] Job Status: ${job.status}, Items Scraped: ${job.itemsScraped}`);
        if (job.status === 'success' || job.status === 'error') {
          break;
        }
      }
    }

    // Step 4: Verify scraped products
    console.log('\n--- Step 4: Verification ---');
    const count = await verifyProducts(accessToken);
    if (count > 0) {
      console.log('\n✅ Scraper verification SUCCESS!');
    } else {
      console.log('\n❌ Scraper verification FAILED: No products found.');
    }
  } catch (e) {
    console.error('Error during execution:', e);
  }
}

main();

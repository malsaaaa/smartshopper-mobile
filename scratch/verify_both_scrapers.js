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

// Helper to fetch all documents in a collection (with pagination)
async function fetchCollection(accessToken, colName) {
  const project = 'smartshopper-mobile-4df1e';
  let documents = [];
  let pageToken = '';
  
  do {
    const url = `/v1/projects/${project}/databases/(default)/documents/${colName}?pageSize=100` + (pageToken ? `&pageToken=${pageToken}` : '');
    const res = await request({
      hostname: 'firestore.googleapis.com',
      path: url,
      method: 'GET',
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });
    
    if (res.statusCode !== 200) {
      break;
    }
    
    const docs = res.body.documents || [];
    documents = documents.concat(docs);
    pageToken = res.body.nextPageToken || '';
  } while (pageToken);
  
  return documents;
}

// 4. Delete all documents in a Firestore collection
async function clearCollection(accessToken, colName) {
  console.log(`Clearing collection: ${colName}...`);
  const documents = await fetchCollection(accessToken, colName);
  console.log(`Found ${documents.length} documents in ${colName}. Deleting...`);

  for (const doc of documents) {
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

// 6. Check job status
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

// 7. Analyze and verify overlap
async function verifyAndAnalyzeOverlap(accessToken) {
  console.log('\n--- Step 4: Fetching Scraped Data for Analysis ---');
  
  // 1. Fetch products
  const products = await fetchCollection(accessToken, 'products');
  console.log(`Found ${products.length} total products in Firestore.`);

  // 2. Fetch prices
  const prices = await fetchCollection(accessToken, 'prices');
  console.log(`Found ${prices.length} total price entries in Firestore.`);

  // Parse products
  const productMap = {}; // productId -> productInfo
  products.forEach(doc => {
    const fields = doc.fields || {};
    const name = fields.name ? fields.name.stringValue : 'Unknown';
    // Document name is projects/{project}/databases/(default)/documents/products/{docId}
    const docId = doc.name.split('/').pop();
    productMap[docId] = {
      id: docId,
      name: name,
      category: fields.category ? fields.category.stringValue : 'Unknown'
    };
  });

  // Parse prices and associate with products
  const productMatchGroups = {}; // matchKey -> { name, mydinPrice, aeonPrice }
  
  prices.forEach(doc => {
    const fields = doc.fields || {};
    const productId = fields.productId ? fields.productId.stringValue : null;
    const retailerId = fields.retailerId ? parseInt(fields.retailerId.stringValue || fields.retailerId.integerValue) : null;
    const price = fields.price ? parseFloat(fields.price.doubleValue || fields.price.integerValue || fields.price.stringValue) : 0;
    
    if (!productId || isNaN(retailerId)) return;

    const product = productMap[productId];
    if (!product) return;

    // Generate match key (alphanumeric only, lowercase)
    const matchKey = product.name.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();

    if (!productMatchGroups[matchKey]) {
      productMatchGroups[matchKey] = {
        name: product.name,
        mydinPrices: [],
        aeonPrices: []
      };
    }

    if (retailerId === 1) { // MyDin
      productMatchGroups[matchKey].mydinPrices.push(price);
    } else if (retailerId === 2) { // myAEON2go
      productMatchGroups[matchKey].aeonPrices.push(price);
    }
  });

  // Find common products
  const commonProducts = [];
  Object.values(productMatchGroups).forEach(group => {
    if (group.mydinPrices.length > 0 && group.aeonPrices.length > 0) {
      commonProducts.push({
        name: group.name,
        mydinPrice: Math.min(...group.mydinPrices),
        aeonPrice: Math.min(...group.aeonPrices)
      });
    }
  });

  console.log('\n=== Overlap Analysis Results ===');
  console.log(`Common Products Count: ${commonProducts.length}`);
  
  if (commonProducts.length > 0) {
    console.log('\nCommon Products and Price Comparison:');
    commonProducts.forEach((p, idx) => {
      const diff = (p.aeonPrice - p.mydinPrice).toFixed(2);
      const sign = diff > 0 ? '+' : '';
      console.log(` ${idx + 1}. ${p.name}`);
      console.log(`    - MyDin Price     : RM ${p.mydinPrice.toFixed(2)}`);
      console.log(`    - myAEON2go Price : RM ${p.aeonPrice.toFixed(2)} (Diff: ${sign}${diff})`);
    });
  } else {
    console.log('\n❌ No common products matched! Check standardizer rules and search terms.');
  }

  return commonProducts.length;
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

    // Step 2: Trigger both scrapers
    console.log('\n--- Step 2: Triggering Scraper Jobs ---');
    await triggerScraper(accessToken, 'job_mydin');
    await triggerScraper(accessToken, 'job_myaeon2go');

    // Step 3: Monitor scraper jobs
    console.log('\n--- Step 3: Monitoring Scraper Jobs ---');
    const jobsToMonitor = ['job_mydin', 'job_myaeon2go'];
    const completedJobs = {};
    
    // We poll every 5 seconds for up to 2.5 minutes (30 iterations)
    for (let i = 1; i <= 30; i++) {
      await new Promise(r => setTimeout(r, 5000));
      
      let allDone = true;
      for (const jobId of jobsToMonitor) {
        if (completedJobs[jobId]) continue;
        
        const job = await checkJobStatus(accessToken, jobId);
        if (job) {
          console.log(`[${i * 5}s] ${jobId} Status: ${job.status}, Items Scraped: ${job.itemsScraped}`);
          if (job.status === 'success' || job.status === 'error') {
            completedJobs[jobId] = job;
          } else {
            allDone = false;
          }
        } else {
          allDone = false;
        }
      }
      
      if (allDone) {
        console.log('All scraper jobs completed!');
        break;
      }
    }

    // Step 4: Analyze overlap
    const commonCount = await verifyAndAnalyzeOverlap(accessToken);
    if (commonCount > 0) {
      console.log('\n✅ Scraper verification and overlap analysis SUCCESS!');
    } else {
      console.log('\n❌ Scraper verification FAILED: No common products found.');
    }
  } catch (e) {
    console.error('Error during execution:', e);
  }
}

main();

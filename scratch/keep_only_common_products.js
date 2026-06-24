const https = require('https');
const fs = require('fs');
const path = require('path');

// 1. Read token
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
    if (res.statusCode !== 200) break;
    const docs = res.body.documents || [];
    documents = documents.concat(docs);
    pageToken = res.body.nextPageToken || '';
  } while (pageToken);
  return documents;
}

async function triggerScraper(accessToken, jobId) {
  const project = 'smartshopper-mobile-4df1e';
  const documentPath = `projects/${project}/databases/(default)/documents/scraper_jobs/${jobId}`;
  console.log(`Setting status of ${jobId} to pending...`);
  await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/${documentPath}?updateMask.fieldPaths=status`,
    method: 'PATCH',
    headers: { 'Authorization': `Bearer ${accessToken}`, 'Content-Type': 'application/json' }
  }, { fields: { status: { stringValue: 'pending' } } });
}

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
    return fields.status ? fields.status.stringValue : 'unknown';
  }
  return null;
}

async function deleteDocument(accessToken, docPath) {
  await request({
    hostname: 'firestore.googleapis.com',
    path: `/v1/${docPath}`,
    method: 'DELETE',
    headers: { 'Authorization': `Bearer ${accessToken}` }
  });
}

async function main() {
  try {
    console.log('Obtaining access token...');
    const accessToken = await getAccessToken();
    console.log('Token obtained.');

    // Step 1: Trigger both scrapers
    console.log('\n--- Step 1: Triggering Scraper Jobs ---');
    await triggerScraper(accessToken, 'job_mydin');
    await triggerScraper(accessToken, 'job_myaeon2go');

    // Step 2: Monitor scraper jobs
    console.log('\n--- Step 2: Monitoring Scraper Jobs ---');
    const jobs = ['job_mydin', 'job_myaeon2go'];
    const completed = {};
    for (let i = 1; i <= 30; i++) {
      await new Promise(r => setTimeout(r, 5000));
      let allDone = true;
      for (const jobId of jobs) {
        if (completed[jobId]) continue;
        const status = await checkJobStatus(accessToken, jobId);
        console.log(`[${i * 5}s] ${jobId} Status: ${status}`);
        if (status === 'success' || status === 'error') {
          completed[jobId] = true;
        } else {
          allDone = false;
        }
      }
      if (allDone) {
        console.log('Scraper runs complete!');
        break;
      }
    }

    // Step 3: Fetch all products and prices
    console.log('\n--- Step 3: Fetching Data from Firestore ---');
    const rawProducts = await fetchCollection(accessToken, 'products');
    const rawPrices = await fetchCollection(accessToken, 'prices');
    console.log(`Fetched ${rawProducts.length} products and ${rawPrices.length} prices.`);

    // Map products
    const productMap = {};
    rawProducts.forEach(doc => {
      const fields = doc.fields || {};
      const name = fields.name ? fields.name.stringValue : 'Unknown';
      const docId = doc.name.split('/').pop();
      productMap[docId] = {
        docPath: doc.name,
        id: docId,
        name: name,
        category: fields.category ? fields.category.stringValue : 'Unknown'
      };
    });

    // Group by match key
    const matchGroups = {}; // matchKey -> { name, products: [], prices: [], retailers: Set }
    
    rawPrices.forEach(doc => {
      const fields = doc.fields || {};
      const productId = fields.productId ? fields.productId.stringValue : null;
      const retailerId = fields.retailerId ? parseInt(fields.retailerId.stringValue || fields.retailerId.integerValue) : null;
      
      if (!productId || isNaN(retailerId)) return;
      const product = productMap[productId];
      if (!product) return;

      const matchKey = product.name.replace(/[^a-zA-Z0-9]/g, '').toLowerCase();
      if (!matchGroups[matchKey]) {
        matchGroups[matchKey] = {
          name: product.name,
          productIds: new Set(),
          productPaths: new Set(),
          pricePaths: [],
          retailers: new Set()
        };
      }

      matchGroups[matchKey].productIds.add(productId);
      matchGroups[matchKey].productPaths.add(product.docPath);
      matchGroups[matchKey].pricePaths.push(doc.name);
      matchGroups[matchKey].retailers.add(retailerId);
    });

    // Step 4: Identify non-common products for deletion
    console.log('\n--- Step 4: Analyzing Overlap and Filtering ---');
    const toDeletePaths = [];
    let keptCount = 0;
    let deletedProductCount = 0;

    for (const key in matchGroups) {
      const group = matchGroups[key];
      // Check if group contains both MyDin (1) and myAEON2go (2)
      if (group.retailers.has(1) && group.retailers.has(2)) {
        keptCount++;
        console.log(`✅ KEEP: "${group.name}" (Active in both retailers)`);
      } else {
        // Mark all products and prices in this non-common group for deletion
        group.productPaths.forEach(path => {
          toDeletePaths.push(path);
          deletedProductCount++;
        });
        group.pricePaths.forEach(path => {
          toDeletePaths.push(path);
        });
        console.log(`❌ REMOVE: "${group.name}" (Exclusive to retailer: ${Array.from(group.retailers).join(', ')})`);
      }
    }

    // Also delete any products that have no price entries at all (orphan products)
    const activeProductIds = new Set();
    Object.values(matchGroups).forEach(g => g.productIds.forEach(id => activeProductIds.add(id)));
    
    rawProducts.forEach(doc => {
      const docId = doc.name.split('/').pop();
      if (!activeProductIds.has(docId)) {
        toDeletePaths.push(doc.name);
        deletedProductCount++;
        console.log(`❌ REMOVE ORPHAN: "${productMap[docId]?.name || docId}"`);
      }
    });

    // Step 5: Perform Deletion
    console.log(`\n--- Step 5: Deleting ${toDeletePaths.length} non-common documents (Products: ${deletedProductCount}) ---`);
    if (toDeletePaths.length > 0) {
      for (let idx = 0; idx < toDeletePaths.length; idx++) {
        const docPath = toDeletePaths[idx];
        await deleteDocument(accessToken, docPath);
        if ((idx + 1) % 50 === 0 || idx === toDeletePaths.length - 1) {
          console.log(`Deleted ${idx + 1}/${toDeletePaths.length} documents...`);
        }
      }
    }

    console.log('\n=== Cleanup Execution Completed successfully ===');
    console.log(`Total Common Products Kept: ${keptCount}`);
    console.log(`Total Exclusive Products Deleted: ${deletedProductCount}`);
    console.log(`Total Price Entries Removed: ${toDeletePaths.length - deletedProductCount}`);
  } catch (e) {
    console.error('Error during execution:', e);
  }
}

main();

/**
 * Capture the actual GET request (not CORS preflight) and reproduce it.
 * Key insight: the API requires channel, key, version, accept-language headers.
 */
const puppeteer = require('puppeteer');
const https = require('https');

function httpsGet(url, headers) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const req = https.get({
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      headers,
    }, (res) => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
  });
}

async function run() {
  const browser = await puppeteer.launch({ headless: true, args: ['--no-sandbox', '--disable-setuid-sandbox'] });
  const page = await browser.newPage();

  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  let capturedGet = null;

  await page.setRequestInterception(true);
  page.on('request', (req) => {
    const url = req.url();
    const method = req.method();
    if (url.includes('lotuss-mobile-bff/product/v2/products') && method === 'GET') {
      if (!capturedGet) {
        console.log('\n--- CAPTURED GET REQUEST ---');
        console.log('URL:', url);
        console.log('Headers:', JSON.stringify(req.headers(), null, 2));
        capturedGet = { url, headers: req.headers() };
      }
    }
    req.continue();
  });

  console.log('Navigating to Lotus search page...');
  try {
    await page.goto('https://www.lotuss.com.my/en/search/milo?sort=relevance:DESC', {
      waitUntil: 'networkidle2',
      timeout: 30000,
    });
  } catch (e) {
    console.log('Timeout:', e.message);
  }

  await new Promise(r => setTimeout(r, 3000));

  if (capturedGet) {
    console.log('\n--- Replaying captured GET request ---');
    const { status, body } = await httpsGet(capturedGet.url, capturedGet.headers);
    console.log('Status:', status);
    if (status === 200) {
      const json = JSON.parse(body);
      const products = json.data?.products || [];
      console.log(`\nTotal in API: ${json.meta?.total}`);
      console.log(`Products returned: ${products.length}\n`);
      if (products.length > 0) {
        console.log('--- First product (full JSON) ---');
        console.log(JSON.stringify(products[0], null, 2));
        console.log('\n--- Product list ---');
        products.forEach((p, i) => {
          const price = p.priceRange?.minimumPrice?.regularPrice?.value
            || p.price?.regularPrice?.amount?.value
            || 0;
          const finalPrice = p.priceRange?.minimumPrice?.finalPrice?.value || price;
          const imageUrl = p.smallImage?.url || p.image?.url || '';
          const urlKey = p.urlKey || p.url_key || '';
          console.log(`  ${i+1}. ${p.name}`);
          console.log(`     SKU:      ${p.sku}`);
          console.log(`     Regular:  RM ${price}`);
          console.log(`     Final:    RM ${finalPrice}`);
          console.log(`     URL Key:  ${urlKey}`);
          console.log(`     Image:    ${imageUrl.substring(0, 80)}`);
        });

        // Extract the required custom headers so we can use them in Dart
        console.log('\n\n--- Custom API Headers (for Dart scraper) ---');
        const importantHeaders = ['channel', 'key', 'version', 'x-request-id', 'accept-language', 'accept', 'origin', 'referer'];
        importantHeaders.forEach(h => {
          if (capturedGet.headers[h]) {
            console.log(`  ${h}: ${capturedGet.headers[h]}`);
          }
        });
      }
    } else {
      console.log('Error body:', body.substring(0, 800));
    }
  } else {
    console.log('\nNo GET request was captured. The page may not have loaded products.');
    // Print page source for debugging
    const text = await page.evaluate(() => document.body.innerText.substring(0, 1000));
    console.log('Page text:', text);
  }

  await browser.close();
}

run().catch(console.error);

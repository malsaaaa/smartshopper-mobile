/**
 * Test the Lotus API endpoint directly to inspect the product JSON structure.
 */
const https = require('https');

const WEBSITE_CODE = 'malaysia_hy';
const API_BASE = 'api-o2o.lotuss.com.my';
const LIMIT = 5; // Just 5 for inspection

function request(path) {
  return new Promise((resolve, reject) => {
    const req = https.get({ hostname: API_BASE, path, headers: { 'Accept': 'application/json' } }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    req.on('error', reject);
  });
}

async function run() {
  for (const search of ['cooking oil', 'milo']) {
    const q = JSON.stringify({ offset: 0, limit: LIMIT, search, sort: 'relevance:DESC', filter: {}, websiteCode: WEBSITE_CODE });
    const path = `/lotuss-mobile-bff/product/v2/products?q=${encodeURIComponent(q)}`;

    console.log(`\n${'='.repeat(60)}\nSearch: "${search}"\n${'='.repeat(60)}`);
    console.log(`GET https://${API_BASE}${path}\n`);

    const { status, body } = await request(path);
    console.log(`Status: ${status}`);

    const json = JSON.parse(body);
    console.log(`Total results: ${json.meta?.total}`);
    console.log(`Returned:      ${json.meta?.limit}\n`);

    const products = json.data?.products || [];
    console.log(`Products array length: ${products.length}`);
    if (products.length > 0) {
      console.log('\n--- First product raw JSON (all fields) ---');
      console.log(JSON.stringify(products[0], null, 2));

      console.log('\n--- All products (name + price + url) ---');
      products.forEach((p, i) => {
        const name = p.name || p.productName || p.title || '(no name)';
        const price = p.price?.regularPrice?.amount?.value
          || p.priceRange?.minimumPrice?.regularPrice?.value
          || p.price_range?.minimum_price?.regular_price?.value
          || p.finalPrice || p.price || 0;
        const sku = p.sku || '';
        const urlKey = p.urlKey || p.url_key || '';
        const imageUrl = p.smallImage?.url || p.image?.url || p.thumbnail?.url || '';
        const productUrl = urlKey ? `https://www.lotuss.com.my/en/product/${urlKey}` : '';
        console.log(`  ${i + 1}. ${name}`);
        console.log(`     SKU:   ${sku}`);
        console.log(`     Price: RM ${price}`);
        console.log(`     URL:   ${productUrl}`);
        console.log(`     Image: ${imageUrl.substring(0, 80)}`);
      });
    }
  }
}

run().catch(console.error);

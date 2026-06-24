/**
 * Quick test: call the Lotus API with cooking oil search to verify headers + pagination.
 */
const https = require('https');

const API_HEADERS = {
  'accept': 'application/json, text/plain, */*',
  'accept-language': 'en',
  'channel': 'web',
  'version': '2.3.9',
  'key': 'SeiRQmEDnaZXOlpfKhCjV4Bo2y6vAcW99QKmzifsgP2uCMN7wF3ahRXex84kH6qUVIWoY5Dp0GEljdAvS1JytOZcLbnBTr',
  'origin': 'https://www.lotuss.com.my',
  'referer': 'https://www.lotuss.com.my/',
  'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
};

function get(q) {
  const path = `/lotuss-mobile-bff/product/v2/products?q=${encodeURIComponent(JSON.stringify(q))}`;
  return new Promise((resolve, reject) => {
    https.get({ hostname: 'api-o2o.lotuss.com.my', path, headers: API_HEADERS }, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => resolve({ status: res.statusCode, body }));
    }).on('error', reject);
  });
}

async function run() {
  for (const search of ['cooking oil', 'milo']) {
    console.log(`\n${'='.repeat(60)}\nSearch: "${search}"\n${'='.repeat(60)}`);
    let offset = 0;
    let total = 30;
    let allProducts = [];

    while (offset < total && offset < 60) { // cap at 60 for test
      const { status, body } = await get({ offset, limit: 30, search, sort: 'relevance:DESC', filter: {}, websiteCode: 'malaysia_hy' });
      if (status !== 200) { console.log(`Error ${status}`); break; }
      const json = JSON.parse(body);
      total = json.meta?.total || 0;
      const products = json.data?.products || [];
      allProducts.push(...products);
      console.log(`  Page offset=${offset}: got ${products.length}, total=${total}`);
      offset += 30;
    }

    console.log(`\nTotal products fetched: ${allProducts.length}`);
    allProducts.slice(0, 5).forEach((p, i) => {
      const price = p.priceRange?.minimumPrice?.finalPrice?.value || 0;
      console.log(`  ${i+1}. ${p.name} — RM ${price}`);
    });
  }
}

run().catch(console.error);

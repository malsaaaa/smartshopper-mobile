const https = require('https');

function getJson(url, headers = {}) {
  return new Promise((resolve) => {
    const defaultHeaders = {
      'accept': 'application/json, text/plain, */*',
      'content-type': 'application/json',
      'api-json': 'true',
      'isfromspa': 'false',
      'x-csrf-token': 'zAZtwxfWJSl3C72w6Kq9UAGQ6BkM4yD6lTXBx7-m38q',
      'referer': 'https://myaeon2go.com/',
      'origin': 'https://myaeon2go.com',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36'
    };

    const req = https.get(url, { headers: { ...defaultHeaders, ...headers } }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          body: body
        });
      });
    });

    req.on('error', (e) => {
      resolve({
        statusCode: 500,
        body: e.message
      });
    });
  });
}

async function testEndpoints() {
  const baseUrl = 'https://myaeon2go.com';
  const term = 'cooking%20oil';

  // 1. Try pleType=search with query, search, q, or text
  const candidates = [
    `${baseUrl}/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&query=${term}&pleType=search`,
    `${baseUrl}/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&search=${term}&pleType=search`,
    `${baseUrl}/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&q=${term}&pleType=search`,
    `${baseUrl}/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&text=${term}&pleType=search`,
    
    // 2. Try pleType=softCategory but passing search
    `${baseUrl}/api/product/ples?getSmartBrand=true&isCarousel=true&inStockOnly=true&limit=48&excludeVariants=&serviceType=&skipProduct=false&query=${term}&pleType=softCategory`,
    
    // 3. Try standard search route API (if any)
    `${baseUrl}/api/product/search?query=${term}&limit=48`,
    `${baseUrl}/api/product/search?q=${term}&limit=48`,
    
    // 4. Try Next.js internal data fetch (often works if it is Next.js)
    // Note: Next.js build ID might be needed, but we can try to see if there's a direct API
    `${baseUrl}/api/search?q=${term}`,
    `${baseUrl}/api/search?query=${term}`
  ];

  console.log('Testing candidates...');
  for (let i = 0; i < candidates.length; i++) {
    const url = candidates[i];
    console.log(`\nCandidate ${i+1}: ${url}`);
    const res = await getJson(url);
    console.log(`Status Code: ${res.statusCode}`);
    if (res.statusCode === 200) {
      console.log(`Body Length: ${res.body.length}`);
      try {
        const json = JSON.parse(res.body);
        // Check if we got products
        const keys = Object.keys(json);
        console.log(`Top-level JSON keys: ${keys.join(', ')}`);
        
        // Find productListEntities or variants or items
        let count = 0;
        if (json.productListEntities) count = json.productListEntities.length;
        else if (json.products) count = json.products.length;
        else if (json.items) count = json.items.length;
        
        console.log(`Products found: ${count}`);
        if (count > 0) {
          const first = json.productListEntities ? json.productListEntities[0] : (json.products ? json.products[0] : json.items[0]);
          console.log(`Sample Product Name: ${first.nameText || first.name || first.extendedName || 'Unknown'}`);
          console.log(`SUCCESS! This endpoint works.`);
          break;
        }
      } catch (e) {
        console.log('Failed to parse JSON:', e.message);
      }
    } else {
      console.log(`Body Snippet: ${res.body.substring(0, 100)}`);
    }
  }
}

testEndpoints();

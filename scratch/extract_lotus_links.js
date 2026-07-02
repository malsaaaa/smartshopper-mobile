const https = require('https');

function httpsGet(url) {
  return new Promise((resolve, reject) => {
    const parsed = new URL(url);
    const req = https.get({
      hostname: parsed.hostname,
      path: parsed.pathname + parsed.search,
      headers: {
        'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'accept-language': 'en-US,en;q=0.9',
      }
    }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => resolve({
        status: res.statusCode,
        headers: res.headers,
        body
      }));
    });
    req.on('error', reject);
  });
}

async function run() {
  let url = 'https://www.lotuss.com.my/en/search?q=milo';
  
  for (let i = 0; i < 5; i++) {
    console.log(`GET ${url}`);
    const { status, headers, body } = await httpsGet(url);
    console.log(`Status: ${status}`);
    
    if (status >= 300 && status < 400 && headers.location) {
      url = headers.location.startsWith('http') 
        ? headers.location 
        : `https://www.lotuss.com.my` + headers.location;
      continue;
    }
    
    // Find all matches for hrefs containing products or product
    const regex = /href="([^"]*product[^"]*)"/g;
    const matches = new Set();
    let match;
    while ((match = regex.exec(body)) !== null) {
      matches.add(match[1]);
    }
    
    console.log(`Found ${matches.size} product-related href links in page source:`);
    Array.from(matches).slice(0, 30).forEach((link, i) => {
      console.log(`  [${i+1}] ${link}`);
    });
    break;
  }
}

run().catch(console.error);

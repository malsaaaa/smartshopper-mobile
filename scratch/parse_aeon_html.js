const https = require('https');

function getHtml(url) {
  return new Promise((resolve) => {
    const headers = {
      'accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
      'referer': 'https://myaeon2go.com/',
      'accept-language': 'en-US,en;q=0.9'
    };

    const req = https.get(url, { headers }, (res) => {
      let body = '';
      res.on('data', chunk => body += chunk);
      res.on('end', () => {
        resolve({
          statusCode: res.statusCode,
          headers: res.headers,
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

async function run() {
  const url = 'https://myaeon2go.com/products/search/cooking%20oil';
  console.log(`Fetching HTML from ${url}...`);
  const res = await getHtml(url);
  console.log(`Status Code: ${res.statusCode}`);
  
  if (res.statusCode !== 200) {
    console.log(`Failed to fetch. Body snippet: ${res.body.substring(0, 300)}`);
    return;
  }

  console.log(`HTML Length: ${res.body.length} characters`);

  // Check for __NEXT_DATA__
  const nextDataIndex = res.body.indexOf('id="__NEXT_DATA__"');
  if (nextDataIndex !== -1) {
    console.log('Found __NEXT_DATA__ script tag!');
    const start = res.body.indexOf('>', nextDataIndex) + 1;
    const end = res.body.indexOf('</script>', start);
    const jsonStr = res.body.substring(start, end);
    try {
      const json = JSON.parse(jsonStr);
      console.log('Successfully parsed __NEXT_DATA__ JSON!');
      console.log('Keys in JSON:', Object.keys(json));
      console.log('Build ID:', json.buildId);
      console.log('Page:', json.page);
      
      // Let's write the JSON to a file for inspection
      const fs = require('fs');
      fs.writeFileSync('scratch/next_data.json', JSON.stringify(json, null, 2));
      console.log('Wrote __NEXT_DATA__ JSON to scratch/next_data.json');
      
      // Let's print a summary of the props
      if (json.props && json.props.pageProps) {
        console.log('PageProps keys:', Object.keys(json.props.pageProps));
        const apolloState = json.props.pageProps.apolloState || json.props.pageProps.__APOLLO_STATE__;
        if (apolloState) {
          console.log('Found Apollo State in pageProps!');
          const apolloKeys = Object.keys(apolloState);
          console.log(`Apollo cache contains ${apolloKeys.length} items`);
          // Let's filter for product keys
          const productKeys = apolloKeys.filter(k => k.toLowerCase().includes('product'));
          console.log(`Found ${productKeys.length} product keys in Apollo cache.`);
        }
      }
    } catch (e) {
      console.error('Error parsing JSON:', e);
    }
  } else {
    console.log('__NEXT_DATA__ script tag not found.');
    // Let's check for any script tag containing products or apollo
    const scriptIndex = res.body.indexOf('window.__APOLLO_STATE__');
    if (scriptIndex !== -1) {
      console.log('Found window.__APOLLO_STATE__ in script!');
    }
  }

  // Let's see if we can find any other script tags or API keys
  const fs = require('fs');
  fs.writeFileSync('scratch/aeon_search_page.html', res.body);
  console.log('Saved raw HTML to scratch/aeon_search_page.html');
}

run();

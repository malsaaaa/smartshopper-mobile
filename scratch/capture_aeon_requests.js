const puppeteer = require('puppeteer');

async function run() {
  console.log('Launching browser...');
  const browser = await puppeteer.launch({
    headless: true,
    args: ['--no-sandbox', '--disable-setuid-sandbox']
  });

  const page = await browser.newPage();
  
  // Set user agent to look like a real browser
  await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

  // Enable request interception or just listen to request event
  console.log('Setting up request listeners...');
  page.on('request', request => {
    const url = request.url();
    // Filter for interesting API calls
    if (url.includes('api') || url.includes('graphql') || url.includes('ples') || url.includes('search') || url.includes('products')) {
      // Avoid printing static assets
      if (!url.endsWith('.js') && !url.endsWith('.css') && !url.endsWith('.png') && !url.endsWith('.jpg') && !url.endsWith('.svg') && !url.endsWith('.webp')) {
        console.log(`\n[REQUEST] ${request.method()} ${url}`);
        const headers = request.headers();
        console.log('Headers:', JSON.stringify({
          'accept': headers['accept'],
          'content-type': headers['content-type'],
          'x-csrf-token': headers['x-csrf-token'],
          'api-json': headers['api-json'],
          'isfromspa': headers['isfromspa']
        }, null, 2));
        
        const postData = request.postData();
        if (postData) {
          console.log('Post Data:', postData);
        }
      }
    }
  });

  page.on('response', async response => {
    const url = response.url();
    if (url.includes('api') || url.includes('graphql') || url.includes('ples') || url.includes('search')) {
      if (!url.endsWith('.js') && !url.endsWith('.css') && !url.endsWith('.png') && !url.endsWith('.jpg') && !url.endsWith('.svg') && !url.endsWith('.webp')) {
        console.log(`[RESPONSE] Status: ${response.status()} for ${url}`);
        try {
          // Only print a small snippet of the response body
          const text = await response.text();
          console.log(`Response Snippet: ${text.substring(0, 200)}`);
        } catch (e) {
          console.log(`Could not read response text: ${e.message}`);
        }
      }
    }
  });

  try {
    console.log('Navigating to myAEON2go search page...');
    // We navigate and wait for network idle to ensure all API calls are captured
    await page.goto('https://myaeon2go.com/products/search/cooking%20oil', {
      waitUntil: 'networkidle2',
      timeout: 60000
    });
    
    console.log('Page loaded. Waiting 5 seconds...');
    await new Promise(r => setTimeout(r, 5000));
    
    // Take a screenshot to verify it loaded
    console.log('Taking screenshot...');
    await page.screenshot({ path: 'scratch/aeon_screenshot.png' });
    console.log('Screenshot saved to scratch/aeon_screenshot.png');
  } catch (e) {
    console.error('Error during navigation:', e);
  } finally {
    console.log('Closing browser...');
    await browser.close();
  }
}

run();

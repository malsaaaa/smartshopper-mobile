/**
 * Lotus Scraper Test
 *
 * Strategy: Lotus is a React SPA. We use Puppeteer to:
 *   1. Navigate to the search page
 *   2. Intercept XHR/fetch network requests to find the underlying API
 *   3. Extract products from the intercepted JSON response
 *   4. If no API is found, fall back to DOM extraction
 */
const puppeteer = require('puppeteer');

const SEARCH_TERMS = ['cooking oil', 'milo'];
const BASE_URL = 'https://www.lotuss.com.my/en';

async function sleep(ms) {
  return new Promise(r => setTimeout(r, ms));
}

async function scrapeLotus(searchTerm) {
  console.log(`\n${'='.repeat(60)}`);
  console.log(`Scraping: "${searchTerm}"`);
  console.log('='.repeat(60));

  const browser = await puppeteer.launch({
    headless: true,
    args: [
      '--no-sandbox',
      '--disable-setuid-sandbox',
      '--disable-dev-shm-usage',
      '--disable-blink-features=AutomationControlled',
    ],
  });

  const page = await browser.newPage();

  // Set a realistic user agent
  await page.setUserAgent(
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 ' +
    '(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
  );

  // Storage for intercepted API requests
  const interceptedRequests = [];

  // Intercept all network requests
  page.on('response', async (response) => {
    const url = response.url();
    const contentType = response.headers()['content-type'] || '';
    
    // Only look at JSON XHR/fetch responses
    if (contentType.includes('application/json') && !url.includes('analytics') && !url.includes('tracking')) {
      try {
        const text = await response.text();
        if (text && text.length > 100) {
          interceptedRequests.push({
            url,
            status: response.status(),
            contentType,
            body: text.length > 3000 ? text.substring(0, 3000) + '...(truncated)' : text
          });
        }
      } catch (e) {
        // Ignore read errors
      }
    }
  });

  const searchUrl = `${BASE_URL}/search/${encodeURIComponent(searchTerm)}?sort=relevance:DESC`;
  console.log(`\nNavigating to: ${searchUrl}`);

  try {
    await page.goto(searchUrl, {
      waitUntil: 'networkidle2',
      timeout: 30000,
    });
  } catch (e) {
    console.log(`Navigation timeout, continuing anyway: ${e.message}`);
  }

  // Scroll to trigger lazy loading
  await sleep(2000);
  await page.evaluate(() => window.scrollBy(0, 600));
  await sleep(1500);
  await page.evaluate(() => window.scrollBy(0, 600));
  await sleep(1500);

  console.log(`\nIntercepted ${interceptedRequests.length} JSON API responses:`);
  
  // Filter to most relevant ones
  const relevant = interceptedRequests.filter(r => {
    const url = r.url.toLowerCase();
    return (
      url.includes('search') ||
      url.includes('product') ||
      url.includes('catalog') ||
      url.includes('item') ||
      url.includes('query')
    );
  });

  if (relevant.length > 0) {
    console.log(`\nFound ${relevant.length} relevant API calls:`);
    relevant.forEach((req, i) => {
      console.log(`\n--- Request #${i + 1} ---`);
      console.log(`URL: ${req.url}`);
      console.log(`Status: ${req.status}`);
      console.log(`Body preview: ${req.body.substring(0, 800)}`);
    });
  } else {
    console.log('\nNo relevant JSON API calls found. Trying DOM extraction...');
  }

  // ── DOM extraction fallback ──────────────────────────────────────────────────
  console.log('\n--- DOM Extraction ---');

  const products = await page.evaluate(() => {
    const results = [];
    
    // Strategy 1: Use product-card anchor IDs (confirmed by browser subagent)
    const cardAnchors = document.querySelectorAll('a[id^="product-card-"]');
    console.log(`Found ${cardAnchors.length} product-card anchors`);
    
    cardAnchors.forEach(anchor => {
      const container = anchor.closest('li') || anchor.parentElement;
      
      // Title: sibling anchor with id="product-title"
      const titleEl = container ? container.querySelector('a[id="product-title"]') : null;
      const name = (titleEl ? titleEl.textContent : anchor.getAttribute('aria-label') || '').trim();
      
      // Image
      const img = anchor.querySelector('img');
      const imageUrl = img ? (img.src || img.getAttribute('data-src') || '') : '';
      
      // Link
      const href = anchor.href || anchor.getAttribute('href') || '';
      const productUrl = href.startsWith('http') ? href : 'https://www.lotuss.com.my' + href;
      
      // Price: look for RM pattern in container text
      const containerText = container ? container.textContent : '';
      const priceMatch = containerText.match(/RM\s*([\d,.]+)/);
      const price = priceMatch ? parseFloat(priceMatch[1].replace(',', '')) : 0;

      if (name) {
        results.push({ name, price, imageUrl, productUrl });
      }
    });

    // Strategy 2: If no product-card anchors, try generic product selectors
    if (results.length === 0) {
      // Try h3/h4 product names
      document.querySelectorAll('h3, h4').forEach(el => {
        const text = el.textContent.trim();
        if (text.length > 3 && text.length < 120) {
          const container = el.closest('article') || el.closest('li') || el.parentElement?.parentElement;
          const priceEl = container ? container.querySelector('[class*="price"], [class*="Price"]') : null;
          const priceText = priceEl ? priceEl.textContent : '';
          const priceMatch = priceText.match(/RM\s*([\d,.]+)/);
          const img = container ? container.querySelector('img') : null;
          const link = container ? container.querySelector('a') : null;
          results.push({
            name: text,
            price: priceMatch ? parseFloat(priceMatch[1].replace(',', '')) : 0,
            imageUrl: img ? img.src : '',
            productUrl: link ? link.href : '',
          });
        }
      });
    }

    return results;
  });

  if (products.length > 0) {
    console.log(`\nExtracted ${products.length} products from DOM:\n`);
    products.slice(0, 10).forEach((p, i) => {
      console.log(`  ${i + 1}. ${p.name}`);
      console.log(`     Price:    RM ${p.price.toFixed(2)}`);
      console.log(`     Image:    ${p.imageUrl.substring(0, 80)}`);
      console.log(`     Link:     ${p.productUrl.substring(0, 80)}`);
    });
    if (products.length > 10) {
      console.log(`  ... and ${products.length - 10} more`);
    }
  } else {
    console.log('No products extracted from DOM.');

    // Dump some of the page text to debug
    const pageText = await page.evaluate(() => document.body.innerText.substring(0, 2000));
    console.log('\nPage text preview:\n', pageText);
  }

  // Print all intercepted JSON APIs for analysis
  if (interceptedRequests.length > 0 && relevant.length === 0) {
    console.log('\n--- All intercepted JSON responses (for debugging) ---');
    interceptedRequests.slice(0, 5).forEach((req, i) => {
      console.log(`\n[${i + 1}] ${req.url}`);
      console.log(`Body: ${req.body.substring(0, 400)}`);
    });
  }

  await browser.close();
  return products;
}

(async () => {
  try {
    for (const term of SEARCH_TERMS) {
      await scrapeLotus(term);
    }
  } catch (e) {
    console.error('Fatal error:', e);
    process.exit(1);
  }
})();

/**
 * Test the Lotus API endpoint directly to inspect the product JSON structure.
 */
// Import native Node.js HTTPS module for making network calls
const https = require('https');

// Define Lotus's website catalog code for Malaysia hypermarket
const WEBSITE_CODE = 'malaysia_hy';
// Define the API base domain for Lotus's mobile/web backend
const API_BASE = 'api-o2o.lotuss.com.my';
// Define pagination limit (just 5 items for payload size inspection)
const LIMIT = 5; // Just 5 for inspection

// Helper function to perform HTTPS GET requests and return response body as a Promise
function request(path) {
  // Return a new Promise to handle async success/failure
  return new Promise((resolve, reject) => {
    // Send the GET request with hostname, path, and Accept header
    const req = https.get({ hostname: API_BASE, path, headers: { 'Accept': 'application/json' } }, (res) => {
      // Buffer string to collect response chunks
      let body = '';
      // Append each received chunk of data to the buffer
      res.on('data', chunk => body += chunk);
      // Resolve the Promise when the stream ends, returning status code and full body
      res.on('end', () => resolve({ status: res.statusCode, body }));
    });
    // Reject the Promise if a connection error occurs
    req.on('error', reject);
  });
}

// Main runner function to execute searches
async function run() {
  // Iterate through representative test search queries
  for (const search of ['cooking oil', 'milo']) {
    // Construct the query parameters object and convert it to a JSON string
    const q = JSON.stringify({ offset: 0, limit: LIMIT, search, sort: 'relevance:DESC', filter: {}, websiteCode: WEBSITE_CODE });
    // Construct the final request path with URL-encoded query parameters
    const path = `/lotuss-mobile-bff/product/v2/products?q=${encodeURIComponent(q)}`;

    // Log a visual divider header for the current search query
    console.log(`\n${'='.repeat(60)}\nSearch: "${search}"\n${'='.repeat(60)}`);
    // Log the target HTTP URL being requested
    console.log(`GET https://${API_BASE}${path}\n`);

    // Execute the HTTP request and await status code and body response
    const { status, body } = await request(path);
    // Print the received HTTP status code
    console.log(`Status: ${status}`);

    // Parse the JSON response body
    const json = JSON.parse(body);
    // Print the total number of search results matching the query in the database
    console.log(`Total results: ${json.meta?.total}`);
    // Print the pagination limit returned in pagination metadata
    console.log(`Returned:      ${json.meta?.limit}\n`);

    // Retrieve the products array or default to an empty list
    const products = json.data?.products || [];
    // Log the length of the returned products array
    console.log(`Products array length: ${products.length}`);
    // Print detailed inspection only if there are products
    if (products.length > 0) {
      // Print header for first product raw JSON
      console.log('\n--- First product raw JSON (all fields) ---');
      // Log the raw fields of the first product formatted with 2-space indentation
      console.log(JSON.stringify(products[0], null, 2));

      // Print header for product list overview
      console.log('\n--- All products (name + price + url) ---');
      // Loop through products to extract and print relevant fields
      products.forEach((p, i) => {
        // Try different naming properties to extract product name safely
        const name = p.name || p.productName || p.title || '(no name)';
        // Fall back across different nested price formats used by Lotus's API
        const price = p.price?.regularPrice?.amount?.value
          || p.priceRange?.minimumPrice?.regularPrice?.value
          || p.price_range?.minimum_price?.regular_price?.value
          || p.finalPrice || p.price || 0;
        // Extract product SKU ID
        const sku = p.sku || '';
        // Extract the slug/url key used for web routing
        const urlKey = p.urlKey || p.url_key || '';
        // Extract image URL from different possible size fields
        const imageUrl = p.smallImage?.url || p.image?.url || p.thumbnail?.url || '';
        // Construct the full user-facing product web link
        const productUrl = urlKey ? `https://www.lotuss.com.my/en/product/${urlKey}` : '';
        // Print product index and name
        console.log(`  ${i + 1}. ${name}`);
        // Print product SKU
        console.log(`     SKU:   ${sku}`);
        // Print resolved product price
        console.log(`     Price: RM ${price}`);
        // Print web URL of product
        console.log(`     URL:   ${productUrl}`);
        // Print truncated image URL to prevent log overflow
        console.log(`     Image: ${imageUrl.substring(0, 80)}`);
      });
    }
  }
}

// Run the main script and catch any uncaught asynchronous errors
run().catch(console.error);

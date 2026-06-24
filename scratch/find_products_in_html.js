const fs = require('fs');

function run() {
  console.log('Reading saved HTML file...');
  const html = fs.readFileSync('scratch/aeon_search_page.html', 'utf8');
  console.log(`HTML size: ${html.length} characters.`);

  // 1. Check if "Naturel Cooking Oil" or "Knife Cooking Oil" is present
  const terms = ['Naturel Cooking Oil', 'Knife Cooking Oil', 'TOPVALU Refined Palm Olein', 'cooking oil', 'RM '];
  terms.forEach(term => {
    const index = html.toLowerCase().indexOf(term.toLowerCase());
    console.log(`Term "${term}": ${index !== -1 ? 'FOUND at index ' + index : 'NOT FOUND'}`);
  });

  // 2. Let's extract script tags in the HTML
  console.log('\n--- Extracting Script Tags ---');
  let scriptCount = 0;
  let pos = 0;
  while (true) {
    const start = html.indexOf('<script', pos);
    if (start === -1) break;
    const end = html.indexOf('</script>', start);
    if (end === -1) break;
    
    scriptCount++;
    const scriptContent = html.substring(start, end + 9);
    const openingTagEnd = html.indexOf('>', start);
    const openingTag = html.substring(start, openingTagEnd + 1);
    
    // Check if the script contains interesting content
    let preview = '';
    const body = html.substring(openingTagEnd + 1, end);
    if (body.length > 0) {
      preview = body.substring(0, 100).trim().replace(/\s+/g, ' ');
    }
    
    console.log(`Script ${scriptCount}: ${openingTag} | Body length: ${body.length} | Preview: ${preview}...`);
    
    // If the body is large, check if it's JSON or has APOLLO/NEXT state
    if (body.includes('APOLLO') || body.includes('apollo') || body.includes('NEXT_DATA') || body.includes('__NEXT_')) {
      console.log(`  -> Contains APOLLO or NEXT keyword!`);
    }
    if (body.includes('productListEntities') || body.includes('salePrice')) {
      console.log(`  -> Contains product list data!`);
    }
    
    pos = end + 9;
  }

  // 3. Let's see if there is any script containing JSON that we can parse
  console.log('\n--- Searching for large JSON objects in scripts ---');
  pos = 0;
  while (true) {
    const start = html.indexOf('<script', pos);
    if (start === -1) break;
    const end = html.indexOf('</script>', start);
    if (end === -1) break;
    
    const body = html.substring(html.indexOf('>', start) + 1, end);
    if (body.length > 5000) {
      console.log(`Large script found (length ${body.length}). Check first 200 chars:`);
      console.log(body.substring(0, 200).trim());
      
      // Let's write large scripts to files for inspection
      fs.writeFileSync(`scratch/large_script_${scriptCount}.js`, body);
    }
    
    pos = end + 9;
  }
}

run();

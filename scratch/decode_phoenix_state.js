const fs = require('fs');

function run() {
  console.log('Reading HTML file...');
  const html = fs.readFileSync('scratch/aeon_search_page.html', 'utf8');

  // Find let PhoenixAppState = '...';
  const startKeyword = "let PhoenixAppState = '";
  const startIndex = html.indexOf(startKeyword);
  if (startIndex === -1) {
    console.error('let PhoenixAppState not found!');
    return;
  }

  const valueStart = startIndex + startKeyword.length;
  const valueEnd = html.indexOf("';", valueStart);
  if (valueEnd === -1) {
    console.error('End of PhoenixAppState string not found!');
    return;
  }

  const base64Str = html.substring(valueStart, valueEnd);
  console.log(`Extracted base64 string (length: ${base64Str.length})`);

  console.log('Decoding base64 string...');
  const decodedStr = Buffer.from(base64Str, 'base64').toString('utf8');
  console.log(`Decoded string length: ${decodedStr.length} characters`);

  try {
    const json = JSON.parse(decodedStr);
    console.log('Successfully parsed decoded string as JSON!');
    
    // Save to a file
    fs.writeFileSync('scratch/phoenix_state.json', JSON.stringify(json, null, 2));
    console.log('Saved state to scratch/phoenix_state.json');

    console.log('\n--- Exploring JSON Structure ---');
    console.log('Root keys:', Object.keys(json));
    
    // Let's find product lists or search results
    // We can search for the term "cooking oil" or look at some common keys
    // Let's print nested keys up to 3 levels
    for (const key of Object.keys(json)) {
      if (json[key] && typeof json[key] === 'object') {
        const subkeys = Object.keys(json[key]);
        console.log(` - ${key} keys: ${subkeys.slice(0, 10).join(', ')}${subkeys.length > 10 ? '...' : ''}`);
        
        for (const subkey of subkeys) {
          if (json[key][subkey] && typeof json[key][subkey] === 'object') {
            const subsubkeys = Object.keys(json[key][subkey]);
            if (subsubkeys.length > 0) {
              // Check if this looks like products
              if (subkey.toLowerCase().includes('product') || subkey.toLowerCase().includes('search') || subkey.toLowerCase().includes('entities')) {
                console.log(`    * ${subkey} keys: ${subsubkeys.slice(0, 5).join(', ')}`);
              }
            }
          }
        }
      }
    }
    
    // Let's find any array of products in the state!
    console.log('\n--- Searching for arrays of products in the state ---');
    function findArrays(obj, path = '') {
      if (!obj) return;
      if (Array.isArray(obj)) {
        if (obj.length > 0 && (obj[0].nameText || obj[0].name || obj[0].salePrice || obj[0].extendedName)) {
          console.log(`Found product array at path: ${path} (length: ${obj.length})`);
          console.log(`Sample element:`, JSON.stringify(obj[0]).substring(0, 200));
        }
        return;
      }
      if (typeof obj === 'object') {
        for (const key of Object.keys(obj)) {
          findArrays(obj[key], path ? `${path}.${key}` : key);
        }
      }
    }
    findArrays(json);

  } catch (e) {
    console.error('Failed to parse decoded string as JSON:', e);
  }
}

run();

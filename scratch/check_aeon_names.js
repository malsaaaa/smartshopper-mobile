const fs = require('fs');

function run() {
  console.log('Reading phoenix_state.json...');
  const state = JSON.parse(fs.readFileSync('scratch/phoenix_state.json', 'utf8'));

  const products = state.search.products;
  if (!products) {
    console.error('search.products not found!');
    return;
  }

  const keys = Object.keys(products);
  console.log(`Found ${keys.length} products.`);

  // Print all name-related fields for the first 10 products
  for (let i = 0; i < Math.min(10, keys.length); i++) {
    const key = keys[i];
    const item = products[key].variant;
    if (!item) continue;

    console.log(`\n--- Product ${i + 1} [ID: ${item._id} / GID: ${item.gid}] ---`);
    console.log(`nameText:       "${item.nameText}"`);
    console.log(`name:           "${item.name}"`);
    console.log(`extendedName:   "${item.extendedName}"`);
    console.log(`description:    "${item.description}"`);
    console.log(`shortDescription: "${item.shortDescription}"`);
    console.log(`brand:          "${item.brand}"`);
    
    // Check if there are other fields in the item object that might contain names
    const otherNameKeys = Object.keys(item).filter(k => k.toLowerCase().includes('name') || k.toLowerCase().includes('title') || k.toLowerCase().includes('brand'));
    otherNameKeys.forEach(k => {
      console.log(`${k}: ${JSON.stringify(item[k])}`);
    });
  }
}

run();

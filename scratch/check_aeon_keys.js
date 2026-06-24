const fs = require('fs');

function run() {
  const state = JSON.parse(fs.readFileSync('scratch/phoenix_state.json', 'utf8'));
  const products = state.search.products;
  const keys = Object.keys(products);
  
  // Find a product with variant and print all its keys and values
  for (const key of keys) {
    const item = products[key].variant;
    if (item) {
      console.log('Keys in product variant:', Object.keys(item));
      console.log('Full product variant object:');
      console.log(JSON.stringify(item, null, 2));
      break;
    }
  }
}

run();

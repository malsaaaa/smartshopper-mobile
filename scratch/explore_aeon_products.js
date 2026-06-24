const fs = require('fs');

function run() {
  console.log('Reading phoenix_state.json...');
  const state = JSON.parse(fs.readFileSync('scratch/phoenix_state.json', 'utf8'));

  console.log('search keys:', Object.keys(state.search));
  
  const products = state.search.products;
  if (!products) {
    console.error('search.products not found!');
    return;
  }

  const keys = Object.keys(products);
  console.log(`search.products is of type ${typeof products} and has ${keys.length} keys.`);
  console.log('Keys in products:', keys);

  // Let's inspect the first product!
  const firstKey = keys[0];
  const firstProduct = products[firstKey];
  console.log(`\n--- First Product under key "${firstKey}" ---`);
  console.log('Type of product:', typeof firstProduct);
  if (firstProduct) {
    console.log('Keys of first product:', Object.keys(firstProduct));
    console.log('Product summary:');
    console.log(` - Name: ${firstProduct.nameText || firstProduct.name || firstProduct.extendedName}`);
    console.log(` - ID/GID: ${firstProduct._id} / ${firstProduct.gid}`);
    console.log(` - SalePrice: ${firstProduct.salePrice}`);
    console.log(` - Price: ${firstProduct.price}`);
    console.log(` - Images:`, firstProduct.images);
    console.log(` - Slug: ${firstProduct.slug}`);
  }

  // Let's print all products in the list to see if they are indeed the search results!
  console.log('\n--- All products found ---');
  keys.forEach((key, index) => {
    const p = products[key];
    console.log(`${index + 1}. [${p.gid}] ${p.nameText || p.name} - RM ${p.salePrice || p.price}`);
  });
}

run();

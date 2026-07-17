const https = require('https');

function searchGoogle(address) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(address);
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${query}&key=${apiKey}`;

    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

async function run() {
  const addresses = [
    'Lotus\'s, Melaka, Malaysia',
    'Mydin, Melaka, Malaysia',
    'AEON, Melaka, Malaysia'
  ];

  for (const addr of addresses) {
    console.log(`\n--- Geocoding: "${addr}" ---`);
    try {
      const data = await searchGoogle(addr);
      console.log(`Status: ${data.status}`);
      if (data.status === 'OK' && data.results) {
        console.log(`Results: ${data.results.length}`);
        data.results.forEach((r, idx) => {
          const loc = r.geometry.location;
          console.log(`[${idx+1}] ${r.formatted_address} (${loc.lat}, ${loc.lng})`);
        });
      } else {
        console.log(data);
      }
    } catch (e) {
      console.error(e.message);
    }
  }
}

run();

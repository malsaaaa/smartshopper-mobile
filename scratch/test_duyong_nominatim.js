const https = require('https');

function searchOSM(queryText) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(queryText);
    const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=20`;
    const options = { headers: { 'User-Agent': 'SmartShopperApp/1.0' } };
    https.get(url, options, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

async function run() {
  const queries = [
    'Lotus\'s Duyong',
    'Lotus Duyong',
    'Lotus\'s Mart Duyong',
    'Tesco Duyong',
    'Duyong Melaka supermarket',
    'Mydin Jasin Bestari',
    'Mydin Jasin'
  ];

  for (const q of queries) {
    console.log(`\n--- Query: "${q}" ---`);
    try {
      const results = await searchOSM(q);
      console.log(`Results: ${results.length}`);
      results.forEach((r, idx) => {
        console.log(`[${idx+1}] ${r.display_name} (${r.lat}, ${r.lon})`);
      });
    } catch (e) {
      console.error(e.message);
    }
  }
}

run();

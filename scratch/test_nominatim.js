const https = require('https');

function search(queryText) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(queryText);
    const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=25`;
    
    const options = {
      headers: {
        'User-Agent': 'SmartShopperApp/1.0'
      }
    };

    https.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => {
        data += chunk;
      });
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    }).on('error', (err) => {
      reject(err);
    });
  });
}

async function run() {
  const queries = [
    'Mydin Malaysia',
    'AEON Malaysia',
    'Lotus\'s Malaysia',
    'Lotus Malaysia',
    'Tesco Malaysia'
  ];

  for (const q of queries) {
    console.log(`\n--- Searching for: "${q}" ---`);
    try {
      const results = await search(q);
      console.log(`Total results: ${results.length}`);
      results.slice(0, 5).forEach((r, idx) => {
        console.log(`[${idx + 1}] ${r.display_name} (${r.lat}, ${r.lon})`);
      });
    } catch (e) {
      console.error(`Error: ${e.message}`);
    }
  }
}

run();

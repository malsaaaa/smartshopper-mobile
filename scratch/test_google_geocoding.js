const https = require('https');

function searchGoogle(queryText, lat, lon) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(queryText);
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const bounds = `${lat - 0.35},${lon - 0.35}|${lat + 0.35},${lon + 0.35}`;
    const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${query}&bounds=${bounds}&key=${apiKey}`;

    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

async function run() {
  const melakaLat = 2.2365657630638127;
  const melakaLon = 102.28151321103672;

  const queries = [
    'Lotus\'s',
    'Lotus\'s Malaysia',
    'Mydin',
    'Mydin Malaysia',
    'AEON',
    'AEON Malaysia'
  ];

  for (const q of queries) {
    console.log(`\n--- Google Geocoding search: "${q}" around Melaka ---`);
    try {
      const data = await searchGoogle(q, melakaLat, melakaLon);
      console.log(`Status: ${data.status}`);
      if (data.status === 'OK' && data.results) {
        console.log(`Total results: ${data.results.length}`);
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

const https = require('https');

function searchGooglePlaces(queryText, lat, lon) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(queryText);
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const url = `https://maps.googleapis.com/maps/api/place/textsearch/json?query=${query}&location=${lat},${lon}&radius=40000&key=${apiKey}`;

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
    'Mydin',
    'AEON'
  ];

  for (const q of queries) {
    console.log(`\n--- Google Places Text Search: "${q}" around Melaka ---`);
    try {
      const data = await searchGooglePlaces(q, melakaLat, melakaLon);
      console.log(`Status: ${data.status}`);
      if (data.status === 'OK' && data.results) {
        console.log(`Total results: ${data.results.length}`);
        data.results.slice(0, 5).forEach((r, idx) => {
          const loc = r.geometry.location;
          console.log(`[${idx+1}] ${r.name} - ${r.formatted_address} (${loc.lat}, ${loc.lng})`);
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

const https = require('https');

function reverseGeocode(lat, lon) {
  return new Promise((resolve, reject) => {
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const url = `https://maps.googleapis.com/maps/api/geocode/json?latlng=${lat},${lon}&key=${apiKey}`;
    https.get(url, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', (e) => reject(e));
  });
}

async function run() {
  const points = [
    { name: 'Jasin', lat: 2.2801, lon: 102.3911 },
    { name: 'Duyong', lat: 2.2044, lon: 102.3011 }
  ];

  for (const pt of points) {
    console.log(`\n================ ${pt.name} ================`);
    const data = await reverseGeocode(pt.lat, pt.lon);
    if (data.status === 'OK' && data.results && data.results.length > 0) {
      console.log('Results count:', data.results.length);
      // Let's print the address components of the first 3 results
      data.results.slice(0, 3).forEach((r, rIdx) => {
        console.log(`\nResult [${rIdx+1}] Formatted: ${r.formatted_address}`);
        console.log(`Types: ${JSON.stringify(r.types)}`);
        r.address_components.forEach((c) => {
          console.log(`  - ${c.long_name} (${c.short_name}) : ${JSON.stringify(c.types)}`);
        });
      });
    } else {
      console.log(data);
    }
  }
}

run();

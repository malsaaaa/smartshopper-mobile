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
    console.log(`\n--- Reverse Geocoding ${pt.name} (${pt.lat}, ${pt.lon}) ---`);
    try {
      const data = await reverseGeocode(pt.lat, pt.lon);
      if (data.status === 'OK' && data.results && data.results.length > 0) {
        const first = data.results[0];
        console.log(`Formatted Address: ${first.formatted_address}`);
        const components = first.address_components;
        let found = null;
        for (const comp of components) {
          if (comp.types.includes('locality') || comp.types.includes('suburb') || comp.types.includes('neighborhood') || comp.types.includes('administrative_area_level_2')) {
            console.log(`Matching component [${comp.types.join(', ')}]: ${comp.long_name}`);
            found = comp.long_name;
          }
        }
      } else {
        console.log(data);
      }
    } catch (e) {
      console.error(e.message);
    }
  }
}

run();

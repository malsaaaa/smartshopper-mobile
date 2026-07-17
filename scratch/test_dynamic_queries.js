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

function geocodeAddress(address) {
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
  const points = [
    { name: 'Jasin Point', lat: 2.2801, lon: 102.3911, brand: 'Mydin' },
    { name: 'Duyong Point', lat: 2.2044, lon: 102.3011, brand: 'Lotus\'s' }
  ];

  for (const pt of points) {
    console.log(`\n======================================================`);
    console.log(`Processing: ${pt.name} for brand: ${pt.brand}`);
    console.log(`======================================================`);
    
    const revData = await reverseGeocode(pt.lat, pt.lon);
    if (revData.status !== 'OK' || !revData.results || revData.results.length === 0) {
      console.log('Reverse geocoding failed');
      continue;
    }

    // Extract potential local keywords
    const components = revData.results[0].address_components;
    let localKeywords = [];
    
    // Collect components in order of specificity
    const targetTypes = [
      'neighborhood',
      'sublocality_level_1',
      'sublocality',
      'locality',
      'administrative_area_level_2'
    ];

    for (const type of targetTypes) {
      for (const comp of components) {
        if (comp.types.includes(type) && !localKeywords.includes(comp.long_name)) {
          localKeywords.push(comp.long_name);
        }
      }
    }

    console.log(`Extracted local keywords: ${JSON.stringify(localKeywords)}`);

    // Try queries one by one
    let solved = false;
    for (const keyword of localKeywords) {
      const searchQuery = `${pt.brand}, ${keyword}, Malaysia`;
      console.log(`--> Trying query: "${searchQuery}"`);
      
      const geoData = await geocodeAddress(searchQuery);
      if (geoData.status === 'OK' && geoData.results && geoData.results.length > 0) {
        // Verify result is a store (lat/lng not matching the center of Malaysia 4.21, 101.97)
        const loc = geoData.results[0].geometry.location;
        const distToMY = Math.abs(loc.lat - 4.210484) + Math.abs(loc.lng - 101.975766);
        
        if (distToMY > 0.5) { // not national center
          console.log(`✅ SUCCESS! Resolved to: ${geoData.results[0].formatted_address} (${loc.lat}, ${loc.lng})`);
          solved = true;
          break;
        } else {
          console.log(`❌ Result was just the national center of Malaysia.`);
        }
      } else {
        console.log(`❌ Query failed or returned empty.`);
      }
    }
    
    if (!solved) {
      console.log(`⚠️ Failed to resolve a local branch dynamically. Fallback required.`);
    }
  }
}

run();

const https = require('https');

function searchBounded(queryText, lat, lon) {
  return new Promise((resolve, reject) => {
    const query = encodeURIComponent(queryText);
    const offset = 0.35; // approx 35-40km bounding box radius
    const left = lon - offset;
    const right = lon + offset;
    const top = lat + offset;
    const bottom = lat - offset;
    
    // viewbox=left,top,right,bottom
    const url = `https://nominatim.openstreetmap.org/search?q=${query}&format=json&limit=25&viewbox=${left},${top},${right},${bottom}&bounded=1`;
    
    const options = {
      headers: {
        'User-Agent': 'SmartShopperApp/1.0'
      }
    };

    https.get(url, options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
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
  const userLat = 2.9186; // Cyberjaya
  const userLon = 101.6639;

  const stores = ['Mydin', 'AEON', 'Lotus\'s', 'Lotus'];

  for (const store of stores) {
    console.log(`\n--- Bounded search for: "${store}" around Cyberjaya ---`);
    try {
      const results = await searchBounded(store, userLat, userLon);
      console.log(`Total results: ${results.length}`);
      results.slice(0, 5).forEach((r, idx) => {
        // Calculate distance
        const itemLat = parseFloat(r.lat);
        const itemLon = parseFloat(r.lon);
        
        // haversine
        const R = 6371;
        const dLat = (itemLat - userLat) * Math.PI / 180;
        const dLon = (itemLon - userLon) * Math.PI / 180;
        const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                  Math.cos(userLat * Math.PI / 180) * Math.cos(itemLat * Math.PI / 180) * 
                  Math.sin(dLon/2) * Math.sin(dLon/2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        const dist = R * c;

        console.log(`[${idx + 1}] ${r.display_name}\n    Coord: (${r.lat}, ${r.lon}) | Distance: ${dist.toFixed(2)}km`);
      });
    } catch (e) {
      console.error(`Error: ${e.message}`);
    }
  }
}

run();

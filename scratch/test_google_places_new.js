const https = require('https');

function searchPlacesNew(queryText, lat, lon) {
  return new Promise((resolve, reject) => {
    const apiKey = 'AIzaSyClkMxhgs8P4GFqc5VkN4ylpXoDq7Ero-g';
    const postData = JSON.stringify({
      textQuery: `${queryText} Malaysia`,
      locationBias: {
        circle: {
          center: {
            latitude: lat,
            longitude: lon
          },
          radius: 40000.0 // 40km radius
        }
      }
    });

    const options = {
      hostname: 'places.googleapis.com',
      path: '/v1/places:searchText',
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location'
      }
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (c) => data += c);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', (e) => reject(e));
    req.write(postData);
    req.end();
  });
}

async function run() {
  const melakaLat = 2.2365657630638127;
  const melakaLon = 102.28151321103672;

  const queries = ['Lotus\'s', 'Mydin', 'AEON'];

  for (const q of queries) {
    console.log(`\n--- Places API (New) search: "${q}" ---`);
    try {
      const data = await searchPlacesNew(q, melakaLat, melakaLon);
      if (data.places) {
        console.log(`Results: ${data.places.length}`);
        data.places.forEach((p, idx) => {
          console.log(`[${idx+1}] ${p.displayName.text} - ${p.formattedAddress} (${p.location.latitude}, ${p.location.longitude})`);
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

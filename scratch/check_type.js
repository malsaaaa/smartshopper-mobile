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
  const address = 'Lotus\'s Duyong Melaka';
  try {
    const data = await searchGoogle(address);
    console.log(JSON.stringify(data, null, 2));
  } catch (e) {
    console.error(e.message);
  }
}

run();

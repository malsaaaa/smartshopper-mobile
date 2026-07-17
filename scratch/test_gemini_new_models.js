const https = require('https');

function testGemini(version, model) {
  return new Promise((resolve, reject) => {
    const apiKey = 'YOUR_API_KEY';
    const postData = JSON.stringify({
      contents: [{
        parts: [{ text: "Hello! Give me a 1-sentence shopping tip." }]
      }]
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      path: `/${version}/models/${model}:generateContent?key=${apiKey}`,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
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
  const cases = [
    { version: 'v1beta', model: 'gemini-3.5-flash' },
    { version: 'v1', model: 'gemini-3.5-flash' },
    { version: 'v1beta', model: 'gemini-3.1-flash-lite' },
    { version: 'v1', model: 'gemini-3.1-flash-lite' }
  ];

  for (const c of cases) {
    console.log(`\n--- Testing ${c.version} with model ${c.model} ---`);
    try {
      const data = await testGemini(c.version, c.model);
      console.log(JSON.stringify(data, null, 2));
    } catch (e) {
      console.error(e.message);
    }
  }
}

run();

const https = require('https');

function testGemini(model) {
  return new Promise((resolve, reject) => {
    const apiKey = 'YOUR_API_KEY';
    const postData = JSON.stringify({
      contents: [{
        parts: [{ text: "Hello! Give me a 1-sentence shopping tip." }]
      }]
    });

    const options = {
      hostname: 'generativelanguage.googleapis.com',
      path: `/v1beta/models/${model}:generateContent?key=${apiKey}`,
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
  const models = ['gemini-1.5-flash', 'gemini-2.5-flash', 'gemini-2.0-flash-exp'];
  for (const model of models) {
    console.log(`\n--- Testing model: ${model} ---`);
    try {
      const data = await testGemini(model);
      console.log(JSON.stringify(data, null, 2));
    } catch (e) {
      console.error(e.message);
    }
  }
}

run();

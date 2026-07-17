const https = require('https');

function testGemini() {
  return new Promise((resolve, reject) => {
    const apiKey = 'YOUR_API_KEY';
    const model = 'gemini-2.0-flash';
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
  console.log("--- Testing Gemini API Key ---");
  try {
    const data = await testGemini();
    console.log(JSON.stringify(data, null, 2));
  } catch (e) {
    console.error(e.message);
  }
}

run();

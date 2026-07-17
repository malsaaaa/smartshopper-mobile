const https = require('https');

function testCartRecommendation() {
  return new Promise((resolve, reject) => {
    const apiKey = 'YOUR_API_KEY';
    const model = 'gemini-3.5-flash';

    const prompt = `You are a Malaysian grocery shopping assistant for the SmartShopper app.
The user has a monthly grocery budget of RM 500.

The user's shopping cart contains:
  - Knife Brand Cooking Oil 5kg ×1 → Mydin RM 32.75, Lotus's RM 34.90, AEON RM 36.00

Write a helpful 2–4 sentence basket recommendation in English. Cover:
- Which retailer gives the cheapest total basket
- How much money the user saves by choosing the best store
- A quick budget or planning tip if relevant

Be concise and friendly. Use RM for currency. Only reference the prices listed above.`;

    const postData = JSON.stringify({
      contents: [{
        parts: [{ text: prompt }]
      }],
      generationConfig: {
        maxOutputTokens: 2048,
        temperature: 0.4
      }
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
  console.log("--- Querying Gemini for Cart Recommendation with 2048 Max Tokens ---");
  try {
    const data = await testCartRecommendation();
    console.log(`Finish Reason: ${data.candidates[0].finishReason}`);
    if (data.candidates && data.candidates[0].content.parts[0].text) {
      console.log("\nResponse text:");
      console.log(data.candidates[0].content.parts[0].text);
    }
  } catch (e) {
    console.error(e.message);
  }
}

run();

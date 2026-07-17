const http = require('http');

http.get('http://ip-api.com/json', (res) => {
  let body = '';
  res.on('data', (chunk) => body += chunk);
  res.on('end', () => {
    console.log(body);
  });
}).on('error', (e) => {
  console.error(e.message);
});

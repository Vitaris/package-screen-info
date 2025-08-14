// Simple HTTP API to get/set value in value.json
// Endpoints:
//   GET  /value          -> { value: <string|number>, updated_at?: <string> }
//   POST /value {value:<any>} -> updates value.json and returns new object
//   POST /increment {delta:<number>} -> increments numeric value
//
// Run with: npm run start-api (requires Node.js installed)

const http = require('http');
const fs = require('fs');
const path = require('path');

const FILE = path.join(__dirname, 'value.json');

function load() {
  try {
    const raw = fs.readFileSync(FILE, 'utf8');
    return JSON.parse(raw);
  } catch (e) {
    return { value: null };
  }
}

function save(obj) {
  obj.updated_at = new Date().toISOString();
  fs.writeFileSync(FILE, JSON.stringify(obj, null, 2));
}

function send(res, status, obj) {
  const body = JSON.stringify(obj);
  res.writeHead(status, {
    'Content-Type': 'application/json',
    'Content-Length': Buffer.byteLength(body),
    'Access-Control-Allow-Origin': '*'
  });
  res.end(body);
}

const server = http.createServer((req, res) => {
  if (req.method === 'OPTIONS') {
    res.writeHead(200, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    return res.end();
  }

  if (req.method === 'GET' && req.url === '/value') {
    return send(res, 200, load());
  }

  if (req.method === 'POST' && (req.url === '/value' || req.url === '/increment')) {
    let data = '';
    req.on('data', chunk => data += chunk);
    req.on('end', () => {
      let payload = {};
      if (data.trim()) {
        try { payload = JSON.parse(data); } catch (e) { return send(res, 400, { error: 'invalid json' }); }
      }
      const obj = load();
      if (req.url === '/value') {
        if (!('value' in payload)) return send(res, 400, { error: 'missing value' });
        obj.value = payload.value;
      } else if (req.url === '/increment') {
        const delta = Number(payload.delta || 1);
        const current = Number(obj.value || 0);
        if (isNaN(delta) || isNaN(current)) return send(res, 400, { error: 'value not numeric' });
        obj.value = current + delta;
      }
      save(obj);
      send(res, 200, obj);
    });
    return;
  }

  send(res, 404, { error: 'not found' });
});

const PORT = process.env.PORT || 8080;
server.listen(PORT, () => {
  console.log('API server listening on port ' + PORT);
});

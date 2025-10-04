#!/usr/bin/env node

// Simple test server for LCC/BCC image endpoints
// Usage: node test-server.js

const http = require('http');

// Sample image URLs for testing
const lccImages = [
    "https://lcc.live/image/aHR0cHM6Ly9iMTAuaGRyZWxheS5jb20vY2FtZXJhLzg2MTFlMjc2LTdlZTUtNDJjMC1iOGNkLWQ5ZTE4OTBlMWNkNC9zbmFwc2hvdA==",
    "https://lcc.live/image/aHR0cHM6Ly9hbHRhc2tpYXJlYS5zMy11cy13ZXN0LTIuYW1hem9uYXdzLmNvbS9tb3VudGFpbi1jYW1zL0NvbGxpbnNfU25vd19TdGFrZS5qcGc=",
    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDQuanBlZw==",
    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTY2NDcuanBlZw==",
];

const bccImages = [
    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTQ2MDUuanBlZw==",
    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTIuanBlZw==",
    "https://lcc.live/image/aHR0cHM6Ly91ZG90dHJhZmZpYy51dGFoLmdvdi8xX2RldmljZXMvYXV4MTYyMTMuanBlZw==",
];

// Server version - increment this to test version change detection
let serverVersion = "1.0.0";

const server = http.createServer((req, res) => {
    // Set CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, HEAD, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Accept, Content-Type');
    
    // Set version header
    res.setHeader('X-Server-Version', serverVersion);
    res.setHeader('X-Version', serverVersion);
    
    // Handle OPTIONS for CORS preflight
    if (req.method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // Handle HEAD requests (for version checking)
    if (req.method === 'HEAD') {
        res.writeHead(200);
        res.end();
        return;
    }
    
    // Only allow GET requests
    if (req.method !== 'GET') {
        res.writeHead(405);
        res.end('Method Not Allowed');
        return;
    }
    
    console.log(`${new Date().toISOString()} - ${req.method} ${req.url}`);
    
    // Route handling
    if (req.url === '/' || req.url === '') {
        // LCC endpoint
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(lccImages, null, 2));
    } else if (req.url === '/bcc') {
        // BCC endpoint
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify(bccImages, null, 2));
    } else if (req.url === '/version') {
        // Endpoint to check/update version
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ version: serverVersion }));
    } else if (req.url === '/increment-version') {
        // Endpoint to simulate a version change
        const parts = serverVersion.split('.');
        parts[2] = String(parseInt(parts[2]) + 1);
        serverVersion = parts.join('.');
        console.log(`Server version updated to: ${serverVersion}`);
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ version: serverVersion, message: 'Version incremented' }));
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

const PORT = 3000;
server.listen(PORT, () => {
    console.log(`\n==============================================`);
    console.log(`Test server running on http://localhost:${PORT}`);
    console.log(`==============================================`);
    console.log(`\nEndpoints:`);
    console.log(`  GET  /          - LCC images (${lccImages.length} images)`);
    console.log(`  GET  /bcc       - BCC images (${bccImages.length} images)`);
    console.log(`  GET  /version   - Current server version`);
    console.log(`  POST /increment-version - Increment version (for testing)`);
    console.log(`\nCurrent server version: ${serverVersion}`);
    console.log(`\nTest commands:`);
    console.log(`  curl -H "Accept: application/json" localhost:3000`);
    console.log(`  curl -H "Accept: application/json" localhost:3000/bcc`);
    console.log(`  curl localhost:3000/increment-version`);
    console.log(`\n`);
});


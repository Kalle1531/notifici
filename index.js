require('dotenv').config();
const express = require('express');
const cors = require('cors');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Create scripts directory if it doesn't exist
const scriptsDir = path.join(__dirname, 'scripts');
if (!fs.existsSync(scriptsDir)) {
  fs.mkdirSync(scriptsDir, { recursive: true });
}

// Load keys (in a production app, you'd use a database)
let keys = [];
const keysPath = path.join(__dirname, 'keys.json');
try {
  if (fs.existsSync(keysPath)) {
    keys = JSON.parse(fs.readFileSync(keysPath, 'utf8'));
  }
} catch (error) {
  console.error('Error loading keys:', error);
  keys = [];
}

// API Routes
app.get('/', (req, res) => {
  res.send('Script Server is running!');
});

// Endpoint to verify keys
app.get('/api/verify', (req, res) => {
  const { key } = req.query;
  
  if (!key) {
    return res.json({ valid: false, message: 'No key provided' });
  }
  
  const validKey = keys.find(k => k.key === key && !k.used);
  
  if (validKey) {
    res.json({ valid: true, message: 'Key is valid' });
  } else {
    res.json({ valid: false, message: 'Invalid or used key' });
  }
});

// Endpoint to serve scripts
app.get('/api/scripts/:scriptId', (req, res) => {
  const { scriptId } = req.params;
  const { key } = req.query;
  
  // Verify the key (you can enhance this logic)
  if (!key) {
    return res.status(401).send('-- No key provided');
  }
  
  const scriptPath = path.join(scriptsDir, `${scriptId}.lua`);
  
  if (fs.existsSync(scriptPath)) {
    // In a real implementation, you'd check if key is valid
    // and increment usage statistics
    
    // Read and return the script
    const scriptContent = fs.readFileSync(scriptPath, 'utf8');
    
    // Send script with key integrated
    const finalScript = scriptContent.replace('%KEY%', key);
    res.type('text/plain').send(finalScript);
  } else {
    res.status(404).send('-- Script not found');
  }
});

// Endpoint to serve a generic loader
app.get('/api/scripts/loader', (req, res) => {
  const { key } = req.query;
  
  if (!key) {
    return res.status(401).send('-- No key provided');
  }
  
  const loaderPath = path.join(__dirname, 'loader.lua');
  
  if (fs.existsSync(loaderPath)) {
    const loaderContent = fs.readFileSync(loaderPath, 'utf8')
      .replace('%KEY%', key);
    res.type('text/plain').send(loaderContent);
  } else {
    res.status(404).send('-- Loader not found');
  }
});

// Start the server
app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});

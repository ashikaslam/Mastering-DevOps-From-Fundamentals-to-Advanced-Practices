const express = require('express');

const app = express();

// Read secrets from environment variables - never hardcode them!
const dbPass = process.env.DB_PASS;
const apiKey = process.env.API_KEY;

app.use(express.json());

// Health check route
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok', message: 'Server is running' });
});

// Simple data route
app.post('/api/data', (req, res) => {
  const { name } = req.body;

  if (!name) {
    return res.status(400).json({ error: 'name is required' });
  }

  res.status(201).json({ message: `Hello ${name}`, received: true });
});

// Start the server only when this file is run directly,
// so tests can import the app without opening a port.
if (require.main === module) {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => {
    console.log(`Server listening on http://localhost:${PORT}`);
  });
}

module.exports = app;
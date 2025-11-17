const express = require('express');
const path = require('path');
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.static('public'));
app.use(express.json());

// Rutas
app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.get('/api/status', (req, res) => {
    res.json({
        status: 'online',
        message: 'Application is running successfully',
        timestamp: new Date().toISOString(),
        version: '1.0.0',
        uptime: process.uptime()
    });
});

app.get('/api/info', (req, res) => {
    res.json({
        app: 'AWS Demo Application',
        environment: process.env.NODE_ENV || 'development',
        port: PORT,
        nodeVersion: process.version
    });
});

// Iniciar servidor
app.listen(PORT, () => {
    console.log(`[INFO] Server running on http://localhost:${PORT}`);
    console.log(`[INFO] Environment: ${process.env.NODE_ENV || 'development'}`);
    console.log(`[INFO] Node version: ${process.version}`);
});

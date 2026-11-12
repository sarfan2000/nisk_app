// Fix for Windows DNS ECONNREFUSED bug on Atlas SRV lookups (must be first — before any require)
// Disabled in Docker to preserve container DNS
if (process.platform === 'win32' && !process.env.IS_DOCKER) {
    try {
        require('dns').setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']);
    } catch (e) {
        // Fallback silently
    }
}

require('dotenv').config();

const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const swaggerUi = require('swagger-ui-express');
const swaggerJsDoc = require('swagger-jsdoc');
const path = require('path');

const app = express();
app.use(cors());
app.use(express.json());

// Serve uploads statically from disk or retrieve from MongoDB permanent storage
const UploadedFile = require('./models/UploadedFile');
const fs = require('fs');

app.get('/uploads/:filename', cors(), async (req, res) => {
    try {
        const filename = path.basename(req.params.filename);
        const localPath = path.join(__dirname, 'uploads', filename);

        if (fs.existsSync(localPath)) {
            return res.sendFile(localPath);
        }

        const fileDoc = await UploadedFile.findOne({ filename });
        if (fileDoc && fileDoc.data) {
            try {
                const uploadsDir = path.join(__dirname, 'uploads');
                if (!fs.existsSync(uploadsDir)) fs.mkdirSync(uploadsDir, { recursive: true });
                fs.writeFileSync(localPath, fileDoc.data);
            } catch (err) {
                console.error('Failed to cache file to disk:', err.message);
            }
            res.set('Content-Type', fileDoc.contentType || 'image/jpeg');
            res.set('Access-Control-Allow-Origin', '*');
            res.set('Cache-Control', 'public, max-age=86400');
            return res.send(fileDoc.data);
        }
    } catch (err) {
        console.error('Error fetching file from MongoDB:', err.message);
    }

    // Fallback: If file not found on disk or MongoDB, send a clean placeholder SVG with status 200 (never 404)
    const placeholderSvg = Buffer.from(
        `<svg xmlns="http://www.w3.org/2000/svg" width="300" height="300" viewBox="0 0 300 300">
            <rect width="100%" height="100%" fill="#E8F5E9"/>
            <circle cx="150" cy="140" r="60" fill="#C8E6C9"/>
            <path d="M125 140 L145 160 L180 125" stroke="#2E7D32" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" fill="none"/>
            <text x="150" y="240" font-family="sans-serif" font-size="16" font-weight="bold" fill="#2E7D32" text-anchor="middle">NISK</text>
        </svg>`
    );
    res.set('Content-Type', 'image/svg+xml');
    res.set('Access-Control-Allow-Origin', '*');
    res.status(200).send(placeholderSvg);
});

app.use('/uploads', cors(), express.static(path.join(__dirname, 'uploads'), {
    setHeaders: (res) => { res.set('Access-Control-Allow-Origin', '*'); }
}));

// Set Security HTTP headers
app.use(helmet());

// Prevent NoSQL Injection
app.use(mongoSanitize());

// Prevent XSS attacks
app.use(xss());

// Rate Limiting (Limit each IP to 200 requests per 15 minutes)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 200,
    message: 'Too many requests from this IP, please try again after 15 minutes'
});
app.use('/api/', limiter);

// Load routes
const authRoutes = require('./routes/auth');
const servicesRoutes = require('./routes/services');
const educationRoutes = require('./routes/education');
const teacherRoutes = require('./routes/teacher');
const manpowerRoutes = require('./routes/manpower');
const cleaningRoutes = require('./routes/cleaning');
const productsRoutes = require('./routes/products');
const messagingRoutes = require('./routes/messaging');
const notificationRoutes = require('./routes/notifications');
const adminRoutes = require('./routes/admin');
const operationsRoutes = require('./routes/operations');
const searchRoutes = require('./routes/search');
const paymentRoutes = require('./routes/payment');
const deliveryRoutes = require('./routes/delivery');
const suggestionsRoutes = require('./routes/suggestions');

app.use('/api/auth', authRoutes);
app.use('/api/services', servicesRoutes);
app.use('/api/education', educationRoutes);
app.use('/api/teacher', teacherRoutes);
app.use('/api/manpower', manpowerRoutes);
app.use('/api/cleaning', cleaningRoutes);
app.use('/api/products', productsRoutes);
app.use('/api/messages', messagingRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/admin', adminRoutes);
app.use('/api/operations', operationsRoutes);
app.use('/api/search', searchRoutes);
app.use('/api/payment', paymentRoutes);
app.use('/api/delivery', deliveryRoutes);
app.use('/api/suggestions', suggestionsRoutes);

// Swagger Documentation Schema
const PORT = process.env.PORT || 5001;
const swaggerOptions = {
    swaggerDefinition: {
        openapi: '3.0.0',
        info: {
            title: 'NISK Platform API',
            description: 'Core backend documentation for the NISK multi-sector platform.',
            version: '1.0.0',
        },
        servers: [
            { url: `http://localhost:${PORT}` }
        ],
    },
    apis: ['./routes/*.js'],
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

app.get('/api/health', (req, res) => {
    res.json({
        status: 'Platform API is running',
        environment: process.env.NODE_ENV || 'development',
        timestamp: new Date().toISOString()
    });
});

// App-level error handler to prevent HTML response
app.use((err, req, res, next) => {
    console.error('Unhandled Error:', err);
    res.status(500).json({ msg: 'Server error', error: err.message || err });
});

// Database connection
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app')
    .then(() => {
        console.log('MongoDB connected successfully');
        app.listen(PORT, '0.0.0.0', () => {
            console.log(`Server running on port ${PORT}`);
        });
    }).catch(err => {
        console.error('Database connection error:', err);
    });

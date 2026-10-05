require('dotenv').config();
require('dns').setServers(['8.8.8.8', '8.8.4.4']); // Fix for Windows DNS ECONNREFUSED Bug
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const mongoSanitize = require('express-mongo-sanitize');
const xss = require('xss-clean');
const swaggerUi = require('swagger-ui-express');
const swaggerJsDoc = require('swagger-jsdoc');

const app = express();
app.use(cors());
app.use(express.json());
const path = require('path');
app.use('/uploads', cors(), express.static(path.join(__dirname, 'uploads'), { setHeaders: (res) => { res.set('Access-Control-Allow-Origin', '*'); } }));

// Set Security HTTP headers
app.use(helmet());

// Prevent NoSQL Injection
app.use(mongoSanitize());

// Prevent XSS attacks
app.use(xss());

// Rate Limiting (Limit each IP to 100 requests per 15 minutes)
const limiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 mins
    max: 100,
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
app.use('/api/suggestions', require('./routes/suggestions'));

// Swagger Documentation Schema
const swaggerOptions = {
    swaggerDefinition: {
        openapi: '3.0.0',
        info: {
            title: 'NISK Platform API',
            description: 'Core backend documentation for the NISK multi-sector platform.',
            version: '1.0.0',
        },
        servers: [
            { url: 'http://localhost:5001' }
        ],
    },
    apis: ['./routes/*.js'],
};

const swaggerDocs = swaggerJsDoc(swaggerOptions);
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerDocs));

app.get('/api/health', (req, res) => {
    res.json({ status: 'Platform API is running' });
});

// App-level error handler to prevent HTML response
app.use((err, req, res, next) => {
    console.error('Unhandled Error:', err);
    res.status(500).json({ msg: 'Server error', error: err.message || err });
});

// Database connection
const PORT = process.env.PORT || 5000;
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app')
    .then(() => {
        console.log('MongoDB connected');
        app.listen(PORT, () => {
            console.log(`Server running on port ${PORT}`);
        });
    }).catch(err => {
        console.error('Database connection error:', err);
    });

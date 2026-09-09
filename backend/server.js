require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

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

app.get('/api/health', (req, res) => {
    res.json({ status: 'Platform API is running' });
});

// Database connection
const PORT = process.env.PORT || 5000;
mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app', {
    useNewUrlParser: true,
    useUnifiedTopology: true
}).then(() => {
    console.log('MongoDB connected');
    app.listen(PORT, () => {
        console.log(`Server running on port ${PORT}`);
    });
}).catch(err => {
    console.error('Database connection error:', err);
});

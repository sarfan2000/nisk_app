const request = require('supertest');
const express = require('express');
const mongoose = require('mongoose');
const authRoutes = require('../routes/auth');
require('dotenv').config();

const app = express();
app.use(express.json());
app.use('/api/auth', authRoutes);

describe('Authentication API Endpoints', () => {

    beforeAll(async () => {
        // Connect to a test database so we don't destroy real data
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app_test');
    });

    afterAll(async () => {
        await mongoose.connection.db.dropDatabase();
        await mongoose.connection.close();
    });

    it('Should register a new user successfully', async () => {
        const res = await request(app)
            .post('/api/auth/register')
            .send({
                name: 'Test Setup User',
                phone: '0710000000',
                password: 'securepassword123',
                userType: 'Customer'
            });

        expect(res.statusCode).toEqual(201);
        expect(res.body).toHaveProperty('token');
        expect(res.body.user).toHaveProperty('name', 'Test Setup User');
    });

    it('Should login the existing user successfully', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                phone: '0710000000',
                password: 'securepassword123'
            });

        expect(res.statusCode).toEqual(200);
        expect(res.body).toHaveProperty('token');
    });

    it('Should fail login with incorrect password', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                phone: '0710000000',
                password: 'wrongpassword'
            });

        expect(res.statusCode).toEqual(400);
        expect(res.body).toHaveProperty('msg', 'Invalid credentials');
    });

    it('Should fail login for non-existent phone number', async () => {
        const res = await request(app)
            .post('/api/auth/login')
            .send({
                phone: '0000000000',
                password: 'securepassword123'
            });

        expect(res.statusCode).toEqual(400);
        expect(res.body).toHaveProperty('msg', 'Invalid credentials');
    });
});

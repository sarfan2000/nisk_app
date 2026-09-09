const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Product = require('../models/Product');
const Job = require('../models/Job');

// Global Search API
router.get('/', async (req, res) => {
    try {
        const { query, category, location } = req.query;
        let searchString = query ? { $regex: query, $options: 'i' } : null;

        let results = {
            teachers: [],
            jobs: [],
            products: [],
            services: []
        };

        if (searchString) {
            // Find Teachers
            results.teachers = await User.find({
                userType: 'Teacher',
                name: searchString
            }).select('name location rating');

            // Find Jobs
            results.jobs = await Job.find({
                title: searchString,
                isActive: true
            }).select('title company location salary');

            // Find Products
            results.products = await Product.find({
                name: searchString,
                isApproved: true
            }).select('name price stock rating');
        }

        res.json(results);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

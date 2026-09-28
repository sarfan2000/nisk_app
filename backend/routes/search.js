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
            const TeacherProfile = require('../models/TeacherProfile');
            // search by subject/name in teacher profile if possible, but let's query Users first
            results.teachers = await User.find({
                $or: [{ name: searchString }, { location: searchString }, { userType: searchString }],
                'roles.role': 'Teacher'
            }).select('name location userType');

            // Find Jobs
            results.jobs = await Job.find({
                $or: [{ title: searchString }, { category: searchString }, { company: searchString }],
                isActive: true
            }).select('title company location salary category');

            // Find Products
            results.products = await Product.find({
                $or: [{ name: searchString }, { category: searchString }],
                // isApproved check removed so user can immediately search what they posted!
            }).select('name price stock category');
        }

        res.json(results);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const User = require('../models/User');
const Product = require('../models/Product');
const Job = require('../models/Job');
const TeacherProfile = require('../models/TeacherProfile');

// Global Search API
router.get('/', async (req, res) => {
    try {
        const { query } = req.query;
        let searchString = query && query.trim() ? { $regex: query.trim(), $options: 'i' } : null;

        let results = {
            teachers: [],
            jobs: [],
            products: [],
            services: []
        };

        if (searchString) {
            // Find Teachers (by name, city, district, or profile subjects)
            const matchedTeacherProfiles = await TeacherProfile.find({
                $or: [
                    { subjects: searchString },
                    { location: searchString },
                    { experience: searchString }
                ]
            }).select('user');

            const profileUserIds = matchedTeacherProfiles.map(p => p.user);

            results.teachers = await User.find({
                $and: [
                    { 'roles.role': 'Teacher' },
                    {
                        $or: [
                            { name: searchString },
                            { 'location.city': searchString },
                            { 'location.district': searchString },
                            { 'location.province': searchString },
                            { _id: { $in: profileUserIds } }
                        ]
                    }
                ]
            }).select('name location userType roles isVerified');

            // Find Jobs
            results.jobs = await Job.find({
                $or: [
                    { title: searchString },
                    { category: searchString },
                    { company: searchString },
                    { 'location.city': searchString },
                    { 'location.district': searchString }
                ],
                isActive: true
            }).select('title company location salary category jobType');

            // Find Products
            results.products = await Product.find({
                $or: [
                    { name: searchString },
                    { category: searchString },
                    { description: searchString }
                ]
            }).select('name price stock category images seller');
        }

        res.json(results);
    } catch (err) {
        console.error('Search error:', err);
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

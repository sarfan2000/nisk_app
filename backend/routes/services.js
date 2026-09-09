const express = require('express');
const router = express.Router();
const ServiceRequest = require('../models/ServiceRequest');

// Create service request
router.post('/request', async (req, res) => {
    try {
        const { customerId, serviceCategory, details, location, date, time } = req.body;

        const request = new ServiceRequest({
            customer: customerId,
            serviceCategory,
            details,
            location,
            date,
            time
        });

        await request.save();
        res.status(201).json({ msg: 'Service request submitted', request });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// Get all requests
router.get('/', async (req, res) => {
    try {
        const requests = await ServiceRequest.find().populate('customer', 'name phone').populate('provider', 'name phone');
        res.json(requests);
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

module.exports = router;

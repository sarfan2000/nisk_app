const express = require('express');
const router = express.Router();
const Job = require('../models/Job');
const WorkerProfile = require('../models/WorkerProfile');
const JobApplication = require('../models/JobApplication');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');

// 1. Post a Job (Employer)
router.post('/jobs', [upload.array('images', 1)], async (req, res) => {
    try {
        if (!req.body.title && req.body.category) {
            req.body.title = req.body.category;
        }

        let jobPicture = '';
        if (req.files && req.files.length > 0) {
            jobPicture = req.files[0].path;
        }

        const jobPayload = { ...req.body, jobPicture };
        if (jobPayload.location && typeof jobPayload.location === 'string') {
            try {
                jobPayload.location = JSON.parse(jobPayload.location);
            } catch (e) {
                console.error("Location parse error", e);
            }
        }

        const job = new Job(jobPayload);
        await job.save();
        res.status(201).json({ msg: 'Job posted successfully', job });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Review / Verify Job
router.patch('/jobs/verify/:jobId', async (req, res) => {
    try {
        const { isVerified } = req.body;
        const job = await Job.findByIdAndUpdate(
            req.params.jobId,
            { isVerified },
            { new: true }
        );
        res.json({ msg: 'Job verification status updated', job });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Search Jobs (Worker)
router.get('/jobs', async (req, res) => {
    try {
        const { category, jobType, district } = req.query;
        let query = { isActive: true, isVerified: true };

        if (category) query.category = category;
        if (jobType) query.jobType = jobType;
        if (district) query['location.city'] = new RegExp(district, 'i');

        const jobs = await Job.find(query).populate('employer', 'name phone email');
        res.json(jobs);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Apply for Job (Worker)
router.post('/apply/:jobId', [auth, upload.array('images', 1)], async (req, res) => {
    try {
        const { coverLetter, expectedSalary } = req.body;

        let cvUrl = '';
        if (req.files && req.files.length > 0) {
            cvUrl = req.files[0].path;
        }

        const application = new JobApplication({
            job: req.params.jobId,
            worker: req.user.id,
            coverLetter,
            expectedSalary,
            cvUrl
        });

        await application.save();
        res.status(201).json({ msg: 'Application submitted successfully', application });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Search Jobs (Worker) / Get Employees
router.get('/jobs/filters', async (req, res) => {
    try {
        let match = { isActive: true, isVerified: true };
        if (req.query.category) match.category = req.query.category;

        const jobs = await Job.find(match);
        const categories = new Set();
        const locations = new Set();

        jobs.forEach(j => {
            if (j.category) categories.add(j.category);
            if (j.location && j.location.city) locations.add(j.location.city);
        });

        res.json({
            categories: Array.from(categories),
            locations: Array.from(locations)
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Update Worker Profile
router.post('/worker/profile/:userId', [upload.array('images', 1)], async (req, res) => {
    try {
        let profile = await WorkerProfile.findOne({ user: req.params.userId });

        let profilePicture = req.body.profilePicture || '';
        if (req.files && req.files.length > 0) {
            profilePicture = req.files[0].path;
        }

        if (req.body.skills) req.body.skills = typeof req.body.skills === 'string' ? JSON.parse(req.body.skills) : req.body.skills;
        if (req.body.qualifications) req.body.qualifications = typeof req.body.qualifications === 'string' ? JSON.parse(req.body.qualifications) : req.body.qualifications;

        if (profilePicture) {
            req.body.profilePicture = profilePicture;
        }

        if (profile) {
            profile = await WorkerProfile.findOneAndUpdate(
                { user: req.params.userId },
                { $set: req.body },
                { new: true }
            );
        } else {
            profile = new WorkerProfile({
                user: req.params.userId,
                ...req.body
            });
            await profile.save();
        }
        res.json({ msg: 'Worker profile updated', profile });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 5. Book a Worker
const ManpowerBooking = require('../models/ManpowerBooking');

router.post('/book', auth, async (req, res) => {
    try {
        const { workerId, jobCategory, duration, rate, serviceCharge, total } = req.body;
        const subtotal = rate * duration;

        const orderId = 'MP' + Date.now() + Math.random().toString().slice(2, 6);

        const booking = new ManpowerBooking({
            orderId,
            customer: req.user.id,
            worker: workerId,
            jobCategory,
            duration,
            rate,
            subtotal,
            serviceCharge,
            total
        });

        await booking.save();
        res.status(201).json({ msg: 'Booking placed successfully', booking, paymentUrl: `/api/payment/checkout/${orderId}` });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 6. Get Customer Manpower Bookings
router.get('/my-bookings', auth, async (req, res) => {
    try {
        const bookings = await ManpowerBooking.find({ customer: req.user.id })
            .populate('worker', 'name phone')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 7. Get Worker Hired Bookings
router.get('/worker-bookings', auth, async (req, res) => {
    try {
        const bookings = await ManpowerBooking.find({ worker: req.user.id })
            .populate('customer', 'name phone')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 8. Update Manpower Booking Status (Worker Approval)
router.patch('/bookings/:bookingId/status', auth, async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await ManpowerBooking.findOneAndUpdate(
            { orderId: req.params.bookingId },
            { status },
            { new: true }
        );

        if (booking) {
            // If accepted, mark the worker as locally unavailable!
            if (status === 'Accepted') {
                await Job.updateMany({ employer: booking.worker }, { isAvailable: false });
            }
            // If rejected or completed, free them up again!
            else if (status === 'Rejected' || status === 'Completed') {
                await Job.updateMany({ employer: booking.worker }, { isAvailable: true });
            }
        }

        res.json(booking);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const Job = require('../models/Job');
const WorkerProfile = require('../models/WorkerProfile');
const JobApplication = require('../models/JobApplication');
const upload = require('../middleware/upload');
const auth = require('../middleware/auth');
const role = require('../middleware/role');

// 1. Post a Job / Worker Listing
router.post('/jobs', [auth, role(['Employer', 'Buyer', 'Worker']), upload.array('images', 1)], async (req, res) => {
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

        jobPayload.employer = req.user.id;
        const job = new Job(jobPayload);
        await job.save();
        res.status(201).json({ msg: 'Job/Listing posted successfully', job });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// Admin Review / Verify Job
router.patch('/jobs/verify/:jobId', [auth, role(['Admin', 'Super Admin'])], async (req, res) => {
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
        let query = { isActive: true }; // Temporarily relaxed isVerified so they can see all tests

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
router.post('/apply/:jobId', [auth, role(['Worker']), upload.array('images', 1)], async (req, res) => {
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
        let match = { isActive: true }; // Temporarily relaxed isVerified
        if (req.query.category) match.category = req.query.category;

        const jobs = await Job.find(match);
        const categories = new Set();
        const locations = new Set();

        jobs.forEach(j => {
            if (j.category) categories.add(j.category);
            locations.add((j.location && j.location.city) ? j.location.city : 'Unknown');
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
router.post('/worker/profile/:userId', [auth, role(['Worker']), upload.array('images', 1)], async (req, res) => {
    try {
        if (req.params.userId !== 'me' && req.params.userId !== req.user.id) {
            return res.status(403).json({ msg: 'Forbidden' });
        }
        const actualUserId = req.user.id;
        let profile = await WorkerProfile.findOne({ user: actualUserId });

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
                { user: actualUserId },
                { $set: req.body },
                { new: true }
            );
        } else {
            profile = new WorkerProfile({
                user: actualUserId,
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
const Notification = require('../models/Notification'); // Needed for notifications

router.post('/book', [auth, role(['Employer', 'Buyer'])], async (req, res) => {
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

        // Trigger Notification to the Worker
        const notify = new Notification({
            user: workerId,
            title: 'New Manpower Booking',
            message: `An employer has booked you for ${duration} units of ${jobCategory}. It is pending admin payment verification.`,
            type: 'Alert'
        });
        await notify.save();

        res.status(201).json({ msg: 'Booking placed successfully', booking, paymentUrl: `/api/payment/checkout/${orderId}` });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server error' });
    }
});

// 6. Get Customer Manpower Bookings
router.get('/my-bookings', [auth, role(['Employer', 'Buyer'])], async (req, res) => {
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
router.get('/worker-bookings', [auth, role(['Worker'])], async (req, res) => {
    try {
        const bookings = await ManpowerBooking.find({
            worker: req.user.id,
            status: { $in: ['Admin_Approved', 'Accepted', 'Completed'] }
        })
            .populate('customer', 'name phone')
            .sort({ createdAt: -1 });
        res.json(bookings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 8. Update Manpower Booking Status (Worker Approval)
router.patch('/bookings/:bookingId/status', [auth, role(['Worker'])], async (req, res) => {
    try {
        const { status } = req.body;
        const booking = await ManpowerBooking.findOneAndUpdate(
            { orderId: req.params.bookingId, worker: req.user.id },
            { status },
            { new: true }
        );

        if (booking) {
            if (status === 'Accepted') {
                await Job.updateMany({ employer: booking.worker }, { isAvailable: false });
            } else if (status === 'Rejected' || status === 'Completed') {
                await Job.updateMany({ employer: booking.worker }, { isAvailable: true });
            }

            // Notify Employer
            const notify = new Notification({
                user: booking.customer,
                title: 'Manpower Booking Update',
                message: `Your booking ${booking.orderId} was ${status} by the worker.`,
                type: 'Alert'
            });
            await notify.save();
        }

        res.json(booking);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

const express = require('express');
const router = express.Router();
const Job = require('../models/Job');
const WorkerProfile = require('../models/WorkerProfile');
const JobApplication = require('../models/JobApplication');

// 1. Post a Job (Employer)
router.post('/jobs', async (req, res) => {
    try {
        const job = new Job(req.body);
        await job.save();
        res.status(201).json({ msg: 'Job posted successfully', job });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Search Jobs (Worker)
router.get('/jobs', async (req, res) => {
    try {
        const { category, jobType, district } = req.query;
        let query = { isActive: true };

        if (category) query.category = category;
        if (jobType) query.jobType = jobType;
        if (district) query['location.district'] = district;

        const jobs = await Job.find(query).populate('employer', 'name');
        res.json(jobs);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Apply for Job (Worker)
router.post('/apply', async (req, res) => {
    try {
        const { jobId, workerId, employerId } = req.body;

        const existing = await JobApplication.findOne({ job: jobId, worker: workerId });
        if (existing) return res.status(400).json({ msg: 'Already applied' });

        const app = new JobApplication({
            job: jobId,
            worker: workerId,
            employer: employerId
        });
        await app.save();

        res.status(201).json({ msg: 'Application submitted', application: app });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 4. Update Worker Profile
router.post('/worker/profile/:userId', async (req, res) => {
    try {
        let profile = await WorkerProfile.findOne({ user: req.params.userId });

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

module.exports = router;

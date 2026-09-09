const express = require('express');
const router = express.Router();
const Attendance = require('../models/Attendance');
const WorkReport = require('../models/WorkReport');
const FinancialSetting = require('../models/FinancialSetting');

// 1. Mark Attendance (Supervisor)
router.post('/attendance', async (req, res) => {
    try {
        const attendanceList = req.body.workers.map(workerId => ({
            worker: workerId,
            supervisor: req.body.supervisorId,
            date: req.body.date,
            status: req.body.status,
            checkIn: req.body.checkIn
        }));

        await Attendance.insertMany(attendanceList);
        res.status(201).json({ msg: 'Attendance marked successfully' });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 2. Submit Daily Work Report
router.post('/work-report', async (req, res) => {
    try {
        const report = new WorkReport(req.body);
        await report.save();
        res.status(201).json({ msg: 'Work report submitted', report });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

// 3. Get / Update Break-Even Financials (Admin)
router.get('/financial-targets', async (req, res) => {
    try {
        let settings = await FinancialSetting.findOne();
        if (!settings) {
            settings = new FinancialSetting();
            await settings.save();
        }
        res.json(settings);
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

router.patch('/financial-targets', async (req, res) => {
    try {
        const settings = await FinancialSetting.findOneAndUpdate(
            {},
            { $set: req.body, lastUpdated: Date.now() },
            { new: true, upsert: true }
        );
        res.json({ msg: 'Financial targets updated', settings });
    } catch (err) {
        res.status(500).json({ msg: 'Server error' });
    }
});

module.exports = router;

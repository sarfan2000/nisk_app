const express = require('express');
const router = express.Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

/**
 * @swagger
 * /api/auth/register:
 *   post:
 *     summary: Register a new user
 *     description: Creates an account and returns JWT token
 *     responses:
 *       201:
 *         description: User registered successfully
 */
// 1. User Registration Route
router.post('/register', async (req, res) => {
    try {
        const { name, phone, email, password, userType, location } = req.body;

        let userExists = await User.findOne({ phone });
        if (userExists) {
            return res.status(400).json({ msg: 'User with this phone number already exists' });
        }

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        const newUser = new User({
            name, phone, email, password: hashedPassword, userType, location
        });

        await newUser.save();

        res.status(201).json({ msg: 'User registered successfully', user: { id: newUser._id, name: newUser.name, userType: newUser.userType } });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

/**
 * @swagger
 * /api/auth/login:
 *   post:
 *     summary: Login user
 *     description: Authenticates phone and password, returning JWT token
 *     responses:
 *       200:
 *         description: Login successful
 */
// 2. User Login Route
router.post('/login', async (req, res) => {
    try {
        const { phone, password } = req.body;

        const user = await User.findOne({ phone });
        if (!user) {
            return res.status(400).json({ msg: 'Invalid credentials' });
        }

        const isMatch = await bcrypt.compare(password, user.password);
        if (!isMatch) {
            return res.status(400).json({ msg: 'Invalid credentials' });
        }

        const payload = { user: { id: user._id, userType: user.userType } };
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '10h' });

        res.json({ token, user: { id: user._id, name: user.name, userType: user.userType } });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

module.exports = router;

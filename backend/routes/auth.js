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

        // Setup default Multi-Role Array
        let newRoles = [{ role: 'Buyer', status: 'Active' }];
        if (userType && userType !== 'Buyer') {
            newRoles.push({ role: userType, status: 'Active' });
        }

        const newUser = new User({
            name, phone, email, password: hashedPassword, roles: newRoles, location, userType
        });

        await newUser.save();

        res.status(201).json({ msg: 'User registered successfully', user: { id: newUser._id, name: newUser.name, roles: newUser.roles, userType: newUser.userType } });
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

        const payload = { user: { id: user._id, roles: user.roles, userType: user.userType } };
        const token = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: '10h' });

        res.json({ token, user: { id: user._id, name: user.name, roles: user.roles, userType: user.userType } });
    } catch (err) {
        console.error(err);
        res.status(500).json({ msg: 'Server Error' });
    }
});

// 3. Add Role Route
const auth = require('../middleware/auth');
router.post('/add-role', auth, async (req, res) => {
    try {
        const { role } = req.body;
        const user = await User.findById(req.user.id);

        if (!user) return res.status(404).json({ msg: 'User not found' });
        if (user.roles.find(r => r.role === role)) {
            return res.status(400).json({ msg: 'Role already exists' });
        }

        user.roles.push({ role, status: 'Active' });
        await user.save();

        res.json({ roles: user.roles });
    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

module.exports = router;

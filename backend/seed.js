const mongoose = require('mongoose');
const User = require('./models/User');
const Grade = require('./models/Grade');
const Subject = require('./models/Subject');
const Product = require('./models/Product');
const Job = require('./models/Job');
const bcrypt = require('bcryptjs');
require('dotenv').config();

const seedData = async () => {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app', {
            useNewUrlParser: true,
            useUnifiedTopology: true
        });
        console.log('MongoDB connected for seeding...');

        // Clear existing basic data
        await User.deleteMany();
        await Grade.deleteMany();
        await Subject.deleteMany();
        await Product.deleteMany();
        await Job.deleteMany();

        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash('password123', salt);

        // 1. Create Mock Admin
        const admin = new User({
            name: 'NISK Admin',
            phone: '0771234567',
            password: hashedPassword,
            userType: 'Admin',
            isVerified: true
        });
        await admin.save();

        // 2. Create Mock Teacher
        const teacher = new User({
            name: 'Teacher A',
            phone: '0719876543',
            password: hashedPassword,
            userType: 'Teacher',
            location: { city: 'Kinniya' },
            isVerified: true
        });
        await teacher.save();

        // 3. Create Education Data
        const grade5 = new Grade({ name: 'Grade 5', streams: [] });
        await grade5.save();

        const science = new Subject({ name: 'Science', grade: grade5._id, teachers: [teacher._id] });
        await science.save();

        const math = new Subject({ name: 'Mathematics', grade: grade5._id, teachers: [teacher._id] });
        await math.save();

        // 4. Create Mock Employer and Job
        const employer = new User({
            name: 'BuildMax LK',
            phone: '0751112223',
            password: hashedPassword,
            userType: 'Employer',
            isVerified: true
        });
        await employer.save();

        const job = new Job({
            employer: employer._id,
            title: 'Construction Supervisor',
            company: 'BuildMax LK',
            category: 'Construction',
            jobType: 'Contract',
            location: { district: 'Trincomalee', city: 'Kinniya' },
            salary: 'LKR 120,000'
        });
        await job.save();

        // 5. Create Mock Seller and Product
        const seller = new User({
            name: 'NISK Farms',
            phone: '0774445556',
            password: hashedPassword,
            userType: 'Seller',
            isVerified: true
        });
        await seller.save();

        const product = new Product({
            seller: seller._id,
            name: 'NISK Rice Flour 1KG',
            category: 'Groceries',
            price: 500,
            stock: 100,
            isApproved: true
        });
        await product.save();

        console.log('Seed data successfully populated!');
        process.exit();
    } catch (err) {
        console.error('Seeding Error:', err);
        process.exit(1);
    }
};

seedData();

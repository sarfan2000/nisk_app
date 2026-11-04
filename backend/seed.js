// Fix for Windows DNS ECONNREFUSED bug on Atlas SRV lookups (must be first)
if (process.platform === 'win32' && !process.env.IS_DOCKER) {
    try { require('dns').setServers(['8.8.8.8', '8.8.4.4', '1.1.1.1']); } catch (e) {}
}

require('dotenv').config();
const mongoose = require('mongoose');
const Grade = require('./models/Grade');
const Subject = require('./models/Subject');
const FinancialSetting = require('./models/FinancialSetting');

const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_app';

async function seedDatabase() {
    try {
        console.log('Connecting to database...');
        await mongoose.connect(MONGO_URI);
        console.log('Connected to MongoDB.');

        // 1. Seed Grades
        const gradesList = [
            { name: 'Grade 1', streams: ['General'] },
            { name: 'Grade 2', streams: ['General'] },
            { name: 'Grade 3', streams: ['General'] },
            { name: 'Grade 4', streams: ['General'] },
            { name: 'Grade 5', streams: ['Scholarship'] },
            { name: 'Grade 6', streams: ['General'] },
            { name: 'Grade 7', streams: ['General'] },
            { name: 'Grade 8', streams: ['General'] },
            { name: 'Grade 9', streams: ['General'] },
            { name: 'Grade 10', streams: ['O/L'] },
            { name: 'Grade 11', streams: ['O/L'] },
            { name: 'Grade 12', streams: ['Science', 'Commerce', 'Arts', 'Technology'] },
            { name: 'Grade 13', streams: ['Science', 'Commerce', 'Arts', 'Technology'] }
        ];

        for (const g of gradesList) {
            await Grade.findOneAndUpdate({ name: g.name }, g, { upsert: true, new: true });
        }
        console.log('Grades seeded.');

        // 2. Seed Financial Settings
        const existingSettings = await FinancialSetting.findOne();
        if (!existingSettings) {
            await new FinancialSetting({
                workerBaseSalary: 35000,
                supervisorBaseSalary: 55000,
                officeStaffSalary: 45000,
                monthlyTargetRevenue: 500000,
                incentivePercentage: 5,
                fixedOperatingCosts: 120000,
                variableCostsPerJob: 1500
            }).save();
            console.log('Default financial settings initialized.');
        }

        console.log('Database seeding completed successfully.');
        process.exit(0);
    } catch (err) {
        console.error('Seeding error:', err);
        process.exit(1);
    }
}

seedDatabase();

const mongoose = require('mongoose');
const User = require('./models/User');
require('dotenv').config();

async function migrate() {
    try {
        await mongoose.connect(process.env.MONGO_URI || 'mongodb://localhost:27017/nisk_db');

        console.log('Connected to DB. Starting migration...');
        const users = await User.find({});
        let updatedCount = 0;

        for (let user of users) {
            if (user.userType && (!user.roles || user.roles.length === 0)) {
                // Initialize default Buyer role for everyone to access consumer sectors
                let newRoles = [{ role: 'Buyer', status: 'Active' }];

                // Add their actual worker/teacher/student role if it's not buyer
                if (user.userType !== 'Buyer') {
                    // special auto conversions
                    let legacyRole = user.userType;
                    newRoles.push({ role: legacyRole, status: 'Active' });
                }

                user.roles = newRoles;
                await user.save();
                updatedCount++;
                console.log(`Migrated user ${user.phone}`);
            }
        }

        console.log(`Migration Complete. Updated ${updatedCount} users.`);
        process.exit(0);
    } catch (err) {
        console.error(err);
        process.exit(1);
    }
}

migrate();

/**
 * Quick Message Test - Creates a second user and test messages
 */

const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
require('dotenv').config();
const User = require('../models/User');
const Message = require('../models/Message');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/nisk_app';

async function setupTestMessaging() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        // Find existing user
        const user1 = await User.findOne();
        if (!user1) {
            console.log('❌ No users found in database!');
            console.log('Please register at least one user first.');
            return;
        }
        
        console.log(`📱 Found User 1: ${user1.name} (${user1.phone})\n`);
        
        // Check if we have a second user
        let user2 = await User.findOne({ _id: { $ne: user1._id } });
        
        if (!user2) {
            console.log('🔧 Creating second test user...\n');
            
            const salt = await bcrypt.genSalt(10);
            const hashedPassword = await bcrypt.hash('password123', salt);
            
            user2 = new User({
                name: 'Test Seller',
                phone: '0771234567',
                email: 'seller@test.com',
                password: hashedPassword,
                roles: [
                    { role: 'Buyer', status: 'Active' },
                    { role: 'Seller', status: 'Active' }
                ],
                userType: 'Seller',
                location: {
                    city: 'Colombo'
                }
            });
            
            await user2.save();
            console.log(`✅ Created User 2: ${user2.name} (${user2.phone})`);
            console.log(`   Password: password123\n`);
        } else {
            console.log(`📱 Found User 2: ${user2.name} (${user2.phone})\n`);
        }
        
        // Delete existing messages between these users for fresh test
        await Message.deleteMany({
            $or: [
                { sender: user1._id, receiver: user2._id },
                { sender: user2._id, receiver: user1._id }
            ]
        });
        
        console.log('🗑️  Cleared any old messages between users\n');
        console.log('📨 Creating test conversation...\n');
        
        // Create a realistic conversation
        const messages = [
            {
                sender: user2._id,
                receiver: user1._id,
                content: `Hello ${user1.name}! I saw your product listing. Is it still available?`,
                read: false,
                createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
            },
            {
                sender: user1._id,
                receiver: user2._id,
                content: `Hi! Yes, it's available. Which product are you interested in?`,
                read: true,
                createdAt: new Date(Date.now() - 1.5 * 60 * 60 * 1000) // 1.5 hours ago
            },
            {
                sender: user2._id,
                receiver: user1._id,
                content: `I'm interested in the furniture items. What's the best price you can offer?`,
                read: false,
                createdAt: new Date(Date.now() - 1 * 60 * 60 * 1000) // 1 hour ago
            },
            {
                sender: user1._id,
                receiver: user2._id,
                content: `For bulk orders, I can give you a 10% discount. How many items do you need?`,
                read: true,
                createdAt: new Date(Date.now() - 45 * 60 * 1000) // 45 min ago
            },
            {
                sender: user2._id,
                receiver: user1._id,
                content: `That sounds great! I need about 5 items. Can we arrange delivery?`,
                read: false,
                createdAt: new Date(Date.now() - 30 * 60 * 1000) // 30 min ago
            },
            {
                sender: user1._id,
                receiver: user2._id,
                content: `Sure! Free delivery within Colombo. I'll prepare the items today.`,
                read: true,
                createdAt: new Date(Date.now() - 15 * 60 * 1000) // 15 min ago
            }
        ];
        
        for (const msgData of messages) {
            const msg = new Message(msgData);
            await msg.save();
            console.log(`  ✓ ${msgData.sender.equals(user1._id) ? user1.name : user2.name}: "${msgData.content.substring(0, 50)}..."`);
        }
        
        console.log('\n✅ Successfully created test conversation with 6 messages!\n');
        console.log('═══════════════════════════════════════════════════════════════\n');
        console.log('📱 HOW TO TEST:\n');
        console.log('1. Login to mobile app as:');
        console.log(`   Phone: ${user1.phone}`);
        console.log(`   (Your existing user)\n`);
        console.log('2. Go to Messages tab');
        console.log('3. You should see conversation with "' + user2.name + '"');
        console.log('4. Tap to open and view messages');
        console.log('5. Try sending new messages\n');
        console.log('6. To test from other side, logout and login as:');
        console.log(`   Phone: ${user2.phone}`);
        console.log(`   Password: password123\n`);
        console.log('═══════════════════════════════════════════════════════════════\n');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

setupTestMessaging();

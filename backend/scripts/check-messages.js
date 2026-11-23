/**
 * Check Messages - Verify messages exist in database
 */

const mongoose = require('mongoose');
require('dotenv').config();
const Message = require('../models/Message');
const User = require('../models/User');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/nisk_app';

async function checkMessages() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        const messages = await Message.find()
            .populate('sender', 'name phone')
            .populate('receiver', 'name phone')
            .sort({ createdAt: -1 })
            .limit(20);
        
        if (messages.length === 0) {
            console.log('❌ No messages found in database!\n');
            console.log('Run: node scripts/quick-message-test.js\n');
            return;
        }
        
        console.log(`📨 Found ${messages.length} messages:\n`);
        console.log('═'.repeat(80));
        
        messages.forEach((msg, index) => {
            const time = new Date(msg.createdAt).toLocaleString();
            console.log(`\n${index + 1}. FROM: ${msg.sender.name} (${msg.sender.phone})`);
            console.log(`   TO: ${msg.receiver.name} (${msg.receiver.phone})`);
            console.log(`   MESSAGE: "${msg.content}"`);
            console.log(`   TIME: ${time}`);
            console.log(`   READ: ${msg.read ? 'Yes' : 'No'}`);
        });
        
        console.log('\n' + '═'.repeat(80));
        console.log(`\n✅ Total messages: ${messages.length}\n`);
        
        // Show unique users
        const users = await User.find();
        console.log('👥 Users in database:');
        users.forEach(u => {
            console.log(`   • ${u.name} - ${u.phone}`);
        });
        console.log();
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

checkMessages();

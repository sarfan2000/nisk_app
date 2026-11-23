/**
 * Test Messaging Script
 * 
 * This script helps you test the messaging system by:
 * 1. Creating sample messages between users
 * 2. Listing existing users to help you send test messages
 * 
 * Usage:
 *   node scripts/test-messaging.js list-users
 *   node scripts/test-messaging.js send-test-message <senderId> <receiverId> <message>
 */

const mongoose = require('mongoose');
require('dotenv').config();
const User = require('../models/User');
const Message = require('../models/Message');

const MONGO_URI = process.env.MONGODB_URI || 'mongodb://localhost:27017/nisk_app';

async function listUsers() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        const users = await User.find({}, 'name phone email roles').limit(20);
        
        console.log('📋 Available Users (for testing):');
        console.log('=' .repeat(80));
        
        users.forEach(user => {
            const roleNames = user.roles.map(r => r.role).join(', ');
            console.log(`\n👤 ${user.name}`);
            console.log(`   ID: ${user._id}`);
            console.log(`   Phone: ${user.phone}`);
            console.log(`   Email: ${user.email || 'N/A'}`);
            console.log(`   Roles: ${roleNames}`);
        });
        
        console.log('\n' + '='.repeat(80));
        console.log(`\n✅ Found ${users.length} users\n`);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

async function sendTestMessage(senderId, receiverId, messageContent) {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        // Verify sender exists
        const sender = await User.findById(senderId);
        if (!sender) {
            console.log('❌ Sender not found!');
            return;
        }
        
        // Verify receiver exists
        const receiver = await User.findById(receiverId);
        if (!receiver) {
            console.log('❌ Receiver not found!');
            return;
        }
        
        // Create message
        const message = new Message({
            sender: senderId,
            receiver: receiverId,
            content: messageContent,
            read: false
        });
        
        await message.save();
        
        console.log('✅ Message sent successfully!\n');
        console.log('From:', sender.name);
        console.log('To:', receiver.name);
        console.log('Message:', messageContent);
        console.log('\nMessage ID:', message._id);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

async function createConversation(user1Id, user2Id) {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        const user1 = await User.findById(user1Id);
        const user2 = await User.findById(user2Id);
        
        if (!user1 || !user2) {
            console.log('❌ One or both users not found!');
            return;
        }
        
        console.log(`📨 Creating conversation between ${user1.name} and ${user2.name}...\n`);
        
        // Create messages back and forth
        const messages = [
            {
                sender: user1Id,
                receiver: user2Id,
                content: `Hello ${user2.name}! I'm interested in your services.`,
                read: false
            },
            {
                sender: user2Id,
                receiver: user1Id,
                content: `Hi ${user1.name}! Thanks for reaching out. How can I help you?`,
                read: false
            },
            {
                sender: user1Id,
                receiver: user2Id,
                content: 'I would like to know more about your pricing and availability.',
                read: false
            },
            {
                sender: user2Id,
                receiver: user1Id,
                content: 'Sure! I can help you with that. When would be a good time to discuss?',
                read: true
            }
        ];
        
        for (const msgData of messages) {
            const msg = new Message(msgData);
            await msg.save();
            // Small delay to ensure different timestamps
            await new Promise(resolve => setTimeout(resolve, 100));
        }
        
        console.log('✅ Successfully created test conversation with 4 messages!');
        console.log(`\nYou can now:\n`);
        console.log(`1. Login as ${user1.name} (${user1.phone}) to see conversation`);
        console.log(`2. Login as ${user2.name} (${user2.phone}) to see conversation`);
        console.log('\nBoth users should see the conversation in their Messages tab.\n');
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

async function deleteAllMessages() {
    try {
        await mongoose.connect(MONGO_URI);
        console.log('✅ Connected to MongoDB\n');
        
        const result = await Message.deleteMany({});
        console.log(`🗑️  Deleted ${result.deletedCount} messages\n`);
        
    } catch (error) {
        console.error('❌ Error:', error.message);
    } finally {
        await mongoose.disconnect();
    }
}

// Main execution
const command = process.argv[2];
const arg1 = process.argv[3];
const arg2 = process.argv[4];
const arg3 = process.argv.slice(5).join(' ');

if (command === 'list-users') {
    listUsers();
} else if (command === 'send-message' && arg1 && arg2 && arg3) {
    sendTestMessage(arg1, arg2, arg3);
} else if (command === 'create-conversation' && arg1 && arg2) {
    createConversation(arg1, arg2);
} else if (command === 'delete-all') {
    console.log('⚠️  This will delete ALL messages from the database!');
    console.log('Are you sure? (This operation cannot be undone)\n');
    deleteAllMessages();
} else {
    console.log('📱 NISK Messaging Test Script\n');
    console.log('Usage:');
    console.log('  node scripts/test-messaging.js list-users');
    console.log('  node scripts/test-messaging.js send-message <senderId> <receiverId> <message>');
    console.log('  node scripts/test-messaging.js create-conversation <user1Id> <user2Id>');
    console.log('  node scripts/test-messaging.js delete-all\n');
    console.log('Examples:');
    console.log('  node scripts/test-messaging.js list-users');
    console.log('  node scripts/test-messaging.js send-message 507f1f77bcf86cd799439011 507f191e810c19729de860ea "Hello!"');
    console.log('  node scripts/test-messaging.js create-conversation 507f1f77bcf86cd799439011 507f191e810c19729de860ea\n');
}

// approve-kyc.js — Run: node scripts/approve-kyc.js <userId>
// Example: node scripts/approve-kyc.js 6ac51f0a1c1a144c87922df2

const mongoose = require('mongoose');
require('dotenv').config();

const userId = process.argv[2];

if (!userId) {
  console.log('❌ Please provide a userId');
  console.log('Usage: node scripts/approve-kyc.js <userId>');
  process.exit(1);
}

mongoose.connect(process.env.MONGO_URI).then(async () => {
  const db = mongoose.connection.db;

  const userResult = await db.collection('users').updateOne(
    { _id: new mongoose.Types.ObjectId(userId) },
    { $set: { isVerified: true } }
  );

  const kycResult = await db.collection('deliveryprofiles').updateOne(
    { user: new mongoose.Types.ObjectId(userId) },
    { $set: { kycStatus: 'Approved', approvedAt: new Date() } }
  );

  if (userResult.modifiedCount === 1) {
    console.log('✅ User isVerified = true');
  } else {
    console.log('⚠️  User not found or already verified');
  }

  if (kycResult.modifiedCount === 1) {
    console.log('✅ KYC status = Approved');
  } else {
    console.log('⚠️  Delivery profile not found or already approved');
  }

  console.log('\n🎉 Done! Rider can now accept orders.');
  process.exit(0);
}).catch(e => {
  console.error('❌ Error:', e.message);
  process.exit(1);
});


/**
 * fixPayment.js — Manually check & fix payment/status for any booking
 *
 * Usage:
 *   node fixPayment.js                     → shows all Pending bookings
 *   node fixPayment.js BK1793797376734     → fixes that specific booking
 *   node fixPayment.js all                 → fixes ALL Pending bookings
 *   node fixPayment.js admin               → shows stuck bookings (paid but not admin-approved)
 */

require('dotenv').config();
const mongoose = require('mongoose');
const Booking = require('./models/Booking');

const TARGET = process.argv[2];

async function main() {
    console.log('\n🔗 Connecting to MongoDB...');
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ Connected!\n');

    if (!TARGET) {
        // ── SHOW all pending bookings ──────────────────────────────────
        const pending = await Booking.find({
            $or: [{ paymentStatus: 'Pending' }, { status: 'Pending' }]
        }).select('bookingId paymentStatus status totalBill createdAt');

        if (pending.length === 0) {
            console.log('✅ No pending bookings found — all good!');
        } else {
            console.log(`⚠️  Found ${pending.length} pending booking(s):\n`);
            console.log('BookingID              | paymentStatus | status        | Amount');
            console.log('─────────────────────────────────────────────────────────────');
            pending.forEach(b => {
                console.log(
                    `${b.bookingId.padEnd(22)} | ${b.paymentStatus.padEnd(13)} | ${b.status.padEnd(13)} | LKR ${b.totalBill}`
                );
            });
            console.log('\n💡 To fix payment + approve one:  node fixPayment.js BK...');
            console.log('💡 To fix all payment pending:     node fixPayment.js all');
            console.log('💡 To show paid-but-not-approved:  node fixPayment.js admin');
        }

    } else if (TARGET === 'admin') {
        // ── SHOW bookings paid but waiting Admin approval ──────────────
        const stuck = await Booking.find({
            paymentStatus: 'Completed',
            status: 'Pending'
        }).select('bookingId paymentStatus status totalBill createdAt');

        if (stuck.length === 0) {
            console.log('✅ No stuck bookings — all paid bookings are admin-approved!');
        } else {
            console.log(`⚠️  ${stuck.length} booking(s) paid but NOT admin-approved yet:\n`);
            stuck.forEach(b => {
                console.log(`  ${b.bookingId} | paymentStatus: ${b.paymentStatus} | status: ${b.status} | LKR ${b.totalBill}`);
            });
            console.log('\n💡 Admin must approve these in the app, OR run:  node fixPayment.js BK...');
        }

    } else if (TARGET === 'all') {
        // ── FIX ALL pending payment bookings ───────────────────────────
        const result = await Booking.updateMany(
            { paymentStatus: 'Pending' },
            { paymentStatus: 'Completed', status: 'Admin_Approved' }
        );
        console.log(`✅ Updated ${result.modifiedCount} booking(s) → paymentStatus: Completed, status: Admin_Approved`);

    } else {
        // ── FIX ONE specific booking ───────────────────────────────────
        const booking = await Booking.findOne({ bookingId: TARGET });

        if (!booking) {
            console.log(`❌ Booking not found: ${TARGET}`);
            await mongoose.disconnect();
            return;
        }

        console.log('📋 BEFORE:');
        console.log(`   bookingId    : ${booking.bookingId}`);
        console.log(`   paymentStatus: ${booking.paymentStatus}`);
        console.log(`   status       : ${booking.status}`);
        console.log(`   totalBill    : LKR ${booking.totalBill}`);

        // Fix payment status
        if (booking.paymentStatus !== 'Completed') {
            booking.paymentStatus = 'Completed';
        }

        // Fix booking status — move forward in flow
        if (booking.status === 'Pending') {
            booking.status = 'Admin_Approved'; // Admin approved → now teacher can see it
        }

        await booking.save();

        console.log('\n✅ AFTER (Updated):');
        console.log(`   paymentStatus: ${booking.paymentStatus}`);
        console.log(`   status       : ${booking.status}`);
        console.log('\n📢 Teacher will now see this booking in their dashboard!');
    }

    await mongoose.disconnect();
    console.log('\n🔌 Disconnected. Done!\n');
}

main().catch(err => {
    console.error('❌ Error:', err.message);
    mongoose.disconnect();
    process.exit(1);
});


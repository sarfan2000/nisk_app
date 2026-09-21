const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const Booking = require('../models/Booking');
const ProductOrder = require('../models/ProductOrder');
const ManpowerBooking = require('../models/ManpowerBooking');
const Notification = require('../models/Notification');

// Pull keys dynamically from your secure .env file
const MERCHANT_ID = process.env.PAYHERE_MERCHANT_ID;
const MERCHANT_SECRET = process.env.PAYHERE_MERCHANT_SECRET;

// 1. Web Checkout auto-submit page
router.get('/checkout/:orderId', async (req, res) => {
    try {
        let order;
        let amount = 0;
        let customerName = 'Customer';
        let customerEmail = 'test@test.com';
        let customerPhone = '0770000000';

        const reqOrderId = req.params.orderId;

        if (reqOrderId.startsWith('BK')) {
            const booking = await Booking.findOne({ bookingId: reqOrderId }).populate('student');
            if (!booking) return res.status(404).send('Booking not found');
            order = booking;
            amount = booking.totalBill.toFixed(2);
            if (booking.student) {
                customerName = booking.student.name;
                customerEmail = booking.student.email || customerEmail;
                customerPhone = booking.student.phone || customerPhone;
            }
        } else if (reqOrderId.startsWith('PR')) {
            const pOrder = await ProductOrder.findOne({ orderId: reqOrderId }).populate('customer');
            if (!pOrder) return res.status(404).send('Product Order not found');
            order = pOrder;
            amount = pOrder.total.toFixed(2);
            if (pOrder.customer) {
                customerName = pOrder.customer.name;
                customerEmail = pOrder.customer.email || customerEmail;
                customerPhone = pOrder.customer.phone || customerPhone;
            }
        } else if (reqOrderId.startsWith('MP')) {
            const mBooking = await ManpowerBooking.findOne({ orderId: reqOrderId }).populate('customer');
            if (!mBooking) return res.status(404).send('Manpower Booking not found');
            order = mBooking;
            amount = mBooking.total.toFixed(2);
            if (mBooking.customer) {
                customerName = mBooking.customer.name;
                customerEmail = mBooking.customer.email || customerEmail;
                customerPhone = mBooking.customer.phone || customerPhone;
            }
        } else {
            return res.status(400).send('Invalid Order Type');
        }

        // Payhere Hash Generation
        const orderId = reqOrderId;
        const currency = 'LKR';

        const hashedSecret = crypto.createHash('md5').update(MERCHANT_SECRET).digest('hex').toUpperCase();
        const hashString = MERCHANT_ID + orderId + amount + currency + hashedSecret;
        const hash = crypto.createHash('md5').update(hashString).digest('hex').toUpperCase();

        // Dynamic base URL for Return, Cancel, and Notify
        const baseUrl = `${req.protocol}://${req.get('host')}`;

        // Serve HTML form that auto submits to Payhere Sandbox
        const html = `
        <!DOCTYPE html>
        <html>
        <head><title>Processing Payment...</title></head>
        <body>
            <h2 style="text-align:center; margin-top: 50px;">Redirecting to Secure Payment Gateway...</h2>
            <p style="text-align:center;">If you are not redirected automatically, please click the button below.</p>
            <form id="payhere-form" method="post" action="https://sandbox.payhere.lk/pay/checkout" style="text-align:center;">   
                <input type="hidden" name="merchant_id" value="${MERCHANT_ID}">    
                <input type="hidden" name="return_url" value="${baseUrl}/api/payment/success">
                <input type="hidden" name="cancel_url" value="${baseUrl}/api/payment/cancel">
                <input type="hidden" name="notify_url" value="${baseUrl}/api/payment/webhook">  
                <input type="hidden" name="order_id" value="${orderId}">
                <input type="hidden" name="items" value="Booking - ${orderId}">
                <input type="hidden" name="currency" value="${currency}">
                <input type="hidden" name="amount" value="${amount}">  
                <input type="hidden" name="first_name" value="${customerName}">
                <input type="hidden" name="last_name" value="">
                <input type="hidden" name="email" value="${customerEmail}">
                <input type="hidden" name="phone" value="${customerPhone}">
                <input type="hidden" name="address" value="Colombo">
                <input type="hidden" name="city" value="Colombo">
                <input type="hidden" name="country" value="Sri Lanka">
                <input type="hidden" name="hash" value="${hash}">
                <button type="submit" style="padding: 10px 20px; font-size: 16px; background-color: #f9a826; border: none; color: white; border-radius: 5px; cursor: pointer;">Proceed to PayHere</button>
            </form> 
            <script>
                // Auto submit the form to bypass inline onload handler
                setTimeout(function() { document.getElementById('payhere-form').submit(); }, 500);
            </script>
        </body>
        </html>
        `;

        // Override Helmet's strict CSP for this specific HTML page so the auto-submit JS runs
        res.setHeader("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; form-action 'self' https://sandbox.payhere.lk;");
        res.send(html);

    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// 2. Webhook (Payhere calls this in background)
router.post('/webhook', async (req, res) => {
    const { merchant_id, order_id, payhere_amount, payhere_currency, status_code, md5sig } = req.body;

    // Verify Hash
    const hashedSecret = crypto.createHash('md5').update(MERCHANT_SECRET).digest('hex').toUpperCase();
    const hashString = merchant_id + order_id + payhere_amount + payhere_currency + status_code + hashedSecret;
    const computedHash = crypto.createHash('md5').update(hashString).digest('hex').toUpperCase();

    if (computedHash === md5sig) {
        if (status_code === '2') { // 2 = Success
            if (order_id.startsWith('BK')) {
                const booking = await Booking.findOneAndUpdate({ bookingId: order_id }, { paymentStatus: 'Completed' }, { new: true });
                if (booking) {
                    const notify = new Notification({
                        user: booking.student,
                        title: 'Payment Successful',
                        message: `Your payment for booking ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();
                }
            } else if (order_id.startsWith('PR')) {
                const pOrder = await ProductOrder.findOneAndUpdate({ orderId: order_id }, { paymentStatus: 'Paid', orderStatus: 'Payment Confirmed' }, { new: true });
                if (pOrder) {
                    const notify = new Notification({
                        user: pOrder.customer,
                        title: 'Payment Successful',
                        message: `Your payment for Product Order ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();
                }
            } else if (order_id.startsWith('MP')) {
                const mBooking = await ManpowerBooking.findOneAndUpdate({ orderId: order_id }, { paymentStatus: 'Completed' }, { new: true });
                if (mBooking) {
                    const notify = new Notification({
                        user: mBooking.customer,
                        title: 'Payment Successful',
                        message: `Your payment for Manpower Booking ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();
                }
            }
        }
        res.status(200).send('OK');
    } else {
        res.status(400).send('Invalid Hash');
    }
});

// 3. Return Pages
router.get('/success', (req, res) => res.send('<h2>Payment Successful! You can close this tab and return to the app.</h2>'));
router.get('/cancel', (req, res) => res.send('<h2>Payment Cancelled. You can close this tab.</h2>'));

module.exports = router;

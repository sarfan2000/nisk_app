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
        // Render uses a reverse proxy, so req.protocol sees 'http'. We must force HTTPS for PayHere in production.
        const protocol = req.get('host').includes('localhost') ? 'http' : 'https';
        const baseUrl = `${protocol}://${req.get('host')}`;

        const payhereUrl = process.env.PAYHERE_IS_LIVE === 'true'
            ? 'https://www.payhere.lk/pay/checkout'
            : 'https://sandbox.payhere.lk/pay/checkout';

        // Serve HTML form that auto submits to Payhere Sandbox/Live
        const html = `
        <!DOCTYPE html>
        <html>
        <head><title>Processing Payment...</title></head>
        <body>
            <h2 style="text-align:center; margin-top: 50px;">Redirecting to Secure Payment Gateway...</h2>
            <p style="text-align:center;">If you are not redirected automatically, please click the button below.</p>
            <form id="payhere-form" method="post" action="${payhereUrl}" style="text-align:center;">   
                <input type="hidden" name="merchant_id" value="${MERCHANT_ID}">    
                <input type="hidden" name="return_url" value="${baseUrl}/api/payment/success?order_id=${orderId}">
                <input type="hidden" name="cancel_url" value="${baseUrl}/api/payment/cancel?order_id=${orderId}">
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
        res.setHeader("Content-Security-Policy", "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; form-action 'self' https://sandbox.payhere.lk https://www.payhere.lk;");
        res.send(html);

    } catch (err) {
        console.error(err);
        res.status(500).send('Server Error');
    }
});

// 2. Webhook (Payhere calls this in background with cryptographic signature)
router.post('/webhook', async (req, res) => {
    const { merchant_id, order_id, payhere_amount, payhere_currency, status_code, md5sig } = req.body;

    // Verify Hash
    const hashedSecret = crypto.createHash('md5').update(MERCHANT_SECRET).digest('hex').toUpperCase();
    const hashString = merchant_id + order_id + payhere_amount + payhere_currency + status_code + hashedSecret;
    const computedHash = crypto.createHash('md5').update(hashString).digest('hex').toUpperCase();

    if (computedHash === md5sig) {
        if (status_code === '2') { // 2 = Success
            if (order_id.startsWith('BK')) {
                const booking = await Booking.findOneAndUpdate({ bookingId: order_id, paymentStatus: { $ne: 'Completed' } }, { paymentStatus: 'Completed', status: 'Admin_Approved' }, { new: true });
                if (booking) {
                    const notify = new Notification({
                        user: booking.student,
                        title: 'Payment Successful',
                        message: `Your payment for booking ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();

                    if (booking.items && booking.items.length > 0) {
                        for (let item of booking.items) {
                            if (item.teacher) {
                                const notifyTeacher = new Notification({
                                    user: item.teacher,
                                    title: 'Student Payment Confirmed!',
                                    message: `Student paid successfully and booked your class. Subject: ${item.subject || 'Unknown'}, Grade: ${booking.grade || 'Unknown'}, Time: ${item.schedule || 'Pending'}. Please approve.`,
                                    type: 'Alert'
                                });
                                await notifyTeacher.save();
                            }
                        }
                    }
                }
            } else if (order_id.startsWith('PR')) {
                const existingOrder = await ProductOrder.findOne({ orderId: order_id });
                if (existingOrder && existingOrder.paymentStatus !== 'Paid') {
                    const pOrder = await ProductOrder.findOneAndUpdate({ orderId: order_id }, { paymentStatus: 'Paid', orderStatus: 'Payment Confirmed' }, { new: true });
                    if (pOrder) {
                        const Product = require('../models/Product');
                        // Deduct stock only when payment is confirmed!
                        await Product.findByIdAndUpdate(pOrder.product, { $inc: { stock: -pOrder.quantity } });
                        const productObj = await Product.findById(pOrder.product);
                        if (productObj) {
                            const notifySeller = new Notification({
                                user: productObj.seller,
                                title: 'New Product Sale!',
                                message: `A buyer successfully paid for ${pOrder.quantity}x '${productObj.name}'. Order: ${order_id}`,
                                type: 'Reminder'
                            });
                            await notifySeller.save();
                        }

                        const notify = new Notification({
                            user: pOrder.customer,
                            title: 'Payment Successful',
                            message: `Your payment for Product Order ${order_id} has been processed successfully.`,
                            type: 'Alert'
                        });
                        await notify.save();
                    }
                }
            } else if (order_id.startsWith('MP')) {
                const mBooking = await ManpowerBooking.findOneAndUpdate({ orderId: order_id, paymentStatus: { $ne: 'Completed' } }, { paymentStatus: 'Completed', status: 'Admin_Approved' }, { new: true });
                if (mBooking) {
                    const notify = new Notification({
                        user: mBooking.customer,
                        title: 'Payment Successful',
                        message: `Your payment for Manpower Booking ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();

                    const notifyWorker = new Notification({
                        user: mBooking.worker,
                        title: 'Employer Payment Confirmed!',
                        message: `The employer has paid securely for booking ${order_id}. You can now view and accept the job in your dashboard.`,
                        type: 'Alert'
                    });
                    await notifyWorker.save();
                }
            }
        }
        res.status(200).send('OK');
    } else {
        res.status(400).send('Invalid Hash');
    }
});

// 3. Return Pages
router.get('/success', async (req, res) => {
    let order_id = req.query.order_id;
    if (Array.isArray(order_id)) order_id = order_id[0];

    // Local dev testing ONLY: strictly gated, never allowed in production
    if (process.env.NODE_ENV === 'development' && process.env.ALLOW_DEV_PAYMENT_BYPASS === 'true') {
        if (order_id) {
            console.warn(`[DEV WARNING] Executing dev payment bypass for ${order_id}`);
            if (order_id.startsWith('BK')) {
                const booking = await Booking.findOneAndUpdate({ bookingId: order_id, paymentStatus: { $ne: 'Completed' } }, { paymentStatus: 'Completed', status: 'Admin_Approved' }, { new: true });
                if (booking) {
                    const notify = new Notification({
                        user: booking.student,
                        title: 'Payment Successful',
                        message: `Your payment for booking ${order_id} has been processed successfully.`,
                        type: 'Alert'
                    });
                    await notify.save();

                    if (booking.items && booking.items.length > 0) {
                        for (let item of booking.items) {
                            if (item.teacher) {
                                const notifyTeacher = new Notification({
                                    user: item.teacher,
                                    title: 'Student Payment Confirmed!',
                                    message: `Student paid successfully and booked your class. Subject: ${item.subject || 'Unknown'}, Grade: ${booking.grade || 'Unknown'}, Time: ${item.schedule || 'Pending'}. Please approve.`,
                                    type: 'Alert'
                                });
                                await notifyTeacher.save();
                            }
                        }
                    }
                }
            } else if (order_id.startsWith('PR')) {
                const existingOrder = await ProductOrder.findOne({ orderId: order_id });
                if (existingOrder && existingOrder.paymentStatus !== 'Paid') {
                    const pOrder = await ProductOrder.findOneAndUpdate({ orderId: order_id }, { paymentStatus: 'Paid', orderStatus: 'Payment Confirmed' }, { new: true });
                    if (pOrder) {
                        const Product = require('../models/Product');
                        await Product.findByIdAndUpdate(pOrder.product, { $inc: { stock: -pOrder.quantity } });
                    }
                }
            } else if (order_id.startsWith('MP')) {
                await ManpowerBooking.findOneAndUpdate({ orderId: order_id, paymentStatus: { $ne: 'Completed' } }, { paymentStatus: 'Completed', status: 'Admin_Approved' }, { new: true });
            }
        }
    }

    res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Payment Status</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 40px 20px; background: #f9f9f9; }
            .card { background: white; max-width: 420px; margin: 40px auto; padding: 32px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
            .icon { font-size: 48px; color: #27ae60; margin-bottom: 16px; }
            h2 { color: #1B3B6F; margin-bottom: 12px; }
            p { color: #555; line-height: 1.5; font-size: 15px; }
            .order-id { font-weight: bold; color: #333; background: #f0f3f8; padding: 6px 12px; border-radius: 6px; display: inline-block; margin: 12px 0; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="icon">âœ“</div>
            <h2>Payment Processing</h2>
            ${order_id ? `<div class="order-id">Order ID: ${order_id}</div>` : ''}
            <p>Your payment has been received and is being verified by our secure gateway.</p>
            <p>You can now safely return to the NISK application.</p>
        </div>
    </body>
    </html>
    `);
});

router.get('/cancel', async (req, res) => {
    let order_id = req.query.order_id;
    if (Array.isArray(order_id)) order_id = order_id[0];

    // If a product order was cancelled, ensure order is marked or handled
    if (order_id && order_id.startsWith('PR')) {
        await ProductOrder.findOneAndUpdate(
            { orderId: order_id, paymentStatus: 'Pending' },
            { paymentStatus: 'Failed', orderStatus: 'Cancelled' }
        ).catch(e => console.error('Cancel order update error:', e));
    }

    res.send(`
    <!DOCTYPE html>
    <html>
    <head>
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>Payment Cancelled</title>
        <style>
            body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; text-align: center; padding: 40px 20px; background: #f9f9f9; }
            .card { background: white; max-width: 420px; margin: 40px auto; padding: 32px; border-radius: 12px; box-shadow: 0 4px 12px rgba(0,0,0,0.08); }
            .icon { font-size: 48px; color: #e74c3c; margin-bottom: 16px; }
            h2 { color: #1B3B6F; margin-bottom: 12px; }
            p { color: #555; line-height: 1.5; font-size: 15px; }
        </style>
    </head>
    <body>
        <div class="card">
            <div class="icon">✕</div>
            <h2>Payment Cancelled</h2>
            <p>You cancelled the payment. The product remains in stock.</p>
            <p>You can close this window and return to the NISK application.</p>
        </div>
    </body>
    </html>
    `);
});

module.exports = router;

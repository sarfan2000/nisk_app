const axios = require('axios');
const FormData = require('form-data');
const fs = require('fs');

async function test() {
    try {
        let loginData = { phone: '1234567890', password: 'password' };
        let res;
        try {
            res = await axios.post('http://localhost:5001/api/auth/login', loginData);
        } catch (e) {
            await axios.post('http://localhost:5001/api/auth/register', { name: 'test', email: 'test@test.com', password: 'password', role: 'Seller', phone: '1234567890', userType: 'Seller' });
            res = await axios.post('http://localhost:5001/api/auth/login', loginData);
        }

        const token = res.data.token;
        console.log('Got token:', token);
        const form = new FormData();
        form.append('name', 'test prod');
        form.append('price', '100');
        fs.writeFileSync('test.jpg', 'dummy');
        form.append('images', fs.createReadStream('test.jpg'));

        let upRes = await axios.post('http://localhost:5001/api/products', form, { headers: { ...form.getHeaders(), 'x-auth-token': token } });
        console.log('Upload Result:', upRes.data);
    } catch (e) {
        console.error('Error:', e.response ? e.response.data : e.message);
    }
}
test();

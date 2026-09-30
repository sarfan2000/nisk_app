const http = require('http');

const data = JSON.stringify({
    phone: '0771234567',
    password: 'oldpassword' // we will assume they have an existing user, or hit register if they don't
});

const login = (password) => {
    return new Promise((resolve) => {
        const req = http.request(
            'http://localhost:5001/api/auth/login',
            { method: 'POST', headers: { 'Content-Type': 'application/json' } },
            (res) => {
                let body = '';
                res.on('data', chunk => body += chunk.toString());
                res.on('end', () => resolve(JSON.parse(body)));
            }
        );
        req.write(JSON.stringify({ phone: '0771234567', password }));
        req.end();
    });
};

const register = () => {
    return new Promise((resolve) => {
        const req = http.request(
            'http://localhost:5001/api/auth/register',
            { method: 'POST', headers: { 'Content-Type': 'application/json' } },
            (res) => {
                let body = '';
                res.on('data', chunk => body += chunk.toString());
                res.on('end', () => resolve(JSON.parse(body)));
            }
        );
        req.write(JSON.stringify({ name: "Testing", phone: '0771234567', email: "t@t.com", password: 'oldpassword', location: "Col", userType: "Student" }));
        req.end();
    });
};

const changePass = (token, currentPassword, newPassword) => {
    return new Promise((resolve) => {
        const req = http.request(
            'http://localhost:5001/api/auth/change-password',
            { method: 'PUT', headers: { 'Content-Type': 'application/json', 'x-auth-token': token } },
            (res) => {
                let body = '';
                res.on('data', chunk => body += chunk.toString());
                res.on('end', () => resolve({ code: res.statusCode, body: JSON.parse(body) }));
            }
        );
        req.write(JSON.stringify({ currentPassword, newPassword }));
        req.end();
    });
};

(async () => {
    await register();
    const lg1 = await login('oldpassword');
    console.log('Login old pass:', lg1.token ? "OK" : lg1);
    const token = lg1.token;
    const cp = await changePass(token, 'oldpassword', 'newpassword');
    console.log('Change pass status:', cp.code, cp.body);
    const lg2 = await login('newpassword');
    console.log('Login new pass:', lg2.token ? "OK" : lg2);
})();

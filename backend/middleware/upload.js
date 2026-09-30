const multer = require('multer');
const https = require('https');
const path = require('path');
const fs = require('fs');
require('dotenv').config();

function HybridStorage(opts) { }

HybridStorage.prototype._handleFile = function _handleFile(req, file, cb) {
    const isImage = file.mimetype.startsWith('image/');
    const imgbbKey = process.env.IMGBB_API_KEY;

    if (isImage && imgbbKey) {
        // Securely stream to ImgBB Cloud via native HTTPS
        const chunks = [];
        file.stream.on('data', chunk => chunks.push(chunk));
        file.stream.on('end', () => {
            const buffer = Buffer.concat(chunks);
            const base64Image = buffer.toString('base64');

            const postData = new URLSearchParams();
            postData.append('image', base64Image);
            const body = postData.toString();

            const params = {
                hostname: 'api.imgbb.com',
                port: 443,
                path: `/1/upload?key=${imgbbKey}`,
                method: 'POST',
                headers: {
                    'Content-Type': 'application/x-www-form-urlencoded',
                    'Content-Length': Buffer.byteLength(body)
                }
            };

            const request = https.request(params, (res) => {
                let rawData = '';
                res.on('data', chunk => rawData += chunk);
                res.on('end', () => {
                    try {
                        const parsed = JSON.parse(rawData);
                        if (parsed.success && parsed.data && parsed.data.url) {
                            cb(null, {
                                path: parsed.data.url, // Returns secure Cloud URL
                                size: buffer.length
                            });
                        } else {
                            cb(new Error("ImgBB Error"));
                        }
                    } catch (e) { cb(e); }
                });
            });
            request.on('error', cb);
            request.write(body);
            request.end();
        });
    } else {
        // Fallback to local storage for PDFs or if API key is missing
        if (!fs.existsSync('uploads')) fs.mkdirSync('uploads');
        const filename = `${Date.now()}-${file.originalname}`;
        const finalPath = path.join('uploads', filename);

        const outStream = fs.createWriteStream(finalPath);
        file.stream.pipe(outStream);
        outStream.on('error', cb);
        outStream.on('finish', () => {
            cb(null, { path: finalPath.replace(/\\/g, '/'), size: outStream.bytesWritten });
        });
    }
};

HybridStorage.prototype._removeFile = function _removeFile(req, file, cb) {
    cb(null);
};

const upload = multer({ storage: new HybridStorage() });

module.exports = upload;

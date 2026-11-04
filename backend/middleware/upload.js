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
        const chunks = [];
        let totalSize = 0;
        const MAX_IMAGE_SIZE = 10 * 1024 * 1024; // 10MB

        file.stream.on('data', chunk => {
            totalSize += chunk.length;
            if (totalSize > MAX_IMAGE_SIZE) {
                file.stream.destroy();
                return cb(new Error("File size exceeds 10MB limit"));
            }
            chunks.push(chunk);
        });

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
                                path: parsed.data.url,
                                size: buffer.length
                            });
                        } else {
                            cb(new Error("ImgBB Upload Failed"));
                        }
                    } catch (e) { cb(e); }
                });
            });
            request.on('error', cb);
            request.write(body);
            request.end();
        });
    } else {
        // Fallback to local storage for documents or if ImgBB key is not set
        const uploadDir = path.join(__dirname, '..', 'uploads');
        if (!fs.existsSync(uploadDir)) fs.mkdirSync(uploadDir, { recursive: true });

        const sanitizedName = path.basename(file.originalname).replace(/[^a-zA-Z0-9._-]/g, '_');
        const filename = `${Date.now()}-${sanitizedName}`;
        const finalPath = path.join(uploadDir, filename);

        const outStream = fs.createWriteStream(finalPath);
        file.stream.pipe(outStream);
        outStream.on('error', cb);
        outStream.on('finish', () => {
            cb(null, { path: `uploads/${filename}`, size: outStream.bytesWritten });
        });
    }
};

HybridStorage.prototype._removeFile = function _removeFile(req, file, cb) {
    cb(null);
};

const upload = multer({
    storage: new HybridStorage(),
    limits: { fileSize: 10 * 1024 * 1024 } // 10MB limit
});

module.exports = upload;

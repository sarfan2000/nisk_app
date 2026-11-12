const multer = require('multer');
const path = require('path');
const fs = require('fs');
const UploadedFile = require('../models/UploadedFile');

function MongoHybridStorage() { }

MongoHybridStorage.prototype._handleFile = function _handleFile(req, file, cb) {
    const chunks = [];
    let totalSize = 0;
    const MAX_FILE_SIZE = 15 * 1024 * 1024; // 15MB limit

    file.stream.on('data', chunk => {
        totalSize += chunk.length;
        if (totalSize > MAX_FILE_SIZE) {
            file.stream.destroy();
            return cb(new Error("File size exceeds 15MB limit"));
        }
        chunks.push(chunk);
    });

    file.stream.on('end', () => {
        try {
            const buffer = Buffer.concat(chunks);
            const uploadDir = path.join(__dirname, '..', 'uploads');
            if (!fs.existsSync(uploadDir)) {
                fs.mkdirSync(uploadDir, { recursive: true });
            }

            const sanitizedName = path.basename(file.originalname).replace(/[^a-zA-Z0-9._-]/g, '_');
            const filename = `${Date.now()}-${sanitizedName}`;
            const localFilePath = path.join(uploadDir, filename);

            // 1. Save to local disk — synchronous, fast
            try {
                fs.writeFileSync(localFilePath, buffer);
            } catch (fsErr) {
                console.warn('Local disk write warning:', fsErr.message);
            }

            // 2. Save to MongoDB Atlas ASYNC (fire-and-forget) — do NOT block the upload response
            setImmediate(() => {
                UploadedFile.findOneAndUpdate(
                    { filename },
                    {
                        filename,
                        contentType: file.mimetype || 'image/jpeg',
                        data: buffer,
                        size: buffer.length
                    },
                    { upsert: true, returnDocument: 'after' }
                ).catch(mongoErr => {
                    console.error('MongoDB file background save warning:', mongoErr.message);
                });
            });

            // 3. Return immediately — don't wait for MongoDB
            cb(null, {
                path: `uploads/${filename}`,
                filename: filename,
                size: buffer.length
            });
        } catch (err) {
            cb(err);
        }
    });

    file.stream.on('error', cb);
};

MongoHybridStorage.prototype._removeFile = function _removeFile(req, file, cb) {
    cb(null);
};

const upload = multer({
    storage: new MongoHybridStorage(),
    limits: { fileSize: 15 * 1024 * 1024 }
});

module.exports = upload;

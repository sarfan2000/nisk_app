const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;
require('dotenv').config();

// Configure Cloudinary with secure env limits
cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME || 'nisk_cloud',
    api_key: process.env.CLOUDINARY_API_KEY || 'api_key_placeholder',
    api_secret: process.env.CLOUDINARY_API_SECRET || 'api_secret_placeholder',
});

let storage;

if (process.env.CLOUDINARY_API_KEY && process.env.CLOUDINARY_API_KEY !== 'api_key_placeholder') {
    // Create dynamic storage engine for CVs and Images
    storage = new CloudinaryStorage({
        cloudinary: cloudinary,
        params: async (req, file) => {
            let folderName = 'nisk_assets';
            if (file.mimetype === 'application/pdf') {
                folderName = 'nisk_cvs';
            } else if (file.mimetype.startsWith('image/')) {
                folderName = 'nisk_product_images';
            }

            return {
                folder: folderName,
                allowed_formats: ['jpg', 'png', 'jpeg', 'pdf'],
                public_id: `${Date.now()}-${file.originalname.split('.')[0]}`
            };
        },
    });
} else {
    console.warn("Using local disk storage. Please configure CLOUDINARY_API_KEY for cloud uploads.");
    storage = multer.diskStorage({
        destination: (req, file, cb) => {
            cb(null, 'uploads/');
        },
        filename: (req, file, cb) => {
            cb(null, `${Date.now()}-${file.originalname}`);
        }
    });
}
const upload = multer({ storage: storage });

module.exports = upload;

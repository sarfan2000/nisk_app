# NISK APP ARCHITECTURE & INFRASTRUCTURE OVERVIEW

## 1. Core Framework
- **Frontend OS**: Flutter (Dart) - Single codebase rendering to iOS, Android, and Web.
- **Backend OS**: Node.js (Express Framework)
- **Database**: MongoDB (Mongoose Schema Modeler)

## 2. Security Map
- **JWT Middleware**: Blocks unauthorized `POST/GET/PATCH` requests.
- **Role-Based Check**: Rejects normal tokens if accessing `/admin` (Super Admin checks).
- **Helmet**: Shields Express HTTP headers.
- **Rate-Limiting**: 100 ping max limit per IP every 15 minutes.
- **XSS & Mongo-Sanitization**: Strips raw query variables injected via frontends.
- **Passwords**: Cryptographed inherently using `Bcrypt.js`.

## 3. Storage Layer
- **Strings/Relations**: Stored cleanly in MongoDB `users, jobs, products, cleanings, bookings`.
- **Assets (Images/CVs)**: Abstracted via `Multer` straight into `Cloudinary` servers preventing backend bottlenecking.

## 4. Operational & Analytics Module
- Heavy mapping allowed Admins to tweak variables safely:
  - `Worker Base Salaries`
  - `Company Target Overheads`
  - Allows Break-Even and Incentive math scaling directly on `operations/financial-target` schemas.

## 5. Deployment Paradigm
Docker containerization protects local configurations:
- Rebuilds safely with `docker-compose up --build -d`
- Seeds locally using `node seed.js`

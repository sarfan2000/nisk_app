# NISK App - Multi-Sector Marketplace

CONNECT • EMPOWER • GROW
One Platform. Endless Opportunities.

## Project Structure
This repository contains a full-stack implementation of the NISK Multi-Service digital marketplace platform.
The architecture is split into a scalable **Node.js/Express Backend** and a cross-platform **Flutter Mobile Frontend**.

### 1. `backend/` (Node.js REST API)
- **Framework**: Express.js
- **Database**: MongoDB (Mongoose ORM)
- **Security**: JWT Authentication, Bcrypt password hashing
- **Modules**: Authentication, Education, Manpower, Cleaning, Products, Messaging, Admin, Operations

### 2. `mobile/` (Flutter App)
- **Framework**: Flutter (Dart)
- **State/Navigation**: Pre-configured for provider / routing schemas
- **Styling**: Google Fonts (Inter), Material 3 Design
- **Modules**: Education Dashboard, Manpower Dashboard, Cleaning Hub, Production & Sales Storefront, Admin overview.
- **Multilingual Support**: English, Tamil, Sinhala configurations (`assets/locales`).

---

## 🚀 How to Run the Infrastructure

### Step 1: Start the Backend server
The backend requires MongoDB to be running locally or a valid `MONGO_URI` injected in the `.env` file.

1. Open a new Terminal (Powershell/Command Prompt)
2. Navigate to the backend folder:
   ```bash
   cd backend
   ```
3. Install dependencies:
   ```bash
   npm install
   ```
4. Seed the database with fictional testing data (Admin, Teachers, Products):
   ```bash
   node seed.js
   ```
5. Start the server:
   ```bash
   node server.js
   ```
*(The server will boot on `http://localhost:5000`)*

### Step 2: Boot the Flutter Mobile Application
Ensure you have the Flutter SDK installed on your machine and an emulator running (or a connected physical device).

1. Open a new Terminal (Powershell/Command Prompt)
2. Navigate to the mobile folder:
   ```bash
   cd mobile
   ```
3. Initialize the Flutter templates over our repository logic:
   *Because this project was strictly bootstrapped around bare dart/flutter code logic without forcing local machine dependencies at build time, run this command to cleanly setup Android/iOS targets:*
   ```bash
   flutter create .
   ```
4. Request dependencies:
   ```bash
   flutter pub get
   ```
5. Run the application:
   ```bash
   flutter run
   ```

---

*System Architected by DeepMind AI Assistant according to exact Master Development parameters for NISK MPC (Pvt) Ltd.*

# 🩸 BloodLife – Blood Bank Management System

A modern web-based Blood Bank Management System built to simplify and automate the management of donors, blood inventory, and blood requests.


## 📌 Features

- 📋 **Donor Management**
  - Register, update, and delete donor records.
  - Track donor age, blood group, contact, and donation history.

- 🏥 **Blood Inventory**
  - Visual dashboard of available blood types.
  - Critical stock alert system (threshold ≤ 20 units).
  - Auto-update via SQL triggers on donations.

- 🆘 **Blood Requests**
  - Submit blood requests with type and quantity.
  - View and manage all incoming requests.
  - Fulfillment tracking for pending and completed requests.

- 📊 **Dashboard**
  - Summary cards: total donors, units available, requests, and donations.
  - Trend charts for demand and stock distribution using Chart.js.


## 🧰 Tech Stack

### 💻 Frontend
- HTML5, CSS3, Bootstrap 5
- JavaScript (Vanilla)
- Chart.js for visualizations

### ⚙️ Backend
- Node.js with Express
- RESTful APIs

### 🗃️ Database
- Microsoft SQL Server
- Tables: `Donors`, `BloodDonation`, `BloodInventory`, `BloodRequests`
- Triggers: Auto-inventory update on donation
- View: `vw_BloodInventorySummary`


## ⚙️ Setup Instructions

### 1. Clone the Repository
clone https://github.com/ea-siddiqui/blood-donation-management-system.git

### 2. Setup SQL Server

* Create the required tables using `DAM.sql`
* Add triggers and views as defined in your implementation
* Insert some test data to verify

### 3. Configure the Backend

* Edit the `config.js` file with your SQL Server credentials

module.exports = {
  server: 'EAS-LENOVO\\SQLEXPRESS', // Your exact server name
  database: 'BloodDonationDB',
  options: {
    trustedConnection: true, // Force Windows Auth
    trustServerCertificate: true
  },
  driver: 'msnodesqlv8' // Specify the Windows Auth driver
};

### 4. Start the Server

npm install
node server.js

### 5. Open in Browser

Go to `http://localhost:3000/public/dashboard.html` to view the app.

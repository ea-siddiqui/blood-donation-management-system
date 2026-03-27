module.exports = {
  server: 'EAS-LENOVO\\SQLEXPRESS', // Your exact server name
  database: 'BloodDonationDB',
  options: {
    trustedConnection: true, // Force Windows Auth
    trustServerCertificate: true
  },
  driver: 'msnodesqlv8' // Specify the Windows Auth driver
};
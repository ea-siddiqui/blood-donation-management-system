const express = require('express');
const config = require('./config');
const cors = require('cors');
const path = require('path');
const sql = require('mssql/msnodesqlv8');

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Database Connection
sql.connect(config)
  .then(() => console.log('Connected to SQL Server'))
  .catch(err => console.error('Database connection error:', err));

// Serve static components
app.get('/components/:component', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'components', req.params.component));
});

// API Endpoints

app.get('/api/generate-report', async (req, res) => {
    // Helper function inside the endpoint
    const getSectionType = (index) => {
        const sections = [
            'totalDonors',
            'totalDonations',
            'inventory',
            'bloodRequests',
            'donorDonations',
            'fulfillmentStatus'
        ];
        return sections[index] || `section_${index}`;
    };

    try {
        const request = new sql.Request();
        const report = { sections: [] };

        const result = await request.execute('GenerateBloodDonationReport');
        
        // Use the local helper function
        report.sections = result.recordsets.map((recordset, index) => ({
            type: getSectionType(index),
            data: recordset
        }));

        res.json(report);
    } catch (err) {
        console.error('Report generation error:', err);
        res.status(500).json({ 
            error: 'Failed to generate report',
            details: err.message 
        });
    }
});

// GET: All donors with donation summary
app.get('/api/donors', async (req, res) => {
  try {
    const result = await sql.query`
      SELECT 
        d.DonorID,
        d.DonorName,
        d.BloodType,
        d.Age,
        d.ContactNumber,
        COALESCE(SUM(bd.AmountDonated), 0) AS DonatedAmount,
        MAX(bd.DonationDate) AS DateOfDonation
      FROM Donors d
      LEFT JOIN BloodDonation bd ON d.DonorID = bd.DonorID
      GROUP BY d.DonorID, d.DonorName, d.BloodType, d.Age, d.ContactNumber
    `;
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// POST: Add new donor with initial donation
app.post('/api/donors', async (req, res) => {
  const { DonorName, Age, BloodType, ContactNumber, InitialDonation } = req.body;
  const validBloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

  if (!DonorName || !Age || !BloodType || !ContactNumber) {
    return res.status(400).json({ error: "All fields are required" });
  }
  if (!validBloodTypes.includes(BloodType)) {
    return res.status(400).json({ error: "Invalid blood type" });
  }
  if (!/^03\d{2}-\d{7}$/.test(ContactNumber)) {
    return res.status(400).json({ error: "Invalid contact format (03XX-XXXXXXX)" });
  }

  const transaction = new sql.Transaction();
  try {
    await transaction.begin();

    const donorResult = await transaction.request()
      .input('DonorName', sql.VarChar, DonorName)
      .input('Age', sql.Int, Age)
      .input('BloodType', sql.Char(3), BloodType)
      .input('ContactNumber', sql.VarChar(15), ContactNumber)
      .query(`INSERT INTO Donors (DonorName, Age, BloodType, ContactNumber)
              OUTPUT inserted.DonorID
              VALUES (@DonorName, @Age, @BloodType, @ContactNumber)`);

    const donorId = donorResult.recordset[0].DonorID;

    if (InitialDonation > 0) {
      await transaction.request()
        .input('DonorID', sql.Int, donorId)
        .input('Amount', sql.Decimal(5,2), InitialDonation)
        .query(`INSERT INTO BloodDonation (DonorID, DonationDate, AmountDonated)
                VALUES (@DonorID, GETDATE(), @Amount)`);
    }

    await transaction.commit();
    res.status(201).json({ DonorID: donorId });
  } catch (err) {
    await transaction.rollback();
    res.status(500).json({ error: err.message });
  }
});

// PUT: Update donor
app.put('/api/donors/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { DonorName, BloodType, Age, ContactNumber } = req.body;
    const validBloodTypes = ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'];

    if (!validBloodTypes.includes(BloodType)) {
      return res.status(400).json({ error: "Invalid blood type" });
    }
    if (!/^03\d{2}-\d{7}$/.test(ContactNumber)) {
      return res.status(400).json({ error: "Invalid contact format" });
    }

    await sql.query`
      UPDATE Donors SET
        DonorName = ${DonorName},
        BloodType = ${BloodType},
        Age = ${Age},
        ContactNumber = ${ContactNumber}
      WHERE DonorID = ${id}
    `;
    res.sendStatus(204);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// DELETE: Remove donor
app.delete('/api/donors/:id', async (req, res) => {
  try {
    const { id } = req.params;
    await sql.query`
      DELETE FROM BloodDonation WHERE DonorID = ${id};
      DELETE FROM Donors WHERE DonorID = ${id};
    `;
    res.sendStatus(204);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Inventory (reads from view)
app.get('/api/inventory', async (req, res) => {
  try {
    const result = await sql.query`
      SELECT BloodType, Quantity
      FROM vw_BloodInventorySummary
      ORDER BY BloodType
    `;
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Blood Requests
app.get('/api/blood-requests', async (req, res) => {
  try {
    const { status } = req.query;
    let query = `
      SELECT RequestID, RequestBy, BloodType, Quantity, 
             Fulfilled, FORMAT(RequestDate, 'yyyy-MM-dd') AS RequestDate
      FROM BloodRequests`;

    if (status) {
      query += ` WHERE Fulfilled = ${status === 'fulfilled' ? 1 : 0}`;
    }

    const result = await sql.query(query);
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

app.post('/api/blood-requests', async (req, res) => {
  try {
    const { RequestBy, BloodType, Quantity } = req.body;
    await sql.query`
      INSERT INTO BloodRequests 
        (RequestBy, BloodType, Quantity, RequestDate)
      VALUES 
        (${RequestBy}, ${BloodType}, ${Quantity}, GETDATE())
    `;
    res.status(201).json({ message: 'Request created' });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Donation History
app.get('/api/donations', async (req, res) => {
  try {
    const result = await sql.query`
      SELECT d.DonationID, dn.DonorName, d.DonorID,
             FORMAT(d.DonationDate, 'yyyy-MM-dd') AS DonationDate,
             d.AmountDonated, dn.BloodType
      FROM BloodDonation d
      JOIN Donors dn ON d.DonorID = dn.DonorID
      ORDER BY d.DonationDate DESC
    `;
    res.json(result.recordset);
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

// Error Handling Middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

// Start Server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => 
  console.log(`Server running on http://localhost:${PORT}`));

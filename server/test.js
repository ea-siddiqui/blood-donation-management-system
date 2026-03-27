const sql = require('mssql');
const config = require('./config');  // Path to your config file

async function test() {
  try {
    await sql.connect(config);
    console.log('✅ Connected to:', config.server);
    const result = await sql.query`SELECT DB_NAME() AS dbname`;
    console.log('Current database:', result.recordset[0].dbname);
  } catch (err) {
    console.error('❌ Connection failed:', err.message);
  } finally {
    sql.close();
  }
}

test();
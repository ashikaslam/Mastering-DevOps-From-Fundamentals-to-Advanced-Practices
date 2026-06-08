const express = require('express');
const { Pool } = require('pg');

const app = express();
const PORT = process.env.PORT || 5000;

// ডেটাবেস কানেকশন পুল (এনভায়রনমেন্ট ভ্যারিয়েবল থেকে ডেটা নেবে)
const pool = new Pool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'dbuser',
    password: process.env.DB_PASSWORD || 'password123',
    database: process.env.DB_NAME || 'mydb',
    port: 5432,
});

// হেলথ চেক এবং স্ট্যাটাস এপিআই এনডপয়েন্ট
app.get('/api/status', async (req, res) => {
    try {
        // ডেটাবেস থেকে বর্তমান সময় কোয়েরি করা
        const dbRes = await pool.query('SELECT NOW()');
        res.json({
            status: "Success",
            message: "Welcome to the 3-Tier Application!",
            database_time: dbRes.rows[0].now
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ 
            status: "Error", 
            message: "Database connection failed" 
        });
    }
});

app.listen(PORT, () => {
    console.log(`Backend running on port ${PORT}`);
});
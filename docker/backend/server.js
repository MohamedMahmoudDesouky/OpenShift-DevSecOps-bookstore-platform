/**
 * Bookstore Backend API
 * OpenShift 4.18 – DevSecOps Demo
 * Production-ready & Hardened
 */

'use strict';

const express = require('express');
const mysql = require('mysql2/promise');
const redis = require('redis');
const cors = require('cors');
const helmet = require('helmet');

const app = express();
const PORT = process.env.PORT || 3000;

// ===================
// App & Security Setup
// ===================

// Required for OpenShift Routes / reverse proxies
app.set('trust proxy', 1);

// Security headers (CSP disabled to avoid frontend conflicts)
app.use(
  helmet({
    contentSecurityPolicy: false
  })
);

app.use(cors());
app.use(express.json());

// ===================
// Database Configuration
// ===================

const dbConfig = {
  host: process.env.DB_HOST || 'mysql',
  port: Number(process.env.DB_PORT) || 3306,
  user: process.env.DB_USER || 'bookstore',
  password: process.env.DB_PASSWORD || 'bookstore123',
  database: process.env.DB_NAME || 'bookstore',
  waitForConnections: true,
  connectionLimit: 10,
  queueLimit: 0
};

// ===================
// Redis Configuration (Optional Cache)
// ===================

const redisConfig = {
  socket: {
    host: process.env.REDIS_HOST || 'redis',
    port: Number(process.env.REDIS_PORT) || 6379
  }
};

const CACHE_TTL = Number(process.env.CACHE_TTL) || 300;

let pool;
let redisClient;
let server;

// ===================
// Init Database
// ===================

async function initDatabase() {
  try {
    pool = mysql.createPool(dbConfig);
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();
    console.log('✅ Database connected');
    return true;
  } catch (err) {
    console.error('❌ Database connection failed:', err.message);
    return false;
  }
}

// ===================
// Init Redis (Non-blocking)
// ===================

async function initRedis() {
  try {
    redisClient = redis.createClient(redisConfig);

    redisClient.on('error', err => {
      console.warn('⚠️ Redis error:', err.message);
    });

    redisClient.on('end', () => {
      console.warn('⚠️ Redis connection closed');
    });

    await redisClient.connect();
    console.log('✅ Redis connected');
  } catch (err) {
    console.warn('⚠️ Redis unavailable, caching disabled');
    redisClient = null;
  }
}

// ===================
// Cache Helpers
// ===================

async function getFromCache(key) {
  if (!redisClient?.isOpen) return null;
  try {
    const data = await redisClient.get(key);
    return data ? JSON.parse(data) : null;
  } catch {
    return null;
  }
}

async function setToCache(key, value, ttl = CACHE_TTL) {
  if (!redisClient?.isOpen) return;
  try {
    await redisClient.setEx(key, ttl, JSON.stringify(value));
  } catch {}
}

async function invalidateCache() {
  if (!redisClient?.isOpen) return;
  try {
    const keys = await redisClient.keys('books:*');
    if (keys.length) await redisClient.del(keys);
    await redisClient.del('books:all');
  } catch {}
}

// ===================
// Health Endpoints
// ===================

app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

app.get('/api/ready', async (req, res) => {
  try {
    const conn = await pool.getConnection();
    await conn.ping();
    conn.release();

    res.json({
      status: 'ready',
      database: 'connected',
      cache: redisClient?.isOpen ? 'connected' : 'disabled'
    });
  } catch (err) {
    res.status(503).json({
      status: 'not ready',
      database: 'disconnected',
      cache: redisClient?.isOpen ? 'connected' : 'disabled'
    });
  }
});

// ===================
// Books API
// ===================

// GET all books
app.get('/api/books', async (req, res) => {
  try {
    const cached = await getFromCache('books:all');
    if (cached) {
      return res.json({ data: cached, fromCache: true });
    }

    const [rows] = await pool.query(
      'SELECT * FROM books ORDER BY created_at DESC'
    );

    await setToCache('books:all', rows);
    res.json({ data: rows, fromCache: false });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch books' });
  }
});

// GET single book
app.get('/api/books/:id', async (req, res) => {
  try {
    const key = `books:${req.params.id}`;
    const cached = await getFromCache(key);

    if (cached) {
      return res.json({ data: cached, fromCache: true });
    }

    const [rows] = await pool.query(
      'SELECT * FROM books WHERE id = ?',
      [req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({ error: 'Book not found' });
    }

    await setToCache(key, rows[0]);
    res.json({ data: rows[0], fromCache: false });
  } catch {
    res.status(500).json({ error: 'Failed to fetch book' });
  }
});

// POST new book
app.post('/api/books', async (req, res) => {
  try {
    const { title, author, isbn, price = 0, stock = 0 } = req.body;

    if (!title || !author || !isbn) {
      return res.status(400).json({
        error: 'title, author and isbn are required'
      });
    }

    const [result] = await pool.query(
      'INSERT INTO books (title, author, isbn, price, stock) VALUES (?, ?, ?, ?, ?)',
      [title, author, isbn, price, stock]
    );

    await invalidateCache();

    res.status(201).json({
      data: { id: result.insertId, title, author, isbn, price, stock }
    });
  } catch (err) {
    if (err.code === 'ER_DUP_ENTRY') {
      return res.status(409).json({
        error: 'Book with this ISBN already exists'
      });
    }
    res.status(500).json({ error: 'Failed to create book' });
  }
});

// PUT update book
app.put('/api/books/:id', async (req, res) => {
  try {
    const { title, author, isbn, price, stock } = req.body;

    const [result] = await pool.query(
      'UPDATE books SET title=?, author=?, isbn=?, price=?, stock=?, updated_at=NOW() WHERE id=?',
      [title, author, isbn, price, stock, req.params.id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Book not found' });
    }

    await invalidateCache();
    res.json({ message: 'Book updated successfully' });
  } catch {
    res.status(500).json({ error: 'Failed to update book' });
  }
});

// DELETE book
app.delete('/api/books/:id', async (req, res) => {
  try {
    const [result] = await pool.query(
      'DELETE FROM books WHERE id=?',
      [req.params.id]
    );

    if (!result.affectedRows) {
      return res.status(404).json({ error: 'Book not found' });
    }

    await invalidateCache();
    res.json({ message: 'Book deleted successfully' });
  } catch {
    res.status(500).json({ error: 'Failed to delete book' });
  }
});

// ===================
// Errors
// ===================

app.use((req, res) => {
  res.status(404).json({ error: 'Endpoint not found' });
});

app.use((err, req, res, next) => {
  console.error('Unhandled error:', err);
  res.status(500).json({ error: 'Internal server error' });
});

// ===================
// Start Server
// ===================

async function startServer() {
  let retries = 5;

  while (retries--) {
    if (await initDatabase()) break;
    console.log(`⏳ Retrying DB connection (${retries} left)`);
    await new Promise(r => setTimeout(r, 5000));
  }

  if (!pool) {
    console.error('❌ Database unavailable. Exiting.');
    process.exit(1);
  }

  await initRedis();

  server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`🚀 Bookstore API running on port ${PORT}`);
  });
}

startServer();

// ===================
// Graceful Shutdown
// ===================

process.on('SIGTERM', async () => {
  console.log('📴 SIGTERM received');
  server?.close();
  if (redisClient?.isOpen) await redisClient.quit();
  if (pool) await pool.end();
  process.exit(0);
});

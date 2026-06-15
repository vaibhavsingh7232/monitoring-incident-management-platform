/**
 * Production-Grade Node.js Application
 * Exposes custom Prometheus metrics for monitoring
 */

const express = require('express');
const promClient = require('prom-client');
const winston = require('winston');
const morgan = require('morgan');

const app = express();
const PORT = process.env.PORT || 3000;

// ─────────────────────────────────────────────
// LOGGER SETUP
// ─────────────────────────────────────────────
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: '/app/logs/error.log', level: 'error' }),
    new winston.transports.File({ filename: '/app/logs/combined.log' }),
  ],
});

// ─────────────────────────────────────────────
// PROMETHEUS METRICS SETUP
// ─────────────────────────────────────────────
const register = new promClient.Registry();
promClient.collectDefaultMetrics({ register });

// HTTP Request Counter
const httpRequestsTotal = new promClient.Counter({
  name: 'http_requests_total',
  help: 'Total number of HTTP requests',
  labelNames: ['method', 'route', 'status_code'],
  registers: [register],
});

// HTTP Request Duration
const httpRequestDuration = new promClient.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.001, 0.005, 0.01, 0.05, 0.1, 0.3, 0.5, 1, 2, 5],
  registers: [register],
});

// Active Users Gauge
const activeUsers = new promClient.Gauge({
  name: 'active_users_total',
  help: 'Number of currently active users',
  registers: [register],
});

// Error Rate Counter
const errorsTotal = new promClient.Counter({
  name: 'application_errors_total',
  help: 'Total number of application errors',
  labelNames: ['type', 'route'],
  registers: [register],
});

// Application Uptime
const appStartTime = Date.now();
const appUptime = new promClient.Gauge({
  name: 'app_uptime_seconds',
  help: 'Application uptime in seconds',
  registers: [register],
});

// Memory Usage (Custom)
const memoryUsage = new promClient.Gauge({
  name: 'app_memory_usage_bytes',
  help: 'Application memory usage in bytes',
  labelNames: ['type'],
  registers: [register],
});

// CPU Usage simulation
const cpuUsage = new promClient.Gauge({
  name: 'app_cpu_usage_percent',
  help: 'Application CPU usage percentage',
  registers: [register],
});

// DB Connection Pool
const dbConnections = new promClient.Gauge({
  name: 'db_connections_active',
  help: 'Number of active database connections',
  registers: [register],
});

// Business Metric: Orders processed
const ordersProcessed = new promClient.Counter({
  name: 'orders_processed_total',
  help: 'Total number of orders processed',
  labelNames: ['status'],
  registers: [register],
});

// ─────────────────────────────────────────────
// SIMULATE BACKGROUND METRICS
// ─────────────────────────────────────────────
let simulatedCPU = 15;
let simulatedMemory = 200 * 1024 * 1024;
let simulatedActiveUsers = 50;
let memoryLeaking = false;
let cpuSpiking = false;

setInterval(() => {
  // Update uptime
  appUptime.set((Date.now() - appStartTime) / 1000);

  // Simulate CPU
  if (cpuSpiking) {
    simulatedCPU = Math.min(95, simulatedCPU + Math.random() * 5);
  } else {
    simulatedCPU = Math.max(5, Math.min(40, simulatedCPU + (Math.random() - 0.5) * 3));
  }
  cpuUsage.set(simulatedCPU);

  // Simulate memory
  if (memoryLeaking) {
    simulatedMemory += 10 * 1024 * 1024; // +10MB leak
  } else {
    simulatedMemory = Math.max(
      150 * 1024 * 1024,
      simulatedMemory + (Math.random() - 0.5) * 5 * 1024 * 1024
    );
  }
  memoryUsage.set({ type: 'heap' }, simulatedMemory);
  memoryUsage.set({ type: 'rss' }, simulatedMemory * 1.3);

  // Simulate active users
  simulatedActiveUsers = Math.max(
    10,
    simulatedActiveUsers + Math.floor((Math.random() - 0.5) * 10)
  );
  activeUsers.set(simulatedActiveUsers);

  // Simulate DB connections
  dbConnections.set(Math.floor(5 + Math.random() * 15));

  // Process memory from Node.js
  const mem = process.memoryUsage();
  memoryUsage.set({ type: 'node_heap' }, mem.heapUsed);
}, 5000);

// ─────────────────────────────────────────────
// MIDDLEWARE
// ─────────────────────────────────────────────
app.use(express.json());
app.use(morgan('combined', {
  stream: { write: (message) => logger.info(message.trim()) }
}));

// Metrics middleware
app.use((req, res, next) => {
  const start = Date.now();
  res.on('finish', () => {
    const duration = (Date.now() - start) / 1000;
    const route = req.route ? req.route.path : req.path;
    httpRequestsTotal.inc({
      method: req.method,
      route,
      status_code: res.statusCode,
    });
    httpRequestDuration.observe(
      { method: req.method, route, status_code: res.statusCode },
      duration
    );
    if (res.statusCode >= 400) {
      errorsTotal.inc({ type: res.statusCode >= 500 ? 'server' : 'client', route });
    }
  });
  next();
});

// ─────────────────────────────────────────────
// ROUTES
// ─────────────────────────────────────────────

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString(),
    version: '1.0.0',
  });
});

// Metrics endpoint
app.get('/metrics', async (req, res) => {
  res.setHeader('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// API endpoints
app.get('/api/users', (req, res) => {
  const delay = Math.random() * 100;
  setTimeout(() => {
    res.json({ users: simulatedActiveUsers, timestamp: new Date().toISOString() });
  }, delay);
});

app.get('/api/orders', (req, res) => {
  const status = Math.random() > 0.1 ? 'success' : 'failed';
  ordersProcessed.inc({ status });
  if (status === 'failed') {
    return res.status(500).json({ error: 'Order processing failed' });
  }
  res.json({ orderId: Math.random().toString(36).substr(2, 9), status });
});

app.get('/api/slow', (req, res) => {
  const delay = 2000 + Math.random() * 3000;
  setTimeout(() => {
    res.json({ message: 'Slow response simulated', delay: `${delay.toFixed(0)}ms` });
  }, delay);
});

app.get('/api/error', (req, res) => {
  logger.error('Simulated error endpoint hit');
  res.status(500).json({ error: 'Simulated server error', timestamp: new Date().toISOString() });
});

// ─────────────────────────────────────────────
// INCIDENT SIMULATION ENDPOINTS
// ─────────────────────────────────────────────

app.post('/incident/cpu-spike', (req, res) => {
  cpuSpiking = true;
  logger.warn('CPU spike simulation started');
  setTimeout(() => { cpuSpiking = false; }, 120000); // 2 min spike
  res.json({ incident: 'cpu-spike', status: 'started', duration: '2 minutes' });
});

app.post('/incident/memory-leak', (req, res) => {
  memoryLeaking = true;
  logger.warn('Memory leak simulation started');
  setTimeout(() => { memoryLeaking = false; }, 300000); // 5 min leak
  res.json({ incident: 'memory-leak', status: 'started', duration: '5 minutes' });
});

app.post('/incident/reset', (req, res) => {
  cpuSpiking = false;
  memoryLeaking = false;
  simulatedCPU = 15;
  simulatedMemory = 200 * 1024 * 1024;
  logger.info('All incidents reset to normal');
  res.json({ status: 'reset', message: 'All incidents cleared' });
});

app.get('/api/db-check', (req, res) => {
  // Simulate DB connectivity check
  const dbDown = Math.random() < 0.05; // 5% chance of failure
  if (dbDown) {
    logger.error('Database connectivity failure');
    errorsTotal.inc({ type: 'database', route: '/api/db-check' });
    return res.status(503).json({ error: 'Database connection failed' });
  }
  res.json({ db: 'connected', latency: `${(Math.random() * 50).toFixed(1)}ms` });
});

// ─────────────────────────────────────────────
// 404 HANDLER
// ─────────────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found', path: req.path });
});

// ─────────────────────────────────────────────
// ERROR HANDLER
// ─────────────────────────────────────────────
app.use((err, req, res, next) => {
  logger.error('Unhandled error', { error: err.message, stack: err.stack });
  errorsTotal.inc({ type: 'unhandled', route: req.path });
  res.status(500).json({ error: 'Internal Server Error' });
});

// ─────────────────────────────────────────────
// START SERVER
// ─────────────────────────────────────────────
app.listen(PORT, () => {
  logger.info(`Application started on port ${PORT}`);
  console.log(`🚀 App running at http://localhost:${PORT}`);
  console.log(`📊 Metrics at http://localhost:${PORT}/metrics`);
});

module.exports = app;

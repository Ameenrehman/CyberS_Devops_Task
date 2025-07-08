const express = require('express');
const promClient = require('prom-client'); // Import the prom-client library
const app = express();
const db = require('./persistence'); // Assuming this path is correct for your persistence layer
const getItems = require('./routes/getItems');
const addItem = require('./routes/addItem');
const updateItem = require('./routes/updateItem');
const deleteItem = require('./routes/deleteItem');

// 1. Register default metrics (optional, but good for basic system insights)
// This collects standard Node.js process metrics, CPU, memory, etc.
promClient.collectDefaultMetrics();

// 2. Define custom metrics
// A counter for total HTTP requests
const httpRequestCounter = new promClient.Counter({
    name: 'http_requests_total',
    help: 'Total number of HTTP requests',
    labelNames: ['method', 'route', 'status_code']
});

// A gauge for the number of active HTTP requests
const httpActiveRequestsGauge = new promClient.Gauge({
    name: 'http_active_requests',
    help: 'Number of active HTTP requests'
});

// A histogram for request duration
const httpRequestDurationSeconds = new promClient.Histogram({
    name: 'http_request_duration_seconds',
    help: 'Duration of HTTP requests in seconds',
    labelNames: ['method', 'route', 'status_code'],
    buckets: [0.1, 0.5, 1, 2, 5] // Buckets for response time
});

// Middleware to track request metrics
app.use((req, res, next) => {
    // Increment active requests gauge
    httpActiveRequestsGauge.inc();

    // Start tracking request duration
    const end = httpRequestDurationSeconds.startTimer();

    // Listen for the 'finish' event when the response is sent
    res.on('finish', () => {
        // Decrement active requests gauge
        httpActiveRequestsGauge.dec();

        // Increment the total request counter
        httpRequestCounter.inc({
            method: req.method,
            route: req.route ? req.route.path : req.path, // Use req.route.path for defined routes, req.path for others
            status_code: res.statusCode
        });

        // End the timer for request duration
        end({
            method: req.method,
            route: req.route ? req.route.path : req.path,
            status_code: res.statusCode
        });
    });
    next(); // Continue to the next middleware or route handler
});

app.get('/health', (req, res) => {
    res.status(200).send('OK');
});
app.use(express.json());
app.use(express.static(__dirname + '/static'));

// Existing To-Do app routes
app.get('/items', getItems);
app.post('/items', addItem);
app.put('/items/:id', updateItem);
app.delete('/items/:id', deleteItem);

// 3. Add the Prometheus metrics endpoint
app.get('/metrics', async (req, res) => {
    res.set('Content-Type', promClient.register.contentType);
    res.end(await promClient.register.metrics());
});

// Initialize the database and start the server
db.init().then(() => {
    app.listen(3000, '0.0.0.0',() => console.log('Listening on port 3000'));
}).catch((err) => {
    console.error(err);
    process.exit(1);
});

// Graceful shutdown for database teardown
const gracefulShutdown = () => {
    db.teardown()
        .catch(() => {})
        .then(() => process.exit());
};

process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);
process.on('SIGUSR2', gracefulShutdown); // Sent by nodemon

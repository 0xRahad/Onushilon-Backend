const express = require("express");
const mongoose = require("mongoose");
const cors = require("cors");
const morgan = require("morgan");
const dotenv = require("dotenv");

// Load environment variables
dotenv.config();

// Import routes
const authRoutes = require("./routes/auth");
const adminRoutes = require("./routes/admin");

// Import database connection
const connectDB = require("./config/database");
const { successResponse, errorResponse } = require("./utils/responseHandler");

// Create Express app
const app = express();

// Connect to database
connectDB();

// Middleware
app.use(cors());
app.use(morgan("dev"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/admin", adminRoutes);

// Health check route
app.get("/api/health", (req, res) => {
  return successResponse(res, 200, "Onushilon Quiz Backend API is running", {
    timestamp: new Date().toISOString(),
  });
});

// 404 handler
app.use("*", (req, res) => {
  return errorResponse(res, 404, "Route not found");
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  return errorResponse(
    res,
    500,
    "Something went wrong!",
    process.env.NODE_ENV === "development" ? { error: err.message } : null
  );
});

const PORT = process.env.PORT || 3001;

app.listen(PORT, () => {
  console.clear();
  console.log(`Server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV}`);
  console.log(`Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;

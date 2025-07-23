const express = require("express");
const { authenticate, authorize } = require("../middleware/auth");
const {
  getAllUsers,
  getUserById,
  updateUserRole,
  updateUserStatus,
  deleteUser,
  getStatistics,
} = require("../controllers/adminController");

const router = express.Router();

// Apply authentication middleware to all admin routes
router.use(authenticate);

// Admin routes with proper authorization
router.get("/users", authorize("admin"), getAllUsers);
router.get("/users/:id", authorize("admin"), getUserById);
router.put("/users/:id/role", authorize("admin"), updateUserRole);
router.put("/users/:id/status", authorize("admin"), updateUserStatus);
router.delete("/users/:id", authorize("admin"), deleteUser);
router.get("/stats", authorize("admin"), getStatistics);

module.exports = router;

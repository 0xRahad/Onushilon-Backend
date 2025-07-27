const express = require("express");
const { authenticate } = require("../middleware/auth");

const authController = require("../controllers/authController");
const router = express.Router();

router.post("/register", authController.registerUser);
router.post("/login", authController.loginUser);
router.get("/profile", authenticate, authController.getUserProfile);
router.put("/profile", authenticate, authController.updateUserProfile);

// Password reset routes
router.post("/password-reset/request", authController.requestPasswordReset);
router.post("/password-reset/reset", authController.resetPassword);

module.exports = router;

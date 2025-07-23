const express = require("express");
const { authenticate } = require("../middleware/auth");

const authController = require("../controllers/authController");
const router = express.Router();

router.post("/register", authController.registerUser);
router.post("/login", authController.loginUser);
router.get("/profile", authenticate, authController.getUserProfile);
router.put("/profile", authenticate, authController.updateUserProfile);

module.exports = router;

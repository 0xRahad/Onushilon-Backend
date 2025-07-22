const express = require("express");
const { authenticate } = require("../middleware/auth");
const {
  validateRegister,
  validateLogin,
  handleValidationErrors,
} = require("../middleware/validation");
const authController = require("../controllers/authController");

const router = express.Router();

router.post(
  "/register",
  validateRegister,
  handleValidationErrors,
  authController.registerUser
);
router.post(
  "/login",
  validateLogin,
  handleValidationErrors,
  authController.loginUser
);
router.get("/profile", authenticate, authController.getUserProfile);
router.put("/profile", authenticate, authController.updateUserProfile);

module.exports = router;

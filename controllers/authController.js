const User = require("../models/User");
const { generateToken } = require("../middleware/auth");
const { successResponse, errorResponse } = require("../utils/responseHandler");
const {
  isValidEmail,
  isValidPhone,
  isValidPassword,
} = require("../utils/validators");

const registerUser = async (req, res) => {
  try {
    const { name, email, phone, age, password } = req.body;

    // Check for required fields
    if (!name || !email || !phone || !age || !password) {
      return errorResponse(res, 400, "All fields are required");
    }

    // Validate email format
    if (!isValidEmail(email)) {
      return errorResponse(res, 400, "Please provide a valid email address");
    }

    // Validate phone number
    if (!isValidPhone(phone)) {
      return errorResponse(res, 400, "Phone number must be at least 10 digits");
    }

    // Validate password
    if (!isValidPassword(password)) {
      return errorResponse(
        res,
        400,
        "Password must be at least 6 characters long"
      );
    }
    const existingUser = await User.findOne({ $or: [{ email }, { phone }] });
    if (existingUser) {
      return errorResponse(
        res,
        400,
        "User with this email or phone number already exists"
      );
    }

    const user = new User({
      name,
      email,
      age,
      phone,
      password,
    });

    await user.save();

    const token = generateToken(user._id);

    return successResponse(res, 201, "User registered successfully", {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        age: age,
        phone: phone,
        role: user.role,
        createdAt: user.createdAt,
      },
      token,
    });
  } catch (error) {
    console.error("Registration error:", error);
    return errorResponse(res, 500, "Server error during registration");
  }
};

const loginUser = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Check for required fields
    if (!email || !password) {
      return errorResponse(res, 400, "Email and password are required");
    }

    // Validate email format
    if (!isValidEmail(email)) {
      return errorResponse(res, 400, "Please provide a valid email address");
    }

    const user = await User.findByEmailWithPassword(email);
    if (!user) {
      return errorResponse(res, 401, "Invalid credentials");
    }

    if (!user.isActive) {
      return errorResponse(
        res,
        401,
        "Account has been deactivated. Please contact support."
      );
    }

    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return errorResponse(res, 401, "Invalid credentials");
    }

    user.lastLogin = new Date();
    await user.save();

    const token = generateToken(user._id);

    return successResponse(res, 200, "Login successful", {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        age: user.age,
        phone: user.phone,
        role: user.role,
        lastLogin: user.lastLogin,
      },
      token,
    });
  } catch (error) {
    console.error("Login error:", error);
    return errorResponse(res, 500, "Server error during login");
  }
};

const getUserProfile = async (req, res) => {
  try {
    return successResponse(res, 200, "Profile retrieved successfully", {
      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role,
        isActive: req.user.isActive,
        lastLogin: req.user.lastLogin,
        createdAt: req.user.createdAt,
        updatedAt: req.user.updatedAt,
      },
    });
  } catch (error) {
    console.error("Profile error:", error);
    return errorResponse(res, 500, "Server error while fetching profile");
  }
};

const updateUserProfile = async (req, res) => {
  try {
    const { name, email, phone, age } = req.body;

    // Validate and update fields if provided
    if (name) req.user.name = name.trim();
    if (email) {
      if (!isValidEmail(email)) {
        return errorResponse(res, 400, "Please provide a valid email address");
      }
      // Check for email uniqueness
      const existing = await User.findOne({
        email,
        _id: { $ne: req.user._id },
      });
      if (existing) {
        return errorResponse(res, 400, "Email already in use");
      }
      req.user.email = email.trim();
    }
    if (phone) {
      if (!isValidPhone(phone)) {
        return errorResponse(
          res,
          400,
          "Phone number must be at least 10 digits"
        );
      }
      // Check for phone uniqueness
      const existing = await User.findOne({
        phone,
        _id: { $ne: req.user._id },
      });
      if (existing) {
        return errorResponse(res, 400, "Phone number already in use");
      }
      req.user.phone = phone.trim();
    }
    if (age) req.user.age = age;

    await req.user.save();

    return successResponse(res, 200, "Profile updated successfully", {
      user: {
        id: req.user._id,
        name: req.user.name,
        email: req.user.email,
        role: req.user.role,
        updatedAt: req.user.updatedAt,
      },
    });
  } catch (error) {
    console.error("Profile update error:", error);
    return errorResponse(res, 500, "Server error while updating profile");
  }
};

module.exports = {
  registerUser,
  loginUser,
  getUserProfile,
  updateUserProfile,
};

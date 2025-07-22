const User = require("../models/User");
const { generateToken } = require("../middleware/auth");
const { successResponse, errorResponse } = require("../utils/responseHandler");

const registerUser = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    const existingUser = await User.findOne({ email });
    if (existingUser) {
      return errorResponse(res, 400, "User with this email already exists");
    }

    const user = new User({
      name,
      email,
      password,
    });

    await user.save();

    const token = generateToken(user._id);

    return successResponse(res, 201, "User registered successfully", {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
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
    const { name } = req.body;

    if (!name || name.trim().length < 2) {
      return errorResponse(res, 400, "Name must be at least 2 characters long");
    }

    req.user.name = name.trim();
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

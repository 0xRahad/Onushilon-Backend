const User = require("../models/User");
const {
  successResponse,
  errorResponse,
  paginatedResponse,
} = require("../utils/responseHandler");

const getAllUsers = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const skip = (page - 1) * limit;

    const query = {};

    if (
      req.query.role &&
      ["user", "moderator", "admin"].includes(req.query.role)
    ) {
      query.role = req.query.role;
    }

    if (req.query.isActive !== undefined) {
      query.isActive = req.query.isActive === "true";
    }

    if (req.query.search) {
      query.$or = [
        { name: { $regex: req.query.search, $options: "i" } },
        { email: { $regex: req.query.search, $options: "i" } },
      ];
    }

    const users = await User.find(query)
      .select("-password")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await User.countDocuments(query);

    return paginatedResponse(res, 200, "Users fetched successfully", users, {
      current: page,
      total: Math.ceil(total / limit),
      count: users.length,
      totalUsers: total,
    });
  } catch (error) {
    console.error("Get users error:", error);
    return errorResponse(res, 500, "Server error while fetching users");
  }
};

const getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select("-password");

    if (!user) {
      return errorResponse(res, 404, "User not found");
    }

    return successResponse(res, 200, "User fetched successfully", { user });
  } catch (error) {
    console.error("Get user error:", error);

    if (error.name === "CastError") {
      return errorResponse(res, 400, "Invalid user ID format");
    }

    return errorResponse(res, 500, "Server error while fetching user");
  }
};

const updateUserRole = async (req, res) => {
  try {
    const { role } = req.body;
    const userId = req.params.id;

    if (userId === req.user._id.toString() && role !== "admin") {
      return errorResponse(res, 400, "You cannot change your own admin role");
    }

    const user = await User.findById(userId);

    if (!user) {
      return errorResponse(res, 404, "User not found");
    }

    user.role = role;
    await user.save();

    return successResponse(res, 200, `User role updated to ${role}`, {
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        updatedAt: user.updatedAt,
      },
    });
  } catch (error) {
    console.error("Update role error:", error);

    if (error.name === "CastError") {
      return errorResponse(res, 400, "Invalid user ID format");
    }

    return errorResponse(res, 500, "Server error while updating role");
  }
};

const updateUserStatus = async (req, res) => {
  try {
    const { isActive } = req.body;
    const userId = req.params.id;

    if (typeof isActive !== "boolean") {
      return errorResponse(res, 400, "isActive must be a boolean value");
    }

    if (userId === req.user._id.toString() && !isActive) {
      return errorResponse(res, 400, "You cannot deactivate your own account");
    }

    const user = await User.findById(userId);

    if (!user) {
      return errorResponse(res, 404, "User not found");
    }

    user.isActive = isActive;
    await user.save();

    return successResponse(
      res,
      200,
      `User ${isActive ? "activated" : "deactivated"} successfully`,
      {
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          isActive: user.isActive,
          updatedAt: user.updatedAt,
        },
      }
    );
  } catch (error) {
    console.error("Update status error:", error);

    if (error.name === "CastError") {
      return errorResponse(res, 400, "Invalid user ID format");
    }

    return errorResponse(res, 500, "Server error while updating status");
  }
};

const deleteUser = async (req, res) => {
  try {
    const userId = req.params.id;

    if (userId === req.user._id.toString()) {
      return errorResponse(res, 400, "You cannot delete your own account");
    }

    const user = await User.findById(userId);

    if (!user) {
      return errorResponse(res, 404, "User not found");
    }

    await User.findByIdAndDelete(userId);

    return successResponse(res, 200, "User deleted successfully");
  } catch (error) {
    console.error("Delete user error:", error);

    if (error.name === "CastError") {
      return errorResponse(res, 400, "Invalid user ID format");
    }

    return errorResponse(res, 500, "Server error while deleting user");
  }
};

const getStatistics = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const inactiveUsers = await User.countDocuments({ isActive: false });

    const usersByRole = await User.aggregate([
      {
        $group: {
          _id: "$role",
          count: { $sum: 1 },
        },
      },
    ]);

    const recentUsers = await User.find()
      .select("name email role createdAt")
      .sort({ createdAt: -1 })
      .limit(5);

    return successResponse(res, 200, "Statistics fetched successfully", {
      stats: {
        totalUsers,
        activeUsers,
        inactiveUsers,
        usersByRole: usersByRole.reduce((acc, item) => {
          acc[item._id] = item.count;
          return acc;
        }, {}),
        recentUsers,
      },
    });
  } catch (error) {
    console.error("Get stats error:", error);
    return errorResponse(res, 500, "Server error while fetching statistics");
  }
};

module.exports = {
  getAllUsers,
  getUserById,
  updateUserRole,
  updateUserStatus,
  deleteUser,
  getStatistics,
};

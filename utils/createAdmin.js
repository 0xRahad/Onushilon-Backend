const User = require("../models/User");

const createInitialAdmin = async () => {
  try {
    // Check if admin already exists
    const adminExists = await User.findOne({ role: "admin" });

    if (adminExists) {
      console.log("Admin user already exists");
      return;
    }

    // Create initial admin user
    const adminUser = new User({
      name: "Administrator",
      email: process.env.ADMIN_EMAIL || "admin@onushilon.com",
      password: process.env.ADMIN_PASSWORD || "admin123456",
      role: "admin",
    });

    await adminUser.save();
    console.log("Initial admin user created successfully");
    console.log(`Admin Email: ${adminUser.email}`);
    console.log(
      `Admin Password: ${process.env.ADMIN_PASSWORD || "admin123456"}`
    );
    console.log("Please change the admin password after first login!");
  } catch (error) {
    console.error("Error creating initial admin user:", error);
  }
};

module.exports = createInitialAdmin;

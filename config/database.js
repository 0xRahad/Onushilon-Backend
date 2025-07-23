const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI);
    console.log(`MongoDB Connected: ${conn.connection.host}`);
  } catch (error) {
    console.error("MongoDB connection error:", error.message);
    console.log(
      "Server will continue without database. Install MongoDB to enable full functionality."
    );
    console.log("Install MongoDB: brew install mongodb-community");
    console.log("Start MongoDB: brew services start mongodb-community");
  }
};

module.exports = connectDB;

const mongoose = require("mongoose");

const connectDB = async () => {
  try {
    console.log("Environment check:", {
      hasMongoURI: !!process.env.MONGODB_URI,
      nodeEnv: process.env.NODE_ENV,
      port: process.env.PORT,
    });

    // Use fallback URI if environment variable is not set
    if (!process.env.MONGODB_URI) {
      throw new Error("MONGODB_URI is not defined in environment variables!");
    }
    const mongoURI = process.env.MONGODB_URI;

    const conn = await mongoose.connect(mongoURI, {
      useNewUrlParser: true,
      useUnifiedTopology: true,
      serverSelectionTimeoutMS: 10000, // 10s timeout
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
    return conn;
  } catch (error) {
    console.error(`MongoDB Connection Error: ${error.message}`);
    console.error(
      "Please check your MongoDB connection string and credentials."
    );
    console.error(
      "If you have a .env file, make sure MONGODB_URI is set correctly."
    );
    throw error;
  }
};

module.exports = connectDB;

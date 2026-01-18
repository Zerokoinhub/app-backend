// ✅ Load environment variables safely
const path = require("path");
const fs = require("fs"); // Add this import

if (process.env.NODE_ENV !== "production") {
  const envPath = path.join(__dirname, "../.env");
  require("dotenv").config({ path: envPath });
  console.log("🔧 Local .env loaded from:", envPath);
} else {
  console.log("🔧 Production mode – using Railway environment variables");
}

console.log("🔧 __dirname:", __dirname);

const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const morgan = require("morgan");
const connectDB = require("./config/database");
const userRoutes = require("./routes/userRoutes");
const tokenRoutes = require("./routes/tokenRoutes");
const withdrawRoutes = require("./routes/withdrawRoutes");
const courseRoutes = require("./routes/courseRoutes");
const notificationRoutes = require("./routes/notificationRoutes");
const timeRoutes = require("./routes/timeRoutes");
const sessionNotificationService = require("./services/sessionNotificationService");
const autoNotificationService = require("./services/autoNotificationService");

const PORT = process.env.PORT || 3000;

const app = express();
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ CRITICAL: Create uploads directory if it doesn't exist
const uploadsDir = path.join(__dirname, 'uploads');
const profilePicturesDir = path.join(uploadsDir, 'profile-pictures');

try {
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
    console.log('✅ Created uploads directory:', uploadsDir);
  }

  if (!fs.existsSync(profilePicturesDir)) {
    fs.mkdirSync(profilePicturesDir, { recursive: true });
    console.log('✅ Created profile-pictures directory:', profilePicturesDir);
  }
  
  // Check write permissions
  fs.accessSync(uploadsDir, fs.constants.W_OK);
  fs.accessSync(profilePicturesDir, fs.constants.W_OK);
  console.log('✅ Write permissions OK for upload directories');
} catch (error) {
  console.error('❌ Error creating/checking upload directories:', error);
  console.error('   Please check file permissions on your server');
}

// ✅ Add this line to serve static files
app.use('/uploads', express.static('uploads'));
console.log('✅ Serving static files from /uploads');

app.use("/api/users", userRoutes);
app.use("/api/token", tokenRoutes);
app.use("/api/withdraw", withdrawRoutes);
app.use("/api/courses", courseRoutes);
app.use("/api/notifications", notificationRoutes);
app.use("/api/time", timeRoutes);

// Connect to MongoDB
connectDB()
  .then(() => {
    console.log("Connected to MongoDB successfully");

    // Start session notification service
    sessionNotificationService.start();
    console.log("🔔 Session notification service started");

    // Start automatic notification service
    autoNotificationService.start();
    console.log("📱 Automatic notification service started");
  })
  .catch((error) => {
    console.error("MongoDB connection error:", error);
  });

app.get("/", (req, res) => {
  res.json({ message: "Welcome to the API" });
});

// ✅ Add better error handling middleware
app.use((err, req, res, next) => {
  console.error('🔥 Server Error:', err);
  console.error('🔥 Error Stack:', err.stack);
  
  if (err.name === 'MulterError') {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return res.status(400).json({ 
        success: false, 
        error: 'File too large. Maximum size is 5MB' 
      });
    }
    return res.status(400).json({ 
      success: false, 
      error: 'File upload error: ' + err.message 
    });
  }
  
  res.status(500).json({ 
    success: false, 
    message: "Internal server error",
    error: process.env.NODE_ENV === 'production' ? undefined : err.message 
  });
});

const server = app
  .listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
    console.log(`✅ Upload directory ready: ${profilePicturesDir}`);
  })
  .on("error", (err) => {
    if (err.code === "EADDRINUSE") {
      console.error(
        `Port ${PORT} is already in use. Please try a different port.`
      );
      process.exit(1);
    } else {
      console.error("Server error:", err);
    }
  });

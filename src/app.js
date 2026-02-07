// ✅ Load environment variables safely
const path = require("path");

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
const admin = require("firebase-admin"); 


const PORT = process.env.PORT || 3000;

// ========== 🔥 FIREBASE ADMIN INITIALIZATION ==========
console.log("🔥 Initializing Firebase Admin...");
try {
  if (!admin.apps.length) {
    const serviceAccount = {
      projectId: process.env.FIREBASE_PROJECT_ID,
      clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
    };
    
    console.log("🔥 Firebase Project ID:", serviceAccount.projectId ? "✓" : "✗");
    console.log("🔥 Firebase Client Email:", serviceAccount.clientEmail ? "✓" : "✗");
    
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      storageBucket: process.env.FIREBASE_STORAGE_BUCKET || "zerokoin-705c5.firebasestorage.app",
    });
    
    console.log("✅ Firebase Admin initialized");
  }
} catch (error) {
  console.error("❌ Firebase Admin initialization failed:", error.message);
}
// ======================================================

const app = express();
app.use(cors());
app.use(helmet());
app.use(morgan("dev"));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ⚠️ REMOVED directory creation - Railway has ephemeral filesystem
// Just serve static files without creating directories
app.use('/uploads', express.static('uploads'));
console.log('✅ Serving static files from /uploads (if directory exists)');

// ✅ Test endpoint for Firebase
app.get("/api/test-firebase", async (req, res) => {
  try {
    const bucket = admin.storage().bucket();
    const [files] = await bucket.getFiles({ prefix: 'profile_pics/' });
    
    res.json({
      success: true,
      message: "Firebase Storage is working",
      bucket: bucket.name,
      fileCount: files.length
    });
  } catch (error) {
    console.error("Firebase test error:", error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});


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
  res.json({ message: "Welcome to the API"         
           });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: "Something went wrong!" });
});

const server = app
  .listen(PORT, () => {
    console.log(`Server is running on port ${PORT}`);
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

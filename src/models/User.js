const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  // ============ AUTHENTICATION & PROFILE ============
  firebaseUid: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  email: {
    type: String,
    unique: true,
    sparse: true,
    index: true
  },
  name: {
    type: String,
    default: ''
  },
  photoURL: {
    type: String,
    default: ''
  },
  role: {
    type: String,
    enum: ['user', 'admin'],
    default: 'user'
  },
  
  // ============ FINANCIAL & WALLET ============
  balance: {
    type: Number,
    default: 0,
    min: 0
  },
  walletAddresses: {
    metamask: { 
      type: String, 
      default: null 
    },
    trustWallet: { 
      type: String, 
      default: null 
    }
  },
  walletStatus: {
    type: String,
    enum: ['Not Connected', 'Connected'],
    default: 'Not Connected'
  },
  recentAmount: {
    type: Number,
    default: 0
  },
  
  // ============ SESSIONS ============
  sessions: [{
    sessionNumber: {
      type: Number,
      required: true,
      min: 1,
      max: 4
    },
    unlockedAt: {
      type: Date,
      default: null
    },
    completedAt: {
      type: Date,
      default: null
    },
    isLocked: {
      type: Boolean,
      default: true
    },
    nextUnlockAt: {
      type: Date,
      default: null
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  }],
  
  lastSessionCompletedAt: {
    type: Date,
    default: null
  },
  lastSessionCycleCompletedAt: {
    type: Date,
    default: null
  },
  sessionsResetAt: {
    type: Date,
    default: null
  },
  lastSessionUnlockAt: {
    type: Date,
    default: null
  },
  
  // ============ INVITE & REFERRAL ============
  inviteCode: {
    type: String,
    unique: true,
    required: true,
    index: true,
    default: function() {
      const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
      let code = '';
      for (let i = 0; i < 8; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
      }
      return code;
    }
  },
  referredBy: {
    type: String,
    default: null
  },
  
  // ============ ACTIVITY & USAGE ============
  calculatorUsage: {
    type: Number,
    default: 0
  },
  screenshots: {
    type: [String],
    default: []
  },
  country: {
    type: String,
    default: null
  },
  
  // ============ NOTIFICATIONS ============
  fcmTokens: [{
    token: {
      type: String,
      required: true
    },
    deviceId: {
      type: String,
      default: null
    },
    platform: {
      type: String,
      enum: ['android', 'ios', 'web'],
      default: null
    },
    isActive: {
      type: Boolean,
      default: true
    },
    lastUsed: {
      type: Date,
      default: Date.now
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  notificationSettings: {
    sessionUnlocked: {
      type: Boolean,
      default: true
    },
    pushEnabled: {
      type: Boolean,
      default: true
    }
  },
  
  readNotifications: [{
    notificationId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Notification',
      required: true
    },
    readAt: {
      type: Date,
      default: Date.now
    }
  }]
}, {
  // ✅ Add timestamps for better tracking
  timestamps: true // This adds createdAt and updatedAt automatically
});

// ============ INDEXES FOR PERFORMANCE ============
userSchema.index({ firebaseUid: 1 });
userSchema.index({ email: 1 });
userSchema.index({ inviteCode: 1 });
userSchema.index({ 'sessions.sessionNumber': 1 });
userSchema.index({ 'sessions.isLocked': 1 });
userSchema.index({ 'sessions.nextUnlockAt': 1 });

// ============ PRE-SAVE MIDDLEWARE ============
userSchema.pre('save', function(next) {
  // Ensure inviteCode is set if not provided
  if (!this.inviteCode || this.inviteCode.trim() === '') {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 8; i++) {
      code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    this.inviteCode = code;
  }
  
  // Update sessions lastUpdated timestamp
  if (this.sessions && this.isModified('sessions')) {
    const now = new Date();
    this.sessions = this.sessions.map(session => {
      return {
        ...session,
        lastUpdated: now
      };
    });
  }
  
  next();
});

// ============ STATIC METHODS ============
userSchema.statics.findByFirebaseUid = function(firebaseUid) {
  return this.findOne({ firebaseUid });
};

userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email });
};

userSchema.statics.findByInviteCode = function(inviteCode) {
  return this.findOne({ inviteCode });
};

// ============ INSTANCE METHODS ============
userSchema.methods.getSession = function(sessionNumber) {
  if (!this.sessions || this.sessions.length === 0) {
    return null;
  }
  return this.sessions.find(s => s.sessionNumber === sessionNumber);
};

userSchema.methods.isSessionUnlocked = function(sessionNumber) {
  const session = this.getSession(sessionNumber);
  if (!session) return false;
  
  return !session.isLocked;
};

userSchema.methods.isSessionCompleted = function(sessionNumber) {
  const session = this.getSession(sessionNumber);
  if (!session) return false;
  
  return session.completedAt !== null;
};

userSchema.methods.getNextUnlockTime = function(sessionNumber) {
  const session = this.getSession(sessionNumber);
  if (!session) return null;
  
  return session.nextUnlockAt;
};

userSchema.methods.addBalance = async function(amount) {
  if (amount <= 0) {
    throw new Error('Amount must be positive');
  }
  
  this.balance += amount;
  this.recentAmount = amount;
  return this.save();
};

userSchema.methods.completeSession = async function(sessionNumber, coinsToAdd = 30) {
  const session = this.getSession(sessionNumber);
  if (!session) {
    throw new Error(`Session ${sessionNumber} not found`);
  }
  
  if (session.isLocked) {
    throw new Error(`Session ${sessionNumber} is locked`);
  }
  
  if (session.completedAt) {
    throw new Error(`Session ${sessionNumber} already completed`);
  }
  
  // Mark as completed
  session.completedAt = new Date();
  session.isLocked = true; // Lock after completion
  session.lastUpdated = new Date();
  
  // Add coins to balance
  this.balance += coinsToAdd;
  this.recentAmount = coinsToAdd;
  this.lastSessionCompletedAt = new Date();
  
  // If this is session 4, mark cycle completion
  if (sessionNumber === 4) {
    this.lastSessionCycleCompletedAt = new Date();
  }
  
  // Update the session in the array
  const sessionIndex = this.sessions.findIndex(s => s.sessionNumber === sessionNumber);
  if (sessionIndex !== -1) {
    this.sessions[sessionIndex] = session;
  }
  
  return this.save();
};

userSchema.methods.resetAllSessions = async function() {
  const now = new Date();
  
  this.sessions = this.sessions.map((session, index) => {
    const resetTime = new Date(now.getTime() + (index * 6 * 60 * 60 * 1000));
    
    return {
      sessionNumber: index + 1,
      unlockedAt: index === 0 ? resetTime : null,
      completedAt: null,
      isLocked: index > 0,
      nextUnlockAt: index > 0 ? resetTime : null,
      createdAt: session.createdAt || now,
      lastUpdated: now
    };
  });
  
  this.sessionsResetAt = now;
  return this.save();
};

userSchema.methods.initializeSessions = async function() {
  if (this.sessions && this.sessions.length > 0) {
    // Already has sessions, just update status
    return this.updateSessionStatuses();
  }
  
  const now = new Date();
  this.sessions = [
    {
      sessionNumber: 1,
      unlockedAt: now,
      completedAt: null,
      isLocked: false,
      nextUnlockAt: null,
      createdAt: now,
      lastUpdated: now
    },
    {
      sessionNumber: 2,
      unlockedAt: null,
      completedAt: null,
      isLocked: true,
      nextUnlockAt: new Date(now.getTime() + 6 * 60 * 60 * 1000),
      createdAt: now,
      lastUpdated: now
    },
    {
      sessionNumber: 3,
      unlockedAt: null,
      completedAt: null,
      isLocked: true,
      nextUnlockAt: new Date(now.getTime() + 12 * 60 * 60 * 1000),
      createdAt: now,
      lastUpdated: now
    },
    {
      sessionNumber: 4,
      unlockedAt: null,
      completedAt: null,
      isLocked: true,
      nextUnlockAt: new Date(now.getTime() + 18 * 60 * 60 * 1000),
      createdAt: now,
      lastUpdated: now
    }
  ];
  
  return this.save();
};

userSchema.methods.updateSessionStatuses = function() {
  if (!this.sessions || this.sessions.length === 0) {
    return this;
  }
  
  const now = new Date();
  let changed = false;
  
  this.sessions = this.sessions.map(session => {
    const sessionCopy = { ...session };
    
    // Convert nextUnlockAt to Date if it's a string
    if (sessionCopy.nextUnlockAt && typeof sessionCopy.nextUnlockAt === 'string') {
      sessionCopy.nextUnlockAt = new Date(sessionCopy.nextUnlockAt);
    }
    
    // If session is locked and nextUnlockAt has passed, unlock it
    if (sessionCopy.isLocked && sessionCopy.nextUnlockAt) {
      if (now >= sessionCopy.nextUnlockAt) {
        sessionCopy.isLocked = false;
        sessionCopy.unlockedAt = now;
        sessionCopy.nextUnlockAt = null;
        sessionCopy.lastUpdated = now;
        changed = true;
      }
    }
    
    return sessionCopy;
  });
  
  if (changed) {
    this.markModified('sessions');
  }
  
  return this;
};

// ============ VIRTUAL FIELDS ============
userSchema.virtual('completedSessionsCount').get(function() {
  if (!this.sessions) return 0;
  return this.sessions.filter(s => s.completedAt !== null).length;
});

userSchema.virtual('unlockedSessionsCount').get(function() {
  if (!this.sessions) return 0;
  return this.sessions.filter(s => !s.isLocked).length;
});

userSchema.virtual('totalEarnedFromSessions').get(function() {
  if (!this.sessions) return 0;
  return this.sessions.filter(s => s.completedAt !== null).length * 30;
});

userSchema.virtual('nextSessionToComplete').get(function() {
  if (!this.sessions) return null;
  
  // Find first session that is unlocked but not completed
  return this.sessions.find(s => !s.isLocked && s.completedAt === null);
});

// ============ TOJSON TRANSFORM ============
userSchema.set('toJSON', {
  virtuals: true,
  transform: function(doc, ret) {
    // Remove sensitive/technical fields
    delete ret.__v;
    delete ret._id;
    
    // Convert _id to id
    ret.id = doc._id;
    
    return ret;
  }
});

module.exports = mongoose.model('User', userSchema);

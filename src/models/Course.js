const mongoose = require('mongoose');

const pageSchema = new mongoose.Schema({
  title: { type: String, required: true },
  content: { type: String, required: true },
  time: { type: String, default: "120" }
});

const languageContentSchema = new mongoose.Schema({
  courseName: { type: String, required: true },
  pages: [pageSchema]
});

const courseSchema = new mongoose.Schema({
  // Main fields for simple courses (legacy)
  courseName: { type: String },
  pages: [pageSchema],
  
  // New structure for multi-language courses
  languages: {
    type: Map,
    of: languageContentSchema,
    default: {}
  },
  
  // Helper fields
  primaryName: { type: String },
  availableLanguages: [{ type: String, default: [] }],
  
  // Metadata
  isActive: { type: Boolean, default: true },
  uploadedBy: { type: mongoose.Schema.Types.ObjectId, ref: 'User' },
  
  // Timestamps
  createdAt: { type: Date, default: Date.now },
  updatedAt: { type: Date, default: Date.now }
}, { timestamps: true });

// Add index for faster queries
courseSchema.index({ courseName: 1 });
courseSchema.index({ 'languages.en.courseName': 1 });
courseSchema.index({ isActive: 1 });

// Method to get localized content
courseSchema.methods.getLocalizedContent = function(language = 'en') {
  // If course has languages structure
  if (this.languages && this.languages.get) {
    const langContent = this.languages.get(language);
    if (langContent && langContent.courseName) {
      return {
        courseName: langContent.courseName,
        pages: langContent.pages || []
      };
    }
    
    // Fallback to English
    const enContent = this.languages.get('en');
    if (enContent && enContent.courseName) {
      return {
        courseName: enContent.courseName,
        pages: enContent.pages || []
      };
    }
  }
  
  // Fallback to simple structure
  return {
    courseName: this.courseName || 'Untitled',
    pages: this.pages || []
  };
};

module.exports = mongoose.model('Course', courseSchema);

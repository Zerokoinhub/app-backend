const Course = require('../models/Course');
// Get courses by language (for Flutter app)
exports.getCoursesByLanguage = async (req, res) => {
  try {
    const { language } = req.params;
    const { page = 1, limit = 10 } = req.query;

    console.log(`📚 Fetching courses in language: ${language}`);

    // Find courses that have this language available
    const query = { 
      [`languages.${language}`]: { $exists: true },
      isActive: true 
    };

    const courses = await Course.find(query)
      .populate('uploadedBy', 'username email')
      .skip((parseInt(page) - 1) * parseInt(limit))
      .limit(parseInt(limit));

    const total = await Course.countDocuments(query);

    console.log(`✅ Found ${courses.length} courses in ${language}`);

    // Transform courses to include only the requested language content
    const localizedCourses = courses.map(course => {
      const langContent = course.languages[language];
      
      if (!langContent) {
        console.log(`⚠️ No ${language} content for course ${course._id}`);
        return null;
      }
      
      let courseName = langContent.courseName || 'Untitled';
      
      // ✅ Filter out Arabic course names when language is English
      if (language === 'en') {
        const hasArabic = /[\u0600-\u06FF]/.test(courseName);
        if (hasArabic) {
          console.log(`⚠️ Skipping Arabic course name: ${courseName}`);
          return null;
        }
      }
      
      // ✅ Filter out English course names when language is Arabic
      if (language === 'ar') {
        const hasEnglish = /^[a-zA-Z\s\']+$/.test(courseName);
        if (hasEnglish) {
          console.log(`⚠️ Skipping English course name: ${courseName}`);
          return null;
        }
      }
      
      return {
        id: course._id,
        courseName: courseName,
        pages: langContent.pages || [],
        uploadedBy: course.uploadedBy,
        availableLanguages: course.availableLanguages || [],
        createdAt: course.createdAt
      };
    }).filter(course => course !== null);

    console.log(`✅ Returning ${localizedCourses.length} courses for ${language}`);
    
    res.json({ 
      success: true, 
      courses: localizedCourses,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(total / parseInt(limit)),
        totalCourses: total
      }
    });
  } catch (error) {
    console.error("Error fetching courses by language:", error);
    res.status(500).json({
      success: false,
      message: "Error fetching courses by language",
      error: error.message,
    });
  }
};
// Add a new course with full content
exports.addCourse = async (req, res) => {
  try {
    const { courseName, languages, uploadedBy } = req.body;
    
    if (!courseName && !languages) {
      return res.status(400).json({ 
        success: false, 
        message: 'Course name or languages content is required' 
      });
    }

    // Check if course already exists
    const existingCourse = await Course.findOne({ 
      $or: [
        { courseName: courseName },
        { 'languages.en.courseName': courseName }
      ]
    });
    
    if (existingCourse) {
      return res.status(409).json({ 
        success: false, 
        message: 'Course with this name already exists' 
      });
    }

    const courseData = {
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date()
    };

    if (languages) {
      courseData.languages = languages;
      courseData.availableLanguages = Object.keys(languages);
      // Get primary name from first language
      const firstLang = Object.keys(languages)[0];
      if (firstLang && languages[firstLang].courseName) {
        courseData.courseName = languages[firstLang].courseName;
        courseData.primaryName = languages[firstLang].courseName;
      }
    } else if (courseName) {
      courseData.courseName = courseName;
      courseData.primaryName = courseName;
      courseData.languages = {
        en: {
          courseName: courseName,
          pages: [
            {
              title: courseName,
              content: `Welcome to ${courseName}. Content is being prepared.`,
              time: "120"
            }
          ]
        }
      };
      courseData.availableLanguages = ['en'];
    }

    if (uploadedBy) {
      courseData.uploadedBy = uploadedBy;
    }

    const course = new Course(courseData);
    await course.save();

    res.status(201).json({ 
      success: true,
      message: 'Course added successfully',
      course: {
        id: course._id,
        courseName: course.courseName || course.primaryName,
        languages: course.languages,
        availableLanguages: course.availableLanguages,
        isActive: course.isActive
      }
    });
  } catch (error) {
    console.error('Add course error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error adding course', 
      error: error.message 
    });
  }
};

// Get all course names (for dropdown)
exports.getAllCourses = async (req, res) => {
  try {
    console.log('📚 Fetching all course names');
    
    const courses = await Course.find({ isActive: true })
      .select('courseName languages primaryName')
      .lean();
    
    const courseNames = [];
    
    courses.forEach(course => {
      // Get from direct courseName field
      if (course.courseName && course.courseName.trim()) {
        if (!courseNames.includes(course.courseName)) {
          courseNames.push(course.courseName);
        }
      }
      
      // Get from languages object
      if (course.languages) {
        Object.values(course.languages).forEach(langContent => {
          if (langContent && langContent.courseName && !courseNames.includes(langContent.courseName)) {
            courseNames.push(langContent.courseName);
          }
        });
      }
      
      // Get from primaryName
      if (course.primaryName && course.primaryName.trim() && !courseNames.includes(course.primaryName)) {
        courseNames.push(course.primaryName);
      }
    });
    
    res.status(200).json({ 
      success: true,
      courseNames: courseNames,
      totalCourses: courseNames.length
    });
  } catch (error) {
    console.error('Get courses error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching courses', 
      error: error.message 
    });
  }
};

// Get course details by name (for Flutter app)
exports.getCourseDetailsByName = async (req, res) => {
  try {
    const { courseName } = req.params;
    const { lang = 'en' } = req.query;
    
    console.log(`📚 Fetching course: ${courseName} in language: ${lang}`);
    
    // Search in multiple fields
    const course = await Course.findOne({
      isActive: true,
      $or: [
        { courseName: { $regex: new RegExp(`^${courseName}$`, 'i') } },
        { primaryName: { $regex: new RegExp(`^${courseName}$`, 'i') } },
        { 'languages.en.courseName': { $regex: new RegExp(`^${courseName}$`, 'i') } },
        { 'languages.ar.courseName': { $regex: new RegExp(`^${courseName}$`, 'i') } }
      ]
    }).lean();

    if (!course) {
      return res.status(404).json({ 
        success: false, 
        message: 'Course not found or not active' 
      });
    }

    // Extract content for requested language
    let pages = [];
    let localizedCourseName = courseName;
    
    if (course.languages && course.languages[lang]) {
      pages = course.languages[lang].pages || [];
      localizedCourseName = course.languages[lang].courseName || courseName;
    } else if (course.languages && course.languages.en) {
      pages = course.languages.en.pages || [];
      localizedCourseName = course.languages.en.courseName || courseName;
    } else if (course.pages) {
      pages = course.pages;
    }

    res.status(200).json({ 
      success: true,
      course: {
        _id: course._id,
        courseName: localizedCourseName,
        pages: pages,
        language: lang,
        isActive: course.isActive,
        createdAt: course.createdAt,
        updatedAt: course.updatedAt,
        availableLanguages: course.availableLanguages || ['en']
      }
    });
  } catch (error) {
    console.error('Get course details error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching course details', 
      error: error.message 
    });
  }
};

// Get all courses with full details (for admin panel)
exports.getAllCoursesFull = async (req, res) => {
  try {
    const courses = await Course.find({ isActive: true })
      .sort({ createdAt: -1 })
      .lean();
    
    const transformedCourses = courses.map(course => ({
      _id: course._id,
      courseName: course.courseName || course.primaryName || 'Untitled',
      primaryName: course.primaryName,
      languages: course.languages,
      availableLanguages: course.availableLanguages || [],
      isActive: course.isActive,
      createdAt: course.createdAt,
      updatedAt: course.updatedAt
    }));
    
    res.status(200).json({ 
      success: true, 
      courses: transformedCourses,
      total: transformedCourses.length
    });
  } catch (error) {
    console.error('Get all courses error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error fetching courses', 
      error: error.message 
    });
  }
};

// Delete a course
exports.deleteCourse = async (req, res) => {
  try {
    const { id } = req.params;
    
    const course = await Course.findByIdAndDelete(id);
    if (!course) {
      return res.status(404).json({ 
        success: false, 
        message: 'Course not found' 
      });
    }

    res.status(200).json({ 
      success: true, 
      message: 'Course deleted successfully' 
    });
  } catch (error) {
    console.error('Delete course error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error deleting course', 
      error: error.message 
    });
  }
};

// Update a course
exports.updateCourse = async (req, res) => {
  try {
    const { id } = req.params;
    const updateData = req.body;
    
    updateData.updatedAt = new Date();
    
    const course = await Course.findByIdAndUpdate(
      id,
      updateData,
      { new: true, runValidators: true }
    );
    
    if (!course) {
      return res.status(404).json({ 
        success: false, 
        message: 'Course not found' 
      });
    }
    
    res.status(200).json({ 
      success: true, 
      message: 'Course updated successfully',
      course
    });
  } catch (error) {
    console.error('Update course error:', error.message);
    res.status(500).json({ 
      success: false, 
      message: 'Error updating course', 
      error: error.message 
    });
  }
};

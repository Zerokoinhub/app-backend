const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');

// ✅ ADD THIS - Create new course (POST)
router.post('/', courseController.addCourse);

// Public routes - Get all courses
router.get('/all', courseController.getAllCourses);
router.get('/:courseName', courseController.getCourseDetailsByName);
router.get('/language/:language', courseController.getCoursesByLanguage);

module.exports = router;

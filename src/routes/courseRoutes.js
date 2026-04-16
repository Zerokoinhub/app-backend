const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');

// Public routes - Get all courses
router.get('/all', courseController.getAllCourses);
router.get('/:courseName', courseController.getCourseDetailsByName); // New route to get course details by name
router.get('/language/:language', courseController.getCoursesByLanguage);
module.exports = router;

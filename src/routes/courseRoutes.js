const express = require('express');
const router = express.Router();
const courseController = require('../controllers/courseController');

// ✅ POST route for creating courses
router.post('/', courseController.addCourse);

// ✅ GET all courses (full data)
router.get('/all', courseController.getAllCourses);

// ✅ Get course details by name
router.get('/:courseName', courseController.getCourseDetailsByName);

// ✅ Get courses by language (for Flutter app)
router.get('/language/:language', courseController.getCoursesByLanguage);

// ✅ Update course
router.put('/:id', courseController.updateCourse);

// ✅ Delete course
router.delete('/:id', courseController.deleteCourse);

module.exports = router;

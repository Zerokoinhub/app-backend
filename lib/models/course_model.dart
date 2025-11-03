import 'dart:convert';

class CoursePage {
  final String? title;
  final String? content;
  final String? time;

  CoursePage({this.title, this.content, this.time});

  factory CoursePage.fromJson(Map<String, dynamic> json) {
    return CoursePage(
      title: json['title'],
      content: json['content'],
      time: json['time'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'title': title, 'content': content, 'time': time};
  }
}

class Course {
  final String id;
  final String courseName;
  final List<CoursePage> pages;
  final bool isActive;
  final String? uploadedBy; // Assuming uploadedBy is a String ID for now
  final DateTime createdAt;
  final DateTime updatedAt;

  Course({
    required this.id,
    required this.courseName,
    required this.pages,
    required this.isActive,
    this.uploadedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    var pagesList = json['pages'] as List;
    List<CoursePage> pages =
        pagesList.map((i) => CoursePage.fromJson(i)).toList();

    return Course(
      id: json['_id'],
      courseName: json['courseName'],
      pages: pages,
      isActive: json['isActive'],
      uploadedBy: json['uploadedBy'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseName': courseName,
      'pages': pages.map((e) => e.toJson()).toList(),
      'isActive': isActive,
      'uploadedBy': uploadedBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

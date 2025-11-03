class NotificationModel {
  final String id;
  final String image;
  final String title;
  final String content;
  final String link;
  final bool isSent;
  final DateTime? sentAt;
  final DateTime createdAt;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.image,
    required this.title,
    required this.content,
    this.link = '',
    required this.isSent,
    this.sentAt,
    required this.createdAt,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Prefer `content`, but support alternate keys some endpoints may return
    // such as `body`, `message`, or `description`.
    final String content = (json['content'] ??
            json['body'] ??
            json['message'] ??
            json['description'] ??
            '')
        .toString();
    print('🔍 NotificationModel.fromJson:');
    print('   Raw JSON: $json');
    print('   Parsed content: "$content"');

    // Prefer `imageUrl` (as returned by production API),
    // but fall back to `image` for compatibility with older responses.
    final String parsedImage =
        (json['imageUrl'] ?? json['image'] ?? '').toString();

    final notification = NotificationModel(
      id: json['id'] ?? '',
      image: parsedImage,
      title: json['title'] ?? '',
      content: content,
      link: (json['link'] ?? '').toString(),
      isSent: json['isSent'] ?? false,
      sentAt: json['sentAt'] != null ? DateTime.parse(json['sentAt']) : null,
      createdAt: DateTime.parse(json['createdAt']),
      isRead: json['isRead'] ?? false,
    );

    print('   DisplayText: "${notification.displayText}"');
    return notification;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'title': title,
      'content': content,
      'link': link,
      'isSent': isSent,
      'sentAt': sentAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
    };
  }

  // Helper method to get the display text
  String get displayText {
    final normalized = content.trim();
    if (normalized.isNotEmpty && normalized.toLowerCase() != 'null') {
      return normalized;
    } else {
      return '';
    }
  }

  // Helper method to get time ago string
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} min${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  // Helper method to get full image URL
  String get fullImageUrl {
    // If image is already a full URL, return as is
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    // If it's a Cloudinary URL path, construct the full URL
    if (image.contains('cloudinary')) {
      return image;
    }

    // For local development or relative paths, construct the full URL
    // You may need to adjust this based on your backend setup
    const baseUrl = 'http://10.0.2.2:3000'; // Adjust for your backend URL

    // Remove leading slash if present to avoid double slashes
    final cleanPath = image.startsWith('/') ? image.substring(1) : image;
    return '$baseUrl/$cleanPath';
  }

  bool get hasLink => link.trim().isNotEmpty;
}

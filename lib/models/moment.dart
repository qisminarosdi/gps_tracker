import 'dart:convert';

class Moment {
  final String title;
  final String description;
  final List<String> mediaUrls;
  final String username;
  final String? userAvatar;
  final String timestamp;

  Moment({
    required this.title,
    required this.description,
    required this.mediaUrls,
    required this.username,
    this.userAvatar,
    required this.timestamp,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    final medias = json['medias'] as List<dynamic>? ?? [];
    final mediaUrls = medias
        .map((media) => media['media_filename'] as String? ?? '')
        .where((url) => url.isNotEmpty)
        .toList();

   // Parse description (string or JSON)
    String parsedDescription = '';
    final rawDescription = json['description'];
    
    if (rawDescription is String && rawDescription.isNotEmpty) {
      try {
        // Try to parse as JSON
        final descJson = jsonDecode(rawDescription);
        
        // Extract text from question field if it exists
        if (descJson is Map && descJson.containsKey('question')) {
          final question = descJson['question'];
          if (question is List && question.isNotEmpty) {
            final firstQuestion = question[0];
            if (firstQuestion is Map && firstQuestion.containsKey('content')) {
              parsedDescription = firstQuestion['content'] as String? ?? '';
            }
          }
        } else if (descJson is Map && descJson.containsKey('content')) {
          // Direct content field
          parsedDescription = descJson['content'] as String? ?? '';
        } else if (descJson is String) {
          parsedDescription = descJson;
        }
      } catch (e) {
        // If parsing fails, use raw string
        parsedDescription = rawDescription;
      }
    }

    return Moment(
      title: json['title'] as String? ?? '',
      description: parsedDescription,
      mediaUrls: mediaUrls,
      username: json['username'] as String? ?? 'Anonymous',
      userAvatar: json['user_avatar'] as String?,
      timestamp: json['created_at'] as String? ?? '',
    );
  }

  String? get firstImage => mediaUrls.isNotEmpty ? mediaUrls.first : null;
  
  String get timeAgo {
    if (timestamp.isEmpty) return 'Just now';
    
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}mo';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Just now';
    }
  }
}
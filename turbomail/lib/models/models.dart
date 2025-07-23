class Email {
  final String id;
  final String address;
  final String subject;
  final String sender;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  Email({
    required this.id,
    required this.address,
    required this.subject,
    required this.sender,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['_id'] ?? '',
      address: json['address'] ?? '',
      subject: json['subject'] ?? '',
      sender: json['sender'] ?? '',
      body: json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'address': address,
      'subject': subject,
      'sender': sender,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  Email copyWith({
    String? id,
    String? address,
    String? subject,
    String? sender,
    String? body,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return Email(
      id: id ?? this.id,
      address: address ?? this.address,
      subject: subject ?? this.subject,
      sender: sender ?? this.sender,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class EmailStats {
  final int totalEmails;
  final int unreadEmails;
  final int todayEmails;
  final int activeAddresses;

  EmailStats({
    required this.totalEmails,
    required this.unreadEmails,
    required this.todayEmails,
    required this.activeAddresses,
  });

  factory EmailStats.fromJson(Map<String, dynamic> json) {
    return EmailStats(
      totalEmails: json['totalEmails'] ?? 0,
      unreadEmails: json['unreadEmails'] ?? 0,
      todayEmails: json['todayEmails'] ?? 0,
      activeAddresses: json['activeAddresses'] ?? 0,
    );
  }
}

class Domain {
  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;

  Domain({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
  });

  factory Domain.fromJson(Map<String, dynamic> json) {
    return Domain(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      isActive: json['isActive'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AppUpdate {
  final String version;
  final String title;
  final String description;
  final String downloadUrl;
  final bool isRequired;
  final DateTime releaseDate;

  AppUpdate({
    required this.version,
    required this.title,
    required this.description,
    required this.downloadUrl,
    required this.isRequired,
    required this.releaseDate,
  });

  factory AppUpdate.fromJson(Map<String, dynamic> json) {
    return AppUpdate(
      version: json['version'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      downloadUrl: json['downloadUrl'] ?? '',
      isRequired: json['isRequired'] ?? false,
      releaseDate: DateTime.parse(json['releaseDate'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class AdConfig {
  final String id;
  final String type;
  final String content;
  final bool isActive;
  final int displayFrequency;

  AdConfig({
    required this.id,
    required this.type,
    required this.content,
    required this.isActive,
    required this.displayFrequency,
  });

  factory AdConfig.fromJson(Map<String, dynamic> json) {
    return AdConfig(
      id: json['_id'] ?? '',
      type: json['type'] ?? '',
      content: json['content'] ?? '',
      isActive: json['isActive'] ?? false,
      displayFrequency: json['displayFrequency'] ?? 5,
    );
  }
}
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Email {
  final String id;
  final String from;
  final String to;
  final String subject;
  final String body;
  final DateTime timestamp;
  final bool isRead;

  Email({
    required this.id,
    required this.from,
    required this.to,
    required this.subject,
    required this.body,
    required this.timestamp,
    this.isRead = false,
  });

  factory Email.fromJson(Map<String, dynamic> json) {
    return Email(
      id: json['_id'] ?? '',
      from: json['from'] ?? '',
      to: json['to'] ?? '',
      subject: json['subject'] ?? 'No Subject',
      body: json['body'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'from': from,
      'to': to,
      'subject': subject,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
    };
  }

  Email copyWith({
    String? id,
    String? from,
    String? to,
    String? subject,
    String? body,
    DateTime? timestamp,
    bool? isRead,
  }) {
    return Email(
      id: id ?? this.id,
      from: from ?? this.from,
      to: to ?? this.to,
      subject: subject ?? this.subject,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
    );
  }
}

class EmailProvider with ChangeNotifier {
  static const String _baseUrl = 'http://165.22.109.153:3001';
  
  List<Email> _emails = [];
  String _currentEmail = '';
  String _deviceId = '';
  bool _isLoading = false;
  String? _error;

  List<Email> get emails => _emails;
  String get currentEmail => _currentEmail;
  String get deviceId => _deviceId;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get unreadCount => _emails.where((email) => !email.isRead).length;

  EmailProvider() {
    _initializeDeviceId();
  }

  Future<void> _initializeDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    _deviceId = prefs.getString('device_id') ?? _generateDeviceId();
    await prefs.setString('device_id', _deviceId);
    notifyListeners();
  }

  String _generateDeviceId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> generateRandomEmail() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'deviceId': _deviceId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentEmail = data['email'];
        await _saveCurrentEmail();
        await fetchEmails();
      } else {
        throw Exception('Failed to generate email: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to generate email: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> generateCustomEmail(String username, String domain) async {
    _setLoading(true);
    _clearError();

    try {
      final customEmail = '$username@$domain';
      final response = await http.post(
        Uri.parse('$_baseUrl/api/generate-custom-email'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deviceId': _deviceId,
          'email': customEmail,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentEmail = data['email'];
        await _saveCurrentEmail();
        await fetchEmails();
      } else {
        throw Exception('Failed to generate custom email: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to generate custom email: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchEmails() async {
    if (_deviceId.isEmpty) return;

    _setLoading(true);
    _clearError();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/emails/$_deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _emails = (data['emails'] as List)
            .map((emailJson) => Email.fromJson(emailJson))
            .toList();
        _emails.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      } else {
        throw Exception('Failed to fetch emails: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to fetch emails: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markEmailAsRead(String emailId) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/api/emails/$emailId/read'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final emailIndex = _emails.indexWhere((email) => email.id == emailId);
        if (emailIndex != -1) {
          _emails[emailIndex] = _emails[emailIndex].copyWith(isRead: true);
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to mark email as read: $e');
    }
  }

  Future<void> deleteEmail(String emailId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/emails/$emailId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _emails.removeWhere((email) => email.id == emailId);
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to delete email: $e');
    }
  }

  Future<void> clearAllEmails() async {
    _setLoading(true);
    _clearError();

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/api/emails/$_deviceId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _emails.clear();
        notifyListeners();
      } else {
        throw Exception('Failed to clear emails: ${response.statusCode}');
      }
    } catch (e) {
      _setError('Failed to clear emails: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshEmails() async {
    await fetchEmails();
  }

  Future<void> _saveCurrentEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_email', _currentEmail);
  }

  Future<void> loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    _currentEmail = prefs.getString('current_email') ?? '';
    if (_currentEmail.isNotEmpty) {
      await fetchEmails();
    }
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Get email statistics
  Map<String, int> getEmailStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final thisWeek = today.subtract(Duration(days: now.weekday - 1));
    final thisMonth = DateTime(now.year, now.month, 1);

    return {
      'total': _emails.length,
      'unread': unreadCount,
      'today': _emails.where((email) => email.timestamp.isAfter(today)).length,
      'thisWeek': _emails.where((email) => email.timestamp.isAfter(thisWeek)).length,
      'thisMonth': _emails.where((email) => email.timestamp.isAfter(thisMonth)).length,
    };
  }

  // Search emails
  List<Email> searchEmails(String query) {
    if (query.isEmpty) return _emails;
    
    final lowercaseQuery = query.toLowerCase();
    return _emails.where((email) {
      return email.subject.toLowerCase().contains(lowercaseQuery) ||
             email.from.toLowerCase().contains(lowercaseQuery) ||
             email.body.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get emails by date range
  List<Email> getEmailsByDateRange(DateTime start, DateTime end) {
    return _emails.where((email) {
      return email.timestamp.isAfter(start) && email.timestamp.isBefore(end);
    }).toList();
  }
}
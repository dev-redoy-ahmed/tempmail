import 'package:dio/dio.dart';
import '../models/email_model.dart';
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'http://165.22.109.153:3001';
  static const String adminUrl = 'http://165.22.109.153:3003'; // Admin panel URL
  static const String apiKey = 'tempmail-master-key-2024';
  static const List<String> availableDomains = ['oplex.online', 'agrovia.store'];

  final Dio _dio = Dio();
  final Dio _adminDio = Dio();

  ApiService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    _adminDio.options.baseUrl = adminUrl;
    _adminDio.options.connectTimeout = const Duration(seconds: 10);
    _adminDio.options.receiveTimeout = const Duration(seconds: 10);
  }

  /// Get available domains
  List<String> getAvailableDomains() {
    return availableDomains;
  }

  /// Generate a random email
  Future<GeneratedEmail> generateRandomEmail() async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/generate', queryParameters: {
        'key': apiKey,
        'deviceId': deviceId,
      });
      
      return GeneratedEmail.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to generate random email: $e');
    }
  }

  /// Generate a manual email with custom username
  Future<GeneratedEmail> generateManualEmail(String username, String domain) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/generate/manual', queryParameters: {
        'key': apiKey,
        'username': username,
        'domain': domain,
        'deviceId': deviceId,
      });
      
      return GeneratedEmail.fromJson(response.data);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 409) {
        final errorData = e.response?.data;
        if (errorData is Map && errorData.containsKey('message')) {
          throw Exception(errorData['message']);
        }
        throw Exception('This email is already taken. Please use a different name.');
      }
      throw Exception('Failed to generate manual email: $e');
    }
  }

  /// Check if email is available
  Future<bool> checkEmailAvailability(String email) async {
    try {
      final response = await _dio.get('/check/$email', queryParameters: {
        'key': apiKey,
      });
      
      return response.data['available'] ?? false;
    } catch (e) {
      throw Exception('Failed to check email availability: $e');
    }
  }

  /// Get inbox messages for an email
  Future<List<EmailModel>> getInboxMessages(String email) async {
    try {
      final response = await _dio.get('/inbox/$email', queryParameters: {
        'key': apiKey,
      });
      
      final List<dynamic> data = response.data;
      return data.map((json) => EmailModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get inbox messages: $e');
    }
  }

  /// Delete a specific message from inbox
  Future<void> deleteMessage(String email, int index) async {
    try {
      await _dio.delete('/delete/$email/$index', queryParameters: {
        'key': apiKey,
      });
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  /// Delete entire inbox
  Future<void> deleteInbox(String email) async {
    try {
      await _dio.delete('/delete/$email', queryParameters: {
        'key': apiKey,
      });
    } catch (e) {
      throw Exception('Failed to delete inbox: $e');
    }
  }

  /// Get email history for current device
  Future<EmailHistoryResponse> getEmailHistory({int page = 1, int limit = 20}) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/history/$deviceId', queryParameters: {
        'key': apiKey,
        'page': page,
        'limit': limit,
      });
      
      return EmailHistoryResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to get email history: $e');
    }
  }

  /// Toggle star status for an email
  Future<void> toggleEmailStar(String email, bool isStarred) async {
    try {
      await _dio.put('/star/$email', 
        data: {'isStarred': isStarred},
        queryParameters: {'key': apiKey},
      );
    } catch (e) {
      throw Exception('Failed to toggle star: $e');
    }
  }

  /// Get starred emails for current device
  Future<List<HistoryEmailModel>> getStarredEmails() async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      final response = await _dio.get('/starred/$deviceId', queryParameters: {
        'key': apiKey,
      });
      
      final List<dynamic> data = response.data['emails'];
      return data.map((json) => HistoryEmailModel.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get starred emails: $e');
    }
  }

  /// Delete email from history
  Future<void> deleteEmailFromHistory(String email) async {
    final deviceId = await DeviceService.getDeviceId();
    
    try {
      await _dio.delete('/history/$email', queryParameters: {
        'key': apiKey,
        'deviceId': deviceId,
      });
    } catch (e) {
      throw Exception('Failed to delete email from history: $e');
    }
  }

  /// Get app update information
  Future<Map<String, dynamic>?> getAppUpdate() async {
    try {
      final response = await _adminDio.get('/api/app-update');
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] && data['update'] != null) {
          return data['update'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting app update: $e');
      return null;
    }
  }

  /// Get ads configuration
  Future<Map<String, dynamic>?> getAdsConfig() async {
    try {
      final response = await _adminDio.get('/api/ads-config');
      
      if (response.statusCode == 200) {
        return response.data;
      }
      return null;
    } catch (e) {
      print('Error getting ads config: $e');
      return null;
    }
  }
}

/// Model for email history response
class EmailHistoryResponse {
  final List<HistoryEmailModel> emails;
  final PaginationInfo pagination;

  EmailHistoryResponse({
    required this.emails,
    required this.pagination,
  });

  factory EmailHistoryResponse.fromJson(Map<String, dynamic> json) {
    return EmailHistoryResponse(
      emails: (json['emails'] as List)
          .map((e) => HistoryEmailModel.fromJson(e))
          .toList(),
      pagination: PaginationInfo.fromJson(json['pagination']),
    );
  }
}

/// Model for pagination information
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int pages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'],
      limit: json['limit'],
      total: json['total'],
      pages: json['pages'],
    );
  }
}

/// Model for history email entries
class HistoryEmailModel {
  final String id;
  final String email;
  final String deviceId;
  final String type;
  final bool isStarred;
  final DateTime createdAt;
  final DateTime lastUsed;
  final String? username;
  final String? domain;

  HistoryEmailModel({
    required this.id,
    required this.email,
    required this.deviceId,
    required this.type,
    required this.isStarred,
    required this.createdAt,
    required this.lastUsed,
    this.username,
    this.domain,
  });

  factory HistoryEmailModel.fromJson(Map<String, dynamic> json) {
    return HistoryEmailModel(
      id: json['_id'],
      email: json['email'],
      deviceId: json['deviceId'],
      type: json['type'],
      isStarred: json['isStarred'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      lastUsed: DateTime.parse(json['lastUsed']),
      username: json['username'],
      domain: json['domain'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'email': email,
      'deviceId': deviceId,
      'type': type,
      'isStarred': isStarred,
      'createdAt': createdAt.toIso8601String(),
      'lastUsed': lastUsed.toIso8601String(),
      'username': username,
      'domain': domain,
    };
  }
}
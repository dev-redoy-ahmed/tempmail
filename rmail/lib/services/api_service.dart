import 'dart:convert';
import 'package:http/http.dart' as http;
import 'device_service.dart';

class ApiService {
  static const String baseUrl = 'http://178.128.222.199:3001';
  static const String apiKey = 'supersecretapikey123';

  // Generate random email
  static Future<String?> generateRandomEmail() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/generate?key=$apiKey&deviceId=$deviceId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['email'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Generate custom email
  static Future<Map<String, dynamic>> generateCustomEmail(String username, String domain) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/generate/manual?key=$apiKey&username=$username&domain=$domain&deviceId=$deviceId'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'email': data['email']};
      } else if (response.statusCode == 409) {
        final data = json.decode(response.body);
        return {
          'success': false, 
          'error': data['error'],
          'message': data['message'],
          'email': data['email']
        };
      }
      return {'success': false, 'error': 'Unknown error'};
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  // Get inbox for email
  static Future<List<dynamic>?> getInbox(String email) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inbox/$email?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting inbox: $e');
    }
    return null;
  }

  // Get specific message
  static Future<Map<String, dynamic>?> getMessage(String email, int index) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/inbox/$email/$index?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('Error getting message: $e');
    }
    return null;
  }

  // Delete all messages
  static Future<bool> deleteAllMessages(String email) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$email?key=$apiKey'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting all messages: $e');
    }
    return false;
  }

  // Delete specific message
  static Future<bool> deleteMessage(String email, int index) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/delete/$email/$index?key=$apiKey'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting message: $e');
    }
    return false;
  }

  // Get available domains
  static Future<List<String>?> getDomains() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/domains?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<String>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // === DEVICE-BASED EMAIL MANAGEMENT ===

  // Get all emails for current device
  static Future<List<Map<String, dynamic>>?> getDeviceEmails() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/device/$deviceId/emails?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get generated emails for current device
  static Future<List<Map<String, dynamic>>?> getGeneratedEmails() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/device/$deviceId/generated?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get received emails for current device
  static Future<List<Map<String, dynamic>>?> getReceivedEmails() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/device/$deviceId/received?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get inbox for a specific email
  static Future<List<Map<String, dynamic>>?> getDeviceInbox(String email) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.get(
        Uri.parse('$baseUrl/device/$deviceId/inbox/$email?key=$apiKey'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear all emails for current device
  static Future<bool> clearDeviceEmails() async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.delete(
        Uri.parse('$baseUrl/device/$deviceId/clear?key=$apiKey'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Delete a specific email
  static Future<bool> deleteDeviceEmail(String emailId) async {
    try {
      final deviceId = await DeviceService.getDeviceId();
      final response = await http.delete(
        Uri.parse('$baseUrl/device/$deviceId/email/$emailId?key=$apiKey'),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
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

  // Note: Inbox and message management removed - emails are now real-time only via socket

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

  // Note: Device-based email management removed - emails are now real-time only via socket
}
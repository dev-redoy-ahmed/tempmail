import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../models/email_model.dart';
import '../services/api_service.dart';
// Note: device_service import removed - device functionality eliminated

class EmailProvider with ChangeNotifier {
  String? _currentEmail;
  List<EmailModel> _emails = [];
  List<String> _savedEmails = [];
  List<String> _availableDomains = [];
  // Note: Generated and received emails removed - now real-time only
  bool _isLoading = false;
  String? _error;
  IO.Socket? _socket;
  bool _isSocketConnected = false;

  // Getters
  String? get currentEmail => _currentEmail;
  List<EmailModel> get emails => _emails;
  List<String> get savedEmails => _savedEmails;
  List<String> get domains => _availableDomains;
  // Note: Generated and received emails getters removed
  bool get isSocketConnected => _isSocketConnected;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EmailProvider() {
    _initializeProvider();
    _initSocketConnection();
  }

  Future<void> _initializeProvider() async {
    await loadSavedEmails();
    await loadDomains();
    await loadGeneratedEmails();
    await loadReceivedEmails();
  }



  // Load saved emails from SharedPreferences
  Future<void> _loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _savedEmails = prefs.getStringList('saved_emails') ?? [];
      _currentEmail = prefs.getString('current_email');
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved emails';
      notifyListeners();
    }
  }

  // Save email to SharedPreferences
  Future<void> _saveEmailToPrefs(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!_savedEmails.contains(email)) {
        _savedEmails.add(email);
        await prefs.setStringList('saved_emails', _savedEmails);
      }
      await prefs.setString('current_email', email);
    } catch (e) {
      _error = 'Failed to save email';
      notifyListeners();
    }
  }

  // Load available domains
  Future<void> _loadDomains() async {
    try {
      final domains = await ApiService.getDomains();
      _availableDomains = domains ?? [];
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load domains';
      notifyListeners();
    }
  }

  // Load available domains (public method)
  Future<void> loadDomains() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final domains = await ApiService.getDomains();
      _availableDomains = domains ?? [];
      _error = null;
    } catch (e) {
      _error = 'Failed to load domains: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Alias for loadDomains
  Future<void> loadAvailableDomains() async {
    await loadDomains();
  }

  // Load saved emails from storage
  Future<void> loadSavedEmails() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedEmailsJson = prefs.getStringList('saved_emails') ?? [];
      _savedEmails = savedEmailsJson;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load saved emails: $e';
      notifyListeners();
    }
  }

  // Generate random email
  Future<void> generateRandomEmail() async {
    _setLoading(true);
    _clearError();
    
    try {
      final email = await ApiService.generateRandomEmail();
      if (email != null) {
        _currentEmail = email;
        await _saveEmailToPrefs(_currentEmail!);
        // Note: Email loading removed - emails are now real-time via socket
      } else {
        _error = 'Failed to generate email';
      }
    } catch (e) {
      _error = 'Error generating email: $e';
    }
    
    _setLoading(false);
  }

  Future<Map<String, dynamic>> generateCustomEmail(String username, String domain) async {
    _setLoading(true);
    _clearError();
    
    try {
      final result = await ApiService.generateCustomEmail(username, domain);
      if (result['success'] == true) {
        _currentEmail = result['email'];
        await _saveEmailToPrefs(_currentEmail!);
        await loadGeneratedEmails(); // Refresh generated emails list
        await refreshInbox();
        _setLoading(false);
        return {'success': true, 'email': result['email']};
      } else {
        _error = result['message'] ?? result['error'] ?? 'Failed to generate custom email';
        _setLoading(false);
        return {
          'success': false, 
          'error': result['error'],
          'message': result['message'],
          'email': result['email']
        };
      }
    } catch (e) {
      _error = 'Error: $e';
      _setLoading(false);
      return {'success': false, 'error': 'Network error: $e'};
    }
  }



  // Set current email
  Future<void> setCurrentEmail(String email) async {
    _currentEmail = email;
    await _saveEmailToPrefs(email);
    // Note: Inbox refresh removed - emails are now real-time via socket
  }

  // Note: Database operations removed - emails are now real-time only via socket
  
  // Clear emails from memory (local only)
  void clearEmails() {
    _emails = [];
    notifyListeners();
  }
  
  // Remove email from memory (local only)
  void removeEmail(int index) {
    if (index >= 0 && index < _emails.length) {
      _emails.removeAt(index);
      notifyListeners();
    }
  }

  // Remove saved email
  Future<void> removeSavedEmail(String email) async {
    try {
      _savedEmails.remove(email);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('saved_emails', _savedEmails);
      
      if (_currentEmail == email) {
        _currentEmail = null;
        _emails = [];
        await prefs.remove('current_email');
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to remove email';
      notifyListeners();
    }
  }

  // Clear all data
  Future<void> clearAllData() async {
    try {
      _savedEmails.clear();
      _currentEmail = null;
      _emails.clear();
      // Note: Generated and received emails clearing removed
      _error = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_emails');
      await prefs.remove('current_email');
      
      // Note: Device email clearing removed - emails are now real-time only
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear data';
      notifyListeners();
    }
  }

  // Note: Device-based email management removed - emails are now real-time only via socket

  // Get email statistics
  Map<String, int> getEmailStats() {
    return {
      'current_emails': _emails.length,
      'saved_emails': _savedEmails.length,
      'total': _emails.length,
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Initialize Socket.IO connection
  void _initSocketConnection() {
    try {
      _socket = IO.io('http://178.128.222.199:3001', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false,
      });

      _socket!.connect();

      _socket!.onConnect((_) {
        print('Socket.IO connected');
        _isSocketConnected = true;
        notifyListeners();
      });

      _socket!.onDisconnect((_) {
        print('Socket.IO disconnected');
        _isSocketConnected = false;
        notifyListeners();
      });

      _socket!.on('new_mail', (data) {
        print('New mail received: $data');
        _handleNewMail(data);
      });

      _socket!.onError((error) {
        print('Socket.IO error: $error');
      });
    } catch (e) {
      print('Socket.IO initialization error: $e');
    }
  }

  // Handle new mail from Socket.IO
  void _handleNewMail(dynamic mailData) {
    try {
      if (_currentEmail != null && mailData != null) {
        // Check if this email is for current user
        final toEmail = mailData['to'];
        if (toEmail != null && toEmail.toString().contains(_currentEmail!)) {
          final newEmail = EmailModel.fromJson(mailData);
          _emails.insert(0, newEmail);
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling new mail: $e');
    }
  }

  // Disconnect Socket.IO
  void _disconnectSocket() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
      _isSocketConnected = false;
    }
  }

  @override
  void dispose() {
    _disconnectSocket();
    super.dispose();
  }
}
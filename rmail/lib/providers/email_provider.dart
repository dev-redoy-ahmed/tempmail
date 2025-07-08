import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/email_model.dart';
import '../services/api_service.dart';
import '../services/device_service.dart';

class EmailProvider with ChangeNotifier {
  String? _currentEmail;
  List<EmailModel> _emails = [];
  List<String> _savedEmails = [];
  List<String> _availableDomains = [];
  List<Map<String, dynamic>> _generatedEmails = [];
  List<Map<String, dynamic>> _receivedEmails = [];
  String? _deviceId;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get currentEmail => _currentEmail;
  List<EmailModel> get emails => _emails;
  List<String> get savedEmails => _savedEmails;
  List<String> get domains => _availableDomains;
  List<Map<String, dynamic>> get generatedEmails => _generatedEmails;
  List<Map<String, dynamic>> get receivedEmails => _receivedEmails;
  String? get deviceId => _deviceId;
  bool get isLoading => _isLoading;
  String? get error => _error;

  EmailProvider() {
    _initializeProvider();
  }

  Future<void> _initializeProvider() async {
    await _loadDeviceId();
    await loadSavedEmails();
    await loadDomains();
    await loadGeneratedEmails();
    await loadReceivedEmails();
  }

  Future<void> _loadDeviceId() async {
    try {
      _deviceId = await DeviceService.getDeviceId();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to get device ID: $e';
      notifyListeners();
    }
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
        await loadGeneratedEmails(); // Refresh generated emails list
        await refreshInbox();
      } else {
        _error = 'Failed to generate email';
      }
    } catch (e) {
      _error = 'Error generating email: $e';
    }
    
    _setLoading(false);
  }

  Future<void> generateCustomEmail(String username, String domain) async {
    _setLoading(true);
    _clearError();
    
    try {
      final email = await ApiService.generateCustomEmail(username, domain);
      if (email != null) {
        _currentEmail = email;
        await _saveEmailToPrefs(_currentEmail!);
        await loadGeneratedEmails(); // Refresh generated emails list
        await refreshInbox();
      } else {
        _error = 'Failed to generate custom email';
      }
    } catch (e) {
      _error = 'Error: $e';
    }
    
    _setLoading(false);
  }



  // Set current email
  Future<void> setCurrentEmail(String email) async {
    _currentEmail = email;
    await _saveEmailToPrefs(email);
    await refreshInbox();
  }

  // Refresh inbox
  Future<void> refreshInbox() async {
    if (_currentEmail == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final emailsData = await ApiService.getInbox(_currentEmail!);
      if (emailsData != null) {
        _emails = emailsData.map((e) => EmailModel.fromJson(e)).toList();
      } else {
        _emails = [];
      }
    } catch (e) {
      _error = 'Error refreshing inbox: $e';
      _emails = [];
    }
    
    _setLoading(false);
  }

  // Delete all messages
  Future<void> deleteAllMessages() async {
    if (_currentEmail == null) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final success = await ApiService.deleteAllMessages(_currentEmail!);
      if (success) {
        _emails = [];
      } else {
        _error = 'Failed to delete messages';
      }
    } catch (e) {
      _error = 'Error deleting messages: $e';
    }
    
    _setLoading(false);
  }

  // Delete specific message
  Future<void> deleteMessage(int index) async {
    if (_currentEmail == null || index >= _emails.length) return;
    
    _setLoading(true);
    _clearError();
    
    try {
      final success = await ApiService.deleteMessage(_currentEmail!, index);
      if (success) {
        await refreshInbox();
      } else {
        _error = 'Failed to delete message';
      }
    } catch (e) {
      _error = 'Error deleting message: $e';
    }
    
    _setLoading(false);
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
      _generatedEmails.clear();
      _receivedEmails.clear();
      _error = null;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_emails');
      await prefs.remove('current_email');
      
      // Also clear device emails from server
      await ApiService.clearDeviceEmails();
      
      notifyListeners();
    } catch (e) {
      _error = 'Failed to clear data';
      notifyListeners();
    }
  }

  // === DEVICE-BASED EMAIL MANAGEMENT ===

  Future<void> loadGeneratedEmails() async {
    try {
      final emails = await ApiService.getGeneratedEmails();
      if (emails != null) {
        _generatedEmails = emails;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load generated emails: $e';
      notifyListeners();
    }
  }

  Future<void> loadReceivedEmails() async {
    try {
      final emails = await ApiService.getReceivedEmails();
      if (emails != null) {
        _receivedEmails = emails;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Failed to load received emails: $e';
      notifyListeners();
    }
  }

  Future<void> loadDeviceInbox(String email) async {
    _setLoading(true);
    try {
      final inbox = await ApiService.getDeviceInbox(email);
      if (inbox != null) {
        // Convert to EmailModel format
        _emails = inbox.map((emailData) => EmailModel(
          id: emailData['_id'] ?? '',
          from: emailData['from'] ?? '',
          to: emailData['to'] ?? '',
          subject: emailData['subject'] ?? '(no subject)',
          body: emailData['body'] ?? '',
          date: emailData['receivedAt'] ?? '',
        )).toList();
        clearError();
      } else {
        _error = 'Failed to load inbox';
      }
    } catch (e) {
      _error = 'Error loading inbox: $e';
    }
    _setLoading(false);
  }

  Future<void> deleteDeviceEmail(String emailId) async {
    try {
      final success = await ApiService.deleteDeviceEmail(emailId);
      if (success) {
        await loadGeneratedEmails();
        await loadReceivedEmails();
        clearError();
      } else {
        _error = 'Failed to delete email';
      }
    } catch (e) {
      _error = 'Error deleting email: $e';
    }
    notifyListeners();
  }

  Future<void> refreshDeviceEmails() async {
    await loadGeneratedEmails();
    await loadReceivedEmails();
  }

  // Switch to a generated email
  Future<void> switchToEmail(String email) async {
    _currentEmail = email;
    await _saveEmailToPrefs(email);
    await loadDeviceInbox(email);
    notifyListeners();
  }

  // Get email statistics
  Map<String, int> getEmailStats() {
    return {
      'generated': _generatedEmails.length,
      'received': _receivedEmails.length,
      'total': _generatedEmails.length + _receivedEmails.length,
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
}
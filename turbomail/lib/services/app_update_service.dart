import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateService {
  static const String _baseUrl = 'http://165.22.109.153:3003'; // Production server URL
  
  static AppUpdateService? _instance;
  static AppUpdateService get instance => _instance ??= AppUpdateService._();
  
  AppUpdateService._();
  
  // App update model
  class AppUpdate {
    final String versionName;
    final int versionCode;
    final bool isForceUpdate;
    final bool isNormalUpdate;
    final bool isActive;
    final String? updateMessage;
    final String? updateLink;
    final DateTime createdAt;
    final DateTime updatedAt;
    
    AppUpdate({
      required this.versionName,
      required this.versionCode,
      required this.isForceUpdate,
      required this.isNormalUpdate,
      required this.isActive,
      this.updateMessage,
      this.updateLink,
      required this.createdAt,
      required this.updatedAt,
    });
    
    factory AppUpdate.fromJson(Map<String, dynamic> json) {
      return AppUpdate(
        versionName: json['versionName'] ?? '',
        versionCode: json['versionCode'] ?? 0,
        isForceUpdate: json['isForceUpdate'] ?? false,
        isNormalUpdate: json['isNormalUpdate'] ?? false,
        isActive: json['isActive'] ?? false,
        updateMessage: json['updateMessage'],
        updateLink: json['updateLink'],
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
      );
    }
  }
  
  // Check for app updates
  Future<AppUpdate?> checkForUpdates() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/app-update'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] && data['update'] != null) {
          return AppUpdate.fromJson(data['update']);
        }
      }
      return null;
    } catch (e) {
      print('Error checking for updates: $e');
      return null;
    }
  }
  
  // Get current app version
  Future<Map<String, dynamic>> getCurrentAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return {
        'versionName': packageInfo.version,
        'versionCode': int.tryParse(packageInfo.buildNumber) ?? 1,
        'appName': packageInfo.appName,
        'packageName': packageInfo.packageName,
      };
    } catch (e) {
      print('Error getting app version: $e');
      return {
        'versionName': '1.0.0',
        'versionCode': 1,
        'appName': 'TurboMail',
        'packageName': 'com.turbomail.app',
      };
    }
  }
  
  // Compare versions
  bool isUpdateAvailable(String currentVersion, String serverVersion) {
    try {
      final currentParts = currentVersion.split('.').map(int.parse).toList();
      final serverParts = serverVersion.split('.').map(int.parse).toList();
      
      // Ensure both versions have the same number of parts
      while (currentParts.length < 3) currentParts.add(0);
      while (serverParts.length < 3) serverParts.add(0);
      
      for (int i = 0; i < 3; i++) {
        if (serverParts[i] > currentParts[i]) return true;
        if (serverParts[i] < currentParts[i]) return false;
      }
      return false;
    } catch (e) {
      print('Error comparing versions: $e');
      return false;
    }
  }
  
  // Show update dialog
  Future<void> showUpdateDialog(BuildContext context, AppUpdate update) async {
    final currentVersion = await getCurrentAppVersion();
    final isUpdateNeeded = isUpdateAvailable(
      currentVersion['versionName'],
      update.versionName,
    ) || currentVersion['versionCode'] < update.versionCode;
    
    if (!isUpdateNeeded) return;
    
    if (!context.mounted) return;
    
    if (update.isForceUpdate) {
      _showForceUpdateDialog(context, update);
    } else if (update.isNormalUpdate) {
      _showNormalUpdateDialog(context, update);
    }
  }
  
  // Force update dialog
  void _showForceUpdateDialog(BuildContext context, AppUpdate update) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: AlertDialog(
            title: Row(
              children: [
                Icon(Icons.system_update, color: Colors.red, size: 28),
                SizedBox(width: 10),
                Text('Update Required'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A new version (${update.versionName}) is available.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                if (update.updateMessage != null && update.updateMessage!.isNotEmpty)
                  Text(update.updateMessage!),
                SizedBox(height: 10),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This update is required to continue using the app.',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton.icon(
                onPressed: () => _launchUpdateUrl(update.updateLink),
                icon: Icon(Icons.download),
                label: Text('Update Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  // Normal update dialog
  void _showNormalUpdateDialog(BuildContext context, AppUpdate update) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.system_update, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Text('Update Available'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A new version (${update.versionName}) is available.',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              if (update.updateMessage != null && update.updateMessage!.isNotEmpty)
                Text(update.updateMessage!),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Update now to get the latest features and improvements.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Later'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _launchUpdateUrl(update.updateLink);
              },
              icon: Icon(Icons.download),
              label: Text('Update'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }
  
  // Launch update URL
  Future<void> _launchUpdateUrl(String? updateUrl) async {
    if (updateUrl == null || updateUrl.isEmpty) {
      // Default to Play Store if no URL provided
      updateUrl = 'https://play.google.com/store/apps/details?id=com.turbomail.app';
    }
    
    try {
      final uri = Uri.parse(updateUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Could not launch update URL: $updateUrl');
      }
    } catch (e) {
      print('Error launching update URL: $e');
    }
  }
  
  // Check and show update if available
  Future<void> checkAndShowUpdate(BuildContext context) async {
    try {
      final update = await checkForUpdates();
      if (update != null && update.isActive && context.mounted) {
        await showUpdateDialog(context, update);
      }
    } catch (e) {
      print('Error in checkAndShowUpdate: $e');
    }
  }
  
  // Initialize update check (call this in main.dart)
  static Future<void> initialize(BuildContext context) async {
    try {
      // Wait a bit for the app to fully load
      await Future.delayed(Duration(seconds: 2));
      
      if (context.mounted) {
        await AppUpdateService.instance.checkAndShowUpdate(context);
      }
    } catch (e) {
      print('Error initializing app update service: $e');
    }
  }
}
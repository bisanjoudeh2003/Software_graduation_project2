import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class NotificationService {
  static String get baseUrl => "${AuthService.apiBase}/notifications";

  static Map<String, dynamic> _decode(String rawBody) {
    if (rawBody.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(rawBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        "success": false,
        "message": "Unexpected response format",
        "data": decoded,
      };
    } catch (e) {
      debugPrint("NOTIFICATION DECODE ERROR: $e");

      return {
        "success": false,
        "message": "Failed to decode server response",
      };
    }
  }

  static Future<Map<String, String>?> _headers() async {
    final token = await AuthService.getToken();

    if (token == null) {
      debugPrint("NOTIFICATION SERVICE: no auth token");
      return null;
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Future<Map<String, dynamic>?> getMyNotifications() async {
    try {
      final headers = await _headers();
      if (headers == null) return null;

      final response = await http.get(
        Uri.parse(baseUrl),
        headers: headers,
      );

      debugPrint("GET NOTIFICATIONS STATUS: ${response.statusCode}");
      debugPrint("GET NOTIFICATIONS BODY: ${response.body}");

      final body = _decode(response.body);

      if (response.statusCode == 200) {
        return body;
      }

      return null;
    } catch (e) {
      debugPrint("GET NOTIFICATIONS ERROR: $e");
      return null;
    }
  }

  static Future<int> getUnreadCount() async {
    final data = await getMyNotifications();

    if (data == null) return 0;

    return int.tryParse(data["unread_count"]?.toString() ?? "0") ?? 0;
  }

  static Future<bool> markAsRead(int notificationId) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      final response = await http.patch(
        Uri.parse("$baseUrl/$notificationId/read"),
        headers: headers,
      );

      debugPrint("MARK AS READ STATUS: ${response.statusCode}");
      debugPrint("MARK AS READ BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("MARK AS READ ERROR: $e");
      return false;
    }
  }

  static Future<bool> markAllAsRead() async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      final response = await http.patch(
        Uri.parse("$baseUrl/read-all"),
        headers: headers,
      );

      debugPrint("MARK ALL AS READ STATUS: ${response.statusCode}");
      debugPrint("MARK ALL AS READ BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("MARK ALL AS READ ERROR: $e");
      return false;
    }
  }

  static Future<bool> saveFcmToken({
    required String fcmToken,
    String deviceType = "android",
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      if (fcmToken.trim().isEmpty) {
        debugPrint("SAVE FCM TOKEN ERROR: token is empty");
        return false;
      }

      final response = await http.post(
        Uri.parse("$baseUrl/fcm-token"),
        headers: headers,
        body: jsonEncode({
          "fcm_token": fcmToken,
          "device_type": deviceType,
        }),
      );

      debugPrint("SAVE FCM TOKEN STATUS: ${response.statusCode}");
      debugPrint("SAVE FCM TOKEN BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("SAVE FCM TOKEN ERROR: $e");
      return false;
    }
  }

  static Future<bool> deleteFcmToken({
    required String fcmToken,
  }) async {
    try {
      final headers = await _headers();
      if (headers == null) return false;

      if (fcmToken.trim().isEmpty) {
        debugPrint("DELETE FCM TOKEN ERROR: token is empty");
        return false;
      }

      final response = await http.delete(
        Uri.parse("$baseUrl/fcm-token"),
        headers: headers,
        body: jsonEncode({
          "fcm_token": fcmToken,
        }),
      );

      debugPrint("DELETE FCM TOKEN STATUS: ${response.statusCode}");
      debugPrint("DELETE FCM TOKEN BODY: ${response.body}");

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("DELETE FCM TOKEN ERROR: $e");
      return false;
    }
  }
}
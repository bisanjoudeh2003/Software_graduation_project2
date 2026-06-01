import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AdminBookingService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api";
    }

    return "http://10.0.2.2:3000/api";
  }

  static String get adminBookingsUrl => "$baseUrl/admin/bookings";

  static Future<List<dynamic>> getPhotographerBookings({
    String status = "all",
    String dateFilter = "all",
    String search = "",
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("You are not logged in.");
    }

    final uri = Uri.parse("$adminBookingsUrl/photographer").replace(
      queryParameters: {
        "status": status,
        "dateFilter": dateFilter,
        "search": search,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      return body["bookings"] ?? [];
    }

    throw Exception(body["message"] ?? "Failed to load photographer bookings.");
  }

  static Future<List<dynamic>> getVenueBookings({
    String status = "all",
    String dateFilter = "all",
    String search = "",
  }) async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("You are not logged in.");
    }

    final uri = Uri.parse("$adminBookingsUrl/venues").replace(
      queryParameters: {
        "status": status,
        "dateFilter": dateFilter,
        "search": search,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    final body = jsonDecode(response.body);

    if (response.statusCode == 200 && body["success"] == true) {
      return body["bookings"] ?? [];
    }

    throw Exception(body["message"] ?? "Failed to load venue bookings.");
  }

  static Future<Map<String, dynamic>> cancelPhotographerBooking({
  required int bookingId,
  required String reason,
}) async {
  final token = await AuthService.getToken();

  if (token == null) {
    throw Exception("You are not logged in.");
  }

  final response = await http.patch(
    Uri.parse("$adminBookingsUrl/photographer/$bookingId/cancel"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "reason": reason.trim(),
    }),
  );

  final body = jsonDecode(response.body);

  if (response.statusCode == 200 && body["success"] == true) {
    return Map<String, dynamic>.from(body);
  }

  throw Exception(body["message"] ?? "Failed to cancel photographer booking.");
}

static Future<Map<String, dynamic>> cancelVenueBooking({
  required int bookingId,
  required String reason,
}) async {
  final token = await AuthService.getToken();

  if (token == null) {
    throw Exception("You are not logged in.");
  }

  final response = await http.patch(
    Uri.parse("$adminBookingsUrl/venues/$bookingId/cancel"),
    headers: {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    },
    body: jsonEncode({
      "reason": reason.trim(),
    }),
  );

  final body = jsonDecode(response.body);

  if (response.statusCode == 200 && body["success"] == true) {
    return Map<String, dynamic>.from(body);
  }

  throw Exception(body["message"] ?? "Failed to cancel venue booking.");
}
}
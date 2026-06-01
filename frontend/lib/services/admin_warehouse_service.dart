import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'auth_service.dart';

class AdminWarehouseService {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://localhost:3000/api";
    }

    return "http://10.0.2.2:3000/api";
  }

  static String get adminWarehouseUrl => "$baseUrl/admin/warehouse";

  static Future<Map<String, String>> _headers() async {
    final token = await AuthService.getToken();

    if (token == null) {
      throw Exception("User not authenticated");
    }

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }

  static Map<String, dynamic> _decodeResponse(
    http.Response response,
    String url,
  ) {
    debugPrint("ADMIN WAREHOUSE URL: $url");
    debugPrint("ADMIN WAREHOUSE STATUS: ${response.statusCode}");
    debugPrint("ADMIN WAREHOUSE BODY: ${response.body}");

    final rawBody = response.body.trim();

    if (rawBody.isEmpty) {
      return {};
    }

    if (rawBody.startsWith("<!DOCTYPE html") || rawBody.startsWith("<html")) {
      throw Exception(
        "The server returned HTML instead of JSON. Check this API URL: $url",
      );
    }

    try {
      final decoded = jsonDecode(rawBody);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        "success": false,
        "message": "Unexpected response format from server",
        "data": decoded,
      };
    } catch (_) {
      throw Exception("Failed to read server response as JSON. URL: $url");
    }
  }

  static Future<Map<String, dynamic>> getOverview() async {
    final url = "$adminWarehouseUrl/overview";

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body["stats"] ?? {});
    }

    throw Exception(body["message"] ?? "Failed to load warehouse overview");
  }

  static Future<List<dynamic>> getProducts({
    String? status,
    String? visibility,
    bool? flagged,
    String? stock,
  }) async {
    final query = <String, String>{};

    if (status != null && status.trim().isNotEmpty) {
      query["status"] = status.trim();
    }

    if (visibility != null && visibility.trim().isNotEmpty) {
      query["visibility"] = visibility.trim();
    }

    if (flagged != null) {
      query["flagged"] = flagged ? "1" : "0";
    }

    if (stock != null && stock.trim().isNotEmpty) {
      query["stock"] = stock.trim();
    }

    final uri = Uri.parse("$adminWarehouseUrl/products").replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final url = uri.toString();

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body["products"] ?? [];
    }

    throw Exception(body["message"] ?? "Failed to load warehouse products");
  }

  static Future<Map<String, dynamic>> getProductDetails(int productId) async {
    final url = "$adminWarehouseUrl/products/$productId/details";

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body["product"] ?? {});
    }

    throw Exception(
      body["message"] ?? "Failed to load warehouse product details",
    );
  }

  static Future<Map<String, dynamic>> approveProduct(int productId) async {
    final url = "$adminWarehouseUrl/products/$productId/approve";

    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body["message"] ?? "Failed to approve product");
  }

  static Future<Map<String, dynamic>> updateProductVisibility({
    required int productId,
    required String adminVisibility,
  }) async {
    final url = "$adminWarehouseUrl/products/$productId/visibility";

    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode({
        "admin_visibility": adminVisibility,
      }),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body["message"] ?? "Failed to update product visibility");
  }

  static Future<Map<String, dynamic>> flagProduct({
    required int productId,
    required bool flagged,
    String? reason,
  }) async {
    final url = "$adminWarehouseUrl/products/$productId/flag";

    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode({
        "product_flagged": flagged,
        "product_flag_reason": reason,
      }),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body["message"] ?? "Failed to update product flag");
  }

  static Future<List<dynamic>> getOrders({
    String? status,
    String? paymentStatus,
  }) async {
    final query = <String, String>{};

    if (status != null && status.trim().isNotEmpty) {
      query["status"] = status.trim();
    }

    if (paymentStatus != null && paymentStatus.trim().isNotEmpty) {
      query["payment_status"] = paymentStatus.trim();
    }

    final uri = Uri.parse("$adminWarehouseUrl/orders").replace(
      queryParameters: query.isEmpty ? null : query,
    );

    final url = uri.toString();

    final response = await http.get(
      uri,
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body["orders"] ?? [];
    }

    throw Exception(body["message"] ?? "Failed to load warehouse orders");
  }

  static Future<Map<String, dynamic>> getOrderDetails(int orderId) async {
    final url = "$adminWarehouseUrl/orders/$orderId/details";

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(body["order"] ?? {});
    }

    throw Exception(body["message"] ?? "Failed to load warehouse order details");
  }

  static Future<Map<String, dynamic>> updateOrderStatus({
    required int orderId,
    required String status,
    String? adminNote,
  }) async {
    final url = "$adminWarehouseUrl/orders/$orderId/status";

    final response = await http.put(
      Uri.parse(url),
      headers: await _headers(),
      body: jsonEncode({
        "status": status,
        "admin_note": adminNote,
      }),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body;
    }

    throw Exception(body["message"] ?? "Failed to update order status");
  }

  static Future<List<dynamic>> getWarehouseOwners() async {
    final url = "$adminWarehouseUrl/owners";

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    final body = _decodeResponse(response, url);

    if (response.statusCode == 200) {
      return body["owners"] ?? [];
    }

    throw Exception(body["message"] ?? "Failed to load warehouse owners");
  }
}
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // 🔧 BusMate Backend URL
  // ✅ USB debugging (adb reverse tcp:4000 tcp:4000): http://127.0.0.1:4000
  // ⚠️ Android Emulator: http://10.0.2.2:4000
  // ⚠️ Physical device via LAN: http://YOUR_PC_IP:4000
  static const String baseUrl = "http://127.0.0.1:4000";

  // Register endpoint
  static Future<Map<String, dynamic>> registerDriver({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String nic,
    required String licenseNumber,
    required String licenseExpiry,
    required String busNumber,
    String? driverPhotoUrl,
    String? licensePhotoUrl,
    String? busType,
    String? depotName,
    String? conductorName,
    String? conductorNic,
    String? conductorPhone,
    String? conductorPhotoUrl,
    String? routeNumber,
    String? routeName,
    String? tripsJson,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/drivers/register"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "name": name,
              "email": email,
              "phone": phone,
              "password": password,
              "nic": nic,
              "driver_photo_url": driverPhotoUrl,
              "license_number": licenseNumber,
              "license_expiry": licenseExpiry,
              "license_photo_url": licensePhotoUrl,
              "bus_number": busNumber,
              "bus_type": busType,
              "depot_name": depotName,
              "conductor_name": conductorName,
              "conductor_nic": conductorNic,
              "conductor_phone": conductorPhone,
              "conductor_photo_url": conductorPhotoUrl,
              "route_number": routeNumber,
              "route_name": routeName,
              // trips_json: if provided, attempt to parse JSON string to native structure
              "trips_json": (tripsJson != null && tripsJson.trim().isNotEmpty)
                  ? (() {
                      try {
                        return jsonDecode(tripsJson);
                      } catch (_) {
                        return null;
                      }
                    })()
                  : null,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception(
              "Connection timeout. Check your backend server.",
            ),
          );

      print("📤 API Response Status: ${response.statusCode}");
      print("📤 API Response Body: ${response.body}");

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data["message"] ?? "Registration successful",
          "data": data["data"],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          "success": false,
          "message":
              error["error"] ?? error["message"] ?? "Registration failed",
          "error": error,
        };
      }
    } catch (e) {
      print("❌ API Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // Login endpoint
  static Future<Map<String, dynamic>> loginDriver({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/api/drivers/login"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          "success": true,
          "message": data["message"] ?? "Login successful",
          "token": data["token"],
          "driver": data["driver"],
        };
      } else {
        final error = jsonDecode(response.body);
        return {
          "success": false,
          "message": error["message"] ?? "Login failed",
        };
      }
    } catch (e) {
      print("❌ Login API Error: $e");
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // Update driver profile
  static Future<Map<String, dynamic>> updateDriver({
    required String driverId,
    required String token,
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse("$baseUrl/api/drivers/$driverId"),
            headers: {
              "Content-Type": "application/json",
              "Authorization": "Bearer $token",
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {
          "success": false,
          "message": jsonDecode(response.body)["message"],
        };
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }

  // Get driver profile
  static Future<Map<String, dynamic>> getDriver({
    required String driverId,
    required String token,
  }) async {
    try {
      final response = await http
          .get(
            Uri.parse("$baseUrl/api/drivers/$driverId"),
            headers: {"Authorization": "Bearer $token"},
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        return {"success": true, "data": jsonDecode(response.body)};
      } else {
        return {"success": false, "message": "Failed to fetch driver"};
      }
    } catch (e) {
      return {"success": false, "message": "Network error: $e"};
    }
  }
}

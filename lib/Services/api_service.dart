import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'token_storage.dart';

class ApiService {
  // 🔧 BusMate Backend URL (Dynamic)
  static String baseUrl = "http://192.168.8.101:4000";

  /// Initialize the API service by loading the saved URL or attempting discovery.
  static Future<void> init() async {
    final saved = await TokenStorage.getServerUrl();
    if (saved != null && saved.isNotEmpty) {
      baseUrl = saved;
      print("🚀 Loaded saved server URL: $baseUrl");
    } else {
      print("📡 No saved server URL, starting auto-discovery...");
      autoDiscover(); // Run in background
    }
  }

  /// Listens for a UDP broadcast from the backend on port 4001.
  static void autoDiscover() async {
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 4001);
      socket.listen((RawSocketEvent event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram == null) return;

          final message = utf8.decode(datagram.data);
          final data = jsonDecode(message);

          if (data['service'] == 'busmate-backend') {
            final newUrl = "http://${datagram.address.address}:${data['port']}";
            if (baseUrl != newUrl) {
              baseUrl = newUrl;
              TokenStorage.saveServerUrl(baseUrl);
              print("✅ Server discovered at: $baseUrl");
            }
            socket.close();
          }
        }
      });
    } catch (e) {
      print("❌ UDP Discovery failed: $e");
    }
  }

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

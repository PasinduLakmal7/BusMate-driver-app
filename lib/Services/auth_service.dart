import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../View/Auth/login.dart';
import '../View/home_screen.dart';
import 'token_storage.dart';

class AuthService {
  // Firebase still used for registration photo upload & Firestore driver data.
  // ⚠️ Login auth is 100% backend OTP — Firebase is NOT used for login.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static const _backendBase = 'http://10.0.2.2:4000';

  void showMsg(BuildContext context, String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  /// ✅ verify name + phone exists in Firestore before sending OTP
  Future<bool> verifyDriverNameAndPhone({
    required String name,
    required String phone,
  }) async {
    // Prefer backend drivers table check (not Firestore)
    try {
      debugPrint("VERIFY(backend): name=$name phone=$phone");
      final uri = Uri.parse('http://10.0.2.2:4000/drivers/check');
      final resp = await http
          .post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"name": name, "phone": phone}),
          )
          .timeout(const Duration(seconds: 20));

      if (resp.statusCode != 200) {
        debugPrint('VERIFY backend non-200: ${resp.statusCode} ${resp.body}');
        return false;
      }

      final data = jsonDecode(resp.body);
      final ok = data['success'] == true && data['exists'] == true;
      debugPrint('VERIFY backend result: $ok');
      return ok;
    } catch (e) {
      debugPrint('VERIFY backend error: $e');
      return false;
    }
  }

  /// Step 1: Send OTP to the phone number (REGISTER FLOW)
  Future<void> registerDriver({
    required String name,
    required String nic,
    required String email,
    required String password,
    required DateTime birth,
    required File driverPhoto,
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required DateTime licenseExpiry,
    required File licensePhoto,
    required String conductorName,
    required String conductorPhone,
    required File conductorPhoto,
    required String busNo,
    required String routeNo,
    required String routeName,
    required String depot,
    required int tripsPerDay,
    required List<Map<String, dynamic>>
    trips, // direction, startTime, arrivalTime
    required BuildContext context,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Optional: auto login if OTP is detected automatically
          await _auth.signInWithCredential(credential);

          await _saveDriverData(
            context: context,
            name: name,
            nic: nic,
            email: email,
            password: password,
            birth: birth,
            driverPhoto: driverPhoto,
            phone: phone,
            vehicleType: vehicleType,
            vehicleNum: vehicleNum,
            licenseNum: licenseNum,
            licenseExpiry: licenseExpiry,
            licensePhoto: licensePhoto,
            conductorName: conductorName,
            conductorPhone: conductorPhone,
            conductorPhoto: conductorPhoto,
            busNo: busNo,
            routeNo: routeNo,
            routeName: routeName,
            depot: depot,
            tripsPerDay: tripsPerDay,
            trips: trips,
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          showMsg(
            context,
            e.message ?? "Phone verification failed",
            isError: true,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      showMsg(context, "Error: $e", isError: true);
    }
  }

  /// Step 2: Verify OTP and save driver data (REGISTER FLOW)
  Future<void> verifyOtpAndSaveDriver({
    required String verificationId,
    required String otp,
    required String name,
    required String nic,
    required String email,
    required String password,
    required DateTime birth,
    required File driverPhoto,
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required DateTime licenseExpiry,
    required File licensePhoto,
    required String conductorName,
    required String conductorPhone,
    required File conductorPhoto,
    required String busNo,
    required String routeNo,
    required String routeName,
    required String depot,
    required int tripsPerDay,
    required List<Map<String, dynamic>> trips,
    required BuildContext context,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      await _saveDriverData(
        context: context,
        name: name,
        nic: nic,
        email: email,
        password: password,
        birth: birth,
        driverPhoto: driverPhoto,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNum: vehicleNum,
        licenseNum: licenseNum,
        licenseExpiry: licenseExpiry,
        licensePhoto: licensePhoto,
        conductorName: conductorName,
        conductorPhone: conductorPhone,
        conductorPhoto: conductorPhoto,
        busNo: busNo,
        routeNo: routeNo,
        routeName: routeName,
        depot: depot,
        tripsPerDay: tripsPerDay,
        trips: trips,
      );
    } on FirebaseAuthException catch (e) {
      showMsg(context, e.message ?? "Invalid OTP", isError: true);
    }
  }

  /// Upload images and save driver data to Firestore (REGISTER FLOW)
  Future<void> _saveDriverData({
    required BuildContext context,
    required String name,
    required String nic,
    required String email,
    required String password,
    required DateTime birth,
    required File driverPhoto,
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required DateTime licenseExpiry,
    required File licensePhoto,
    required String conductorName,
    required String conductorPhone,
    required File conductorPhoto,
    required String busNo,
    required String routeNo,
    required String routeName,
    required String depot,
    required int tripsPerDay,
    required List<Map<String, dynamic>> trips,
  }) async {
    try {
      String uid = _auth.currentUser!.uid;

      // Upload images
      final driverPhotoUrl =
          await (await _storage
                  .ref('drivers/$uid/driverPhoto.jpg')
                  .putFile(driverPhoto))
              .ref
              .getDownloadURL();

      final licensePhotoUrl =
          await (await _storage
                  .ref('drivers/$uid/licensePhoto.jpg')
                  .putFile(licensePhoto))
              .ref
              .getDownloadURL();

      final conductorPhotoUrl =
          await (await _storage
                  .ref('drivers/$uid/conductorPhoto.jpg')
                  .putFile(conductorPhoto))
              .ref
              .getDownloadURL();

      // Save all driver info to Firestore
      await _firestore.collection('drivers').doc(uid).set({
        "name": name,
        "nic": nic,
        "email": email,
        "password":
            password, // ⚠️ recommended: DON'T store password in Firestore
        "birth": birth.toIso8601String(),
        "phone": phone,
        "vehicleType": vehicleType,
        "vehicleNum": vehicleNum,
        "licenseNum": licenseNum,
        "licenseExpiry": licenseExpiry.toIso8601String(),
        "driverPhotoUrl": driverPhotoUrl,
        "licensePhotoUrl": licensePhotoUrl,
        "conductorName": conductorName,
        "conductorPhone": conductorPhone,
        "conductorPhotoUrl": conductorPhotoUrl,
        "busNo": busNo,
        "routeNo": routeNo,
        "routeName": routeName,
        "depot": depot,
        "tripsPerDay": tripsPerDay,
        "trips": trips
            .map(
              (t) => {
                "direction": t["direction"],
                "startTime": t["startTime"].text,
                "arrivalTime": t["arrivalTime"].text,
              },
            )
            .toList(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      showMsg(context, "Driver registered successfully!");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverAppHomeScreen()),
      );
    } catch (e) {
      showMsg(context, "Error saving driver data: $e", isError: true);
    }
  }

  // ==========================================================
  // ✅ LOGIN — Pure backend OTP (no Firebase)
  // ==========================================================

  /// Step 1 (LOGIN): Ask the backend to send an OTP SMS to [phone].
  /// The backend stores the OTP in Redis.
  /// [onCodeSent] is called with a dummy verificationId (the phone itself)
  /// so the existing OtpVerifyScreen keeps working without changes.
  Future<void> sendLoginOtp({
    required String phone,
    required BuildContext context,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      debugPrint('sendLoginOtp: requesting backend OTP for $phone');

      final resp = await http
          .post(
            Uri.parse('$_backendBase/drivers/request-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('request-otp response: ${resp.statusCode} ${resp.body}');

      if (!context.mounted) return;

      if (resp.statusCode == 200) {
        // Pass phone as verificationId — OtpVerifyScreen sends it back to us
        onCodeSent(phone);
        showMsg(context, '✅ OTP sent to $phone');
      } else {
        final body = jsonDecode(resp.body);
        showMsg(context, body['error'] ?? 'Failed to send OTP', isError: true);
      }
    } catch (e) {
      debugPrint('sendLoginOtp error: $e');
      if (context.mounted) showMsg(context, 'Error: $e', isError: true);
    }
  }

  /// Step 2 (LOGIN): Verify OTP with backend → receive JWT → save it.
  /// [verificationId] here is actually the phone number passed from sendLoginOtp.
  Future<void> verifyLoginOtp({
    required String verificationId, // == phone number
    required String otp,
    required String phone,
    required BuildContext context,
  }) async {
    try {
      debugPrint('verifyLoginOtp: phone=$phone otp=$otp');

      final resp = await http
          .post(
            Uri.parse('$_backendBase/drivers/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'phone': phone, 'otp': otp}),
          )
          .timeout(const Duration(seconds: 15));

      debugPrint('verify-otp response: ${resp.statusCode} ${resp.body}');

      if (!context.mounted) return;

      if (resp.statusCode != 200) {
        final body = jsonDecode(resp.body);
        showMsg(context, body['error'] ?? 'Invalid OTP', isError: true);
        return;
      }

      final data = jsonDecode(resp.body);
      if (data['success'] != true) {
        showMsg(context, data['error'] ?? 'OTP verification failed', isError: true);
        return;
      }

      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        showMsg(context, 'No token received from backend', isError: true);
        return;
      }

      // Save JWT — GpsHaddlePage reads this on open
      await TokenStorage.saveToken(token);
      debugPrint('✅ JWT saved: ${token.substring(0, 20)}...');

      showMsg(context, '✅ Login successful!');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverAppHomeScreen()),
      );
    } catch (e) {
      debugPrint('verifyLoginOtp error: $e');
      if (context.mounted) showMsg(context, 'Error: $e', isError: true);
    }
  }

  /// Sign out — clears the backend JWT
  Future<void> signOut({required BuildContext context}) async {
    await TokenStorage.deleteToken();
    if (context.mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => DriverLoginScreen()),
      );
    }
  }
}

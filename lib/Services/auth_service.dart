import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../View/Auth/login.dart';
import '../View/home_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  void showMsg(
    BuildContext context,
    String msg, {
    bool isError = false,
  }) {
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
    try {
      debugPrint("VERIFY: name=$name phone=$phone");

      final snap = await _firestore
          .collection('drivers')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      debugPrint("VERIFY: found docs = ${snap.docs.length}");

      if (snap.docs.isEmpty) {
        debugPrint("VERIFY FAIL: phone not found in drivers");
        return false;
      }

      final data = snap.docs.first.data();
      final savedName = (data['name'] ?? '').toString().trim();

      debugPrint("VERIFY: savedName=$savedName");

      // case-insensitive compare
      final ok = savedName.toLowerCase() == name.trim().toLowerCase();
      debugPrint("VERIFY RESULT: $ok");
      return ok;
    } catch (e) {
      debugPrint("VERIFY ERROR: $e");
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
    required List<Map<String, dynamic>> trips, // direction, startTime, arrivalTime
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
          showMsg(context, e.message ?? "Phone verification failed", isError: true);
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
      final driverPhotoUrl = await (await _storage
              .ref('drivers/$uid/driverPhoto.jpg')
              .putFile(driverPhoto))
          .ref
          .getDownloadURL();

      final licensePhotoUrl = await (await _storage
              .ref('drivers/$uid/licensePhoto.jpg')
              .putFile(licensePhoto))
          .ref
          .getDownloadURL();

      final conductorPhotoUrl = await (await _storage
              .ref('drivers/$uid/conductorPhoto.jpg')
              .putFile(conductorPhoto))
          .ref
          .getDownloadURL();

      // Save all driver info to Firestore
      await _firestore.collection('drivers').doc(uid).set({
        "name": name,
        "nic": nic,
        "email": email,
        "password": password, // ⚠️ recommended: DON'T store password in Firestore
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
            .map((t) => {
                  "direction": t["direction"],
                  "startTime": t["startTime"].text,
                  "arrivalTime": t["arrivalTime"].text,
                })
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
  // ✅ LOGIN OTP METHODS
  // ==========================================================

  /// Step 1 (LOGIN): Send OTP only
  Future<void> sendLoginOtp({
    required String phone,
    required BuildContext context,
    required Function(String verificationId) onCodeSent,
  }) async {
    try {
      debugPrint("SEND OTP: phone=$phone");

      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);

          if (!context.mounted) return;
          showMsg(context, "✅ Auto verified & logged in!");

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const DriverAppHomeScreen()),
          );
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("OTP FAILED: ${e.code} ${e.message}");
          showMsg(context, e.message ?? "Phone verification failed", isError: true);
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("OTP SENT: verificationId=$verificationId");
          onCodeSent(verificationId);
          showMsg(context, "✅ OTP sent!");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("OTP TIMEOUT: verificationId=$verificationId");
        },
      );
    } catch (e) {
      debugPrint("SEND OTP ERROR: $e");
      showMsg(context, "Error: $e", isError: true);
    }
  }

  /// Step 2 (LOGIN): Verify OTP only
  Future<void> verifyLoginOtp({
    required String verificationId,
    required String otp,
    required BuildContext context,
  }) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      await _auth.signInWithCredential(credential);

      if (!context.mounted) return;
      showMsg(context, "✅ Login success!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverAppHomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      showMsg(context, e.message ?? "Invalid OTP", isError: true);
    } catch (e) {
      showMsg(context, "Error: $e", isError: true);
    }
  }

  /// Sign out
  Future<void> signOut({required BuildContext context}) async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DriverLoginScreen()),
    );
  }
}

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import '../View/Auth/login.dart';
import '../View/home_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Step 1: Send OTP to the phone number
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
          Fluttertoast.showToast(
            msg: e.message ?? "Phone verification failed",
            toastLength: Toast.LENGTH_LONG,
            gravity: ToastGravity.SNACKBAR,
            backgroundColor: Colors.white,
            textColor: Colors.red,
            fontSize: 14,
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.white,
        textColor: Colors.red,
        fontSize: 14,
      );
    }
  }

  /// Step 2: Verify OTP and save driver data
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
      Fluttertoast.showToast(
        msg: e.message ?? "Invalid OTP",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.white,
        textColor: Colors.red,
        fontSize: 14,
      );
    }
  }

  /// Upload images and save driver data to Firestore
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
      final driverPhotoUrl = await (await _storage.ref('drivers/$uid/driverPhoto.jpg').putFile(driverPhoto)).ref.getDownloadURL();
      final licensePhotoUrl = await (await _storage.ref('drivers/$uid/licensePhoto.jpg').putFile(licensePhoto)).ref.getDownloadURL();
      final conductorPhotoUrl = await (await _storage.ref('drivers/$uid/conductorPhoto.jpg').putFile(conductorPhoto)).ref.getDownloadURL();

      // Save all driver info to Firestore
      await _firestore.collection('drivers').doc(uid).set({
        "name": name,
        "nic": nic,
        "email": email,
        "password": password,
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

      Fluttertoast.showToast(
        msg: "Driver registered successfully!",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.green,
        textColor: Colors.white,
        fontSize: 14,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverAppHomeScreen()),
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Error saving driver data: $e",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 14,
      );
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

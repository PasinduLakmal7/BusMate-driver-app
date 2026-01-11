import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:io';

import '../View/Auth/login.dart';
import '../View/home_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Step 1: Send OTP to the phone number
  Future<void> registerDriver({
    required String name,
    required DateTime birth,
    required File driverPhoto,   
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required File licensePhoto,
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
            birth: birth,
            driverPhoto: driverPhoto,
            phone: phone,
            vehicleType: vehicleType,
            vehicleNum: vehicleNum,
            licenseNum: licenseNum,
            licensePhoto: licensePhoto,
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
          // OTP sent, pass verificationId to the screen where user enters OTP
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
    required DateTime birth,
    required File driverPhoto,
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required File licensePhoto,
    required BuildContext context,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);

      // Save driver data after OTP verification
      await _saveDriverData(
        context: context,
        name: name,
        birth: birth,
        driverPhoto: driverPhoto,
        phone: phone,
        vehicleType: vehicleType,
        vehicleNum: vehicleNum,
        licenseNum: licenseNum,
        licensePhoto: licensePhoto,
      );

    } on FirebaseAuthException catch (e) {
      Fluttertoast.showToast(
        msg: e.message ?? "Invalid OTP",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.SNACKBAR,
        backgroundColor: Colors.white,
        textColor: Colors.green,
        fontSize: 14,
      );
    }
  }

  /// Private function to upload images and save data in Firestore
  Future<void> _saveDriverData({
    required BuildContext context,
    required String name,
    required DateTime birth,
    required File driverPhoto,
    required String phone,
    required String vehicleType,
    required String vehicleNum,
    required String licenseNum,
    required File licensePhoto,
  }) async {
    try {
      String uid = _auth.currentUser!.uid;

      // Upload driver photo
      UploadTask driverPhotoTask = _storage.ref('drivers/$uid/driverPhoto.jpg').putFile(driverPhoto);
      TaskSnapshot driverPhotoSnapshot = await driverPhotoTask;
      String driverPhotoUrl = await driverPhotoSnapshot.ref.getDownloadURL();

      // Upload license photo
      UploadTask licensePhotoTask = _storage.ref('drivers/$uid/licensePhoto.jpg').putFile(licensePhoto);
      TaskSnapshot licensePhotoSnapshot = await licensePhotoTask;
      String licensePhotoUrl = await licensePhotoSnapshot.ref.getDownloadURL();

      // Save all data to Firestore
      await _firestore.collection('drivers').doc(uid).set({
        'name': name,
        'birth': birth.toIso8601String(),
        'phone': phone,
        'vehicleType': vehicleType,
        'vehicleNum': vehicleNum,
        'licenseNum': licenseNum,
        'driverPhotoUrl': driverPhotoUrl,
        'licensePhotoUrl': licensePhotoUrl,
        'createdAt': FieldValue.serverTimestamp(),
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
        MaterialPageRoute(builder: (context) => const DriverAppHomeScreen()),
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
      MaterialPageRoute(builder: (context) => DriverLoginScreen()),
    );
  }
}

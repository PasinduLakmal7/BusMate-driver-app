import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../Services/auth_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _birthController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _vehicleTypeController = TextEditingController();
  final TextEditingController _vehicleNumController = TextEditingController();
  final TextEditingController _licenseNumController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();

  // Files
  File? _driverPhoto;
  File? _licensePhoto;

  bool _otpSent = false;
  String? _verificationId;

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Driver Registration')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (val) => val!.isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 10),

              // Birth Date
              TextFormField(
                controller: _birthController,
                decoration: const InputDecoration(
                  labelText: 'Birth Date (yyyy-mm-dd)',
                ),
                validator: (val) => val!.isEmpty ? 'Enter birth date' : null,
              ),
              const SizedBox(height: 10),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone (+94...)'),
                validator: (val) => val!.isEmpty ? 'Enter phone' : null,
              ),
              const SizedBox(height: 10),

              // Vehicle Type
              TextFormField(
                controller: _vehicleTypeController,
                decoration: const InputDecoration(labelText: 'Vehicle Type'),
                validator: (val) => val!.isEmpty ? 'Enter vehicle type' : null,
              ),
              const SizedBox(height: 10),

              // Vehicle Number
              TextFormField(
                controller: _vehicleNumController,
                decoration: const InputDecoration(labelText: 'Vehicle Number'),
                validator: (val) => val!.isEmpty ? 'Enter vehicle number' : null,
              ),
              const SizedBox(height: 10),

              // License Number
              TextFormField(
                controller: _licenseNumController,
                decoration: const InputDecoration(labelText: 'License Number'),
                validator: (val) => val!.isEmpty ? 'Enter license number' : null,
              ),
              const SizedBox(height: 20),

              // Driver Photo
              ElevatedButton(
                onPressed: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setState(() => _driverPhoto = File(image.path));
                },
                child: Text(_driverPhoto == null ? 'Upload Driver Photo' : 'Change Driver Photo'),
              ),
              const SizedBox(height: 10),

              // License Photo
              ElevatedButton(
                onPressed: () async {
                  final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                  if (image != null) setState(() => _licensePhoto = File(image.path));
                },
                child: Text(_licensePhoto == null ? 'Upload License Photo' : 'Change License Photo'),
              ),
              const SizedBox(height: 20),

              // OTP input (visible only after sending OTP)
              if (_otpSent)
                TextFormField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Enter OTP'),
                ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  if (!_otpSent) {
                    // Step 1: Validate form
                    if (!_formKey.currentState!.validate()) return;
                    if (_driverPhoto == null || _licensePhoto == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please upload both images')),
                      );
                      return;
                    }

                    // Step 2: Send OTP
                    await AuthService().registerDriver(
                      name: _nameController.text,
                      birth: DateTime.parse(_birthController.text),
                      driverPhoto: _driverPhoto!,
                      phone: '+94${_phoneController.text}',
                      vehicleType: _vehicleTypeController.text,
                      vehicleNum: _vehicleNumController.text,
                      licenseNum: _licenseNumController.text,
                      licensePhoto: _licensePhoto!,
                      context: context,
                      onCodeSent: (verificationId) {
                        setState(() {
                          _otpSent = true;
                          _verificationId = verificationId;
                        });
                      },
                    );
                  } else {
                    // Step 3: Verify OTP and save driver
                    if (_verificationId != null) {
                      await AuthService().verifyOtpAndSaveDriver(
                        verificationId: _verificationId!,
                        otp: _otpController.text,
                        name: _nameController.text,
                        birth: DateTime.parse(_birthController.text),
                        driverPhoto: _driverPhoto!,
                        phone: '+94${_phoneController.text}',
                        vehicleType: _vehicleTypeController.text,
                        vehicleNum: _vehicleNumController.text,
                        licenseNum: _licenseNumController.text,
                        licensePhoto: _licensePhoto!,
                        context: context,
                      );
                    }
                  }
                },
                child: Text(_otpSent ? 'Verify OTP' : 'Register & Send OTP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

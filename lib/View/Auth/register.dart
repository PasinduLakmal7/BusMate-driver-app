import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:driver_app/Utils/colors.dart';
import '../../Services/api_service.dart';

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Driver Details
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nicCtrl = TextEditingController();
  File? driverPhotoFile;
  String? driverPhotoUrl;

  // License Details
  final licenseNumCtrl = TextEditingController();
  DateTime? licenseExpiryDate;
  File? licensePhotoFile;
  String? licensePhotoUrl;

  // Bus Details
  final busNumCtrl = TextEditingController();
  final busTypeCtrl = TextEditingController();
  final depotCtrl = TextEditingController();
  File? busPhotoFile;
  String? busPhotoUrl;

  // Conductor Details
  final conductorNameCtrl = TextEditingController();
  final conductorNicCtrl = TextEditingController();
  final conductorPhoneCtrl = TextEditingController();
  File? conductorPhotoFile;
  String? conductorPhotoUrl;

  // Route & Trips Details
  final routeNumberCtrl = TextEditingController();
  final routeNameCtrl = TextEditingController();
  int tripCount = 0;
  List<Map<String, dynamic>> trips = [];

  // cloud name
  static const String cloudinaryCloudName = "dq97kgovy";
  static const String cloudinaryUploadPreset = "driver_registration";
  bool loading = false;
  final ImagePicker _imagePicker = ImagePicker();

  InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 15),
    filled: true,
    fillColor: Colors.white.withOpacity(0.06),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: const BorderSide(color: Colors.blueAccent),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
  );

  @override
  void dispose() {
    // Driver
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nicCtrl.dispose();

    // License
    licenseNumCtrl.dispose();

    // Bus
    busNumCtrl.dispose();
    busTypeCtrl.dispose();
    depotCtrl.dispose();

    // Conductor
    conductorNameCtrl.dispose();
    conductorNicCtrl.dispose();
    conductorPhoneCtrl.dispose();

    // Route & Trips
    routeNumberCtrl.dispose();
    routeNameCtrl.dispose();

    // Dispose trip controllers
    for (var trip in trips) {
      trip['beginTime']?.dispose();
      trip['endTime']?.dispose();
    }

    super.dispose();
  }

  // snake bar messages
  void showMsg(String msg, {bool ok = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Text(msg, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        backgroundColor: ok ? Colors.greenAccent.withOpacity(0.9) : Colors.redAccent.withOpacity(0.9),
      ),
    );
  }

  // Test Data {fake dataa}
  void fillTestData() {
    setState(() {
      // Driver Details
      nameCtrl.text = "John Driver";
      nicCtrl.text = "123456789V";
      phoneCtrl.text = "0712345678";
      emailCtrl.text = "driver@test.com";
      passwordCtrl.text = "Test@1234";

      // License Details
      licenseNumCtrl.text = "DL2025001";
      licenseExpiryDate = DateTime(2027, 12, 31);

      // Bus Details
      busNumCtrl.text = "WP-AB-1234";
      busTypeCtrl.text = "AC Coach";
      depotCtrl.text = "Main Depot";

      // Conductor Details
      conductorNameCtrl.text = "Ram Conductor";
      conductorNicCtrl.text = "987654321V";
      conductorPhoneCtrl.text = "0787654321";

      // Route Details
      routeNumberCtrl.text = "101";
      routeNameCtrl.text = "Colombo - Kandy";

      // Trips
      tripCount = 2;
      trips.clear();
      trips.add({
        'beginTime': TextEditingController(text: '08:00'),
        'endTime': TextEditingController(text: '10:30'),
        'direction': 'Colombo - Kandy',
      });
      trips.add({
        'beginTime': TextEditingController(text: '11:00'),
        'endTime': TextEditingController(text: '13:00'),
        'direction': 'Kandy - Colombo',
      });
    });

    showMsg("✅ Test data filled!", ok: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset("assets/back.jpg", fit: BoxFit.cover),
          ),
          
          // Shader Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.6),
                    backgroundColor.withOpacity(0.9),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(color: Colors.transparent),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [Colors.white, Color(0xFF94A3B8)],
                        ).createShader(bounds),
                        child: Text(
                          "Join the Fleet",
                          style: GoogleFonts.montserrat(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "Registration Portal",
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.5),
                          fontWeight: FontWeight.w600,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    // Test Data add Button
                    Center(
                      child: TextButton.icon(
                        onPressed: fillTestData,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.amberAccent),
                        label: Text("Fill Test Data", style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(foregroundColor: Colors.amberAccent),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // DRIVER SECTION 
                    section("👤 Driver Details"),
                    field(nameCtrl, "Full Name"),
                    const SizedBox(height: 12),
                    field(nicCtrl, "NIC"),
                    const SizedBox(height: 12),
                    field(phoneCtrl, "Phone Number"),
                    const SizedBox(height: 12),
                    field(emailCtrl, "Email"),
                    const SizedBox(height: 12),
                    field(passwordCtrl, "Password", obscure: true),
                    const SizedBox(height: 12),
                    imagePickerButton(
                      "Driver Photo",
                      driverPhotoFile,
                      () => pickImage(1),
                    ),
                    const SizedBox(height: 24),

                    // LICENSE SECTION
                    section("📋 License Details"),
                    field(licenseNumCtrl, "License Number"),
                    const SizedBox(height: 12),
                    datePickerField("License Expiry Date", licenseExpiryDate),
                    const SizedBox(height: 12),
                    imagePickerButton(
                      "License Photo",
                      licensePhotoFile,
                      () => pickImage(2),
                    ),
                    const SizedBox(height: 24),

                    // BUS SECTION
                    section("🚌 Bus Details"),
                    field(busNumCtrl, "Bus Number"),
                    const SizedBox(height: 12),
                    field(busTypeCtrl, "Bus Type"),
                    const SizedBox(height: 12),
                    field(depotCtrl, "Depot Name/ Company Name"),
                    const SizedBox(height: 12),
                    imagePickerButton(
                      "Bus Photo",
                      busPhotoFile,
                      () => pickImage(4),
                    ),
                    const SizedBox(height: 24),

                    // CONDUCTOR SECTION
                    section("👨‍💼 Conductor Details (Optional)"),
                    field(conductorNameCtrl, "Conductor Name"),
                    const SizedBox(height: 12),
                    field(conductorNicCtrl, "Conductor NIC"),
                    const SizedBox(height: 12),
                    field(conductorPhoneCtrl, "Conductor Phone"),
                    const SizedBox(height: 12),
                    imagePickerButton(
                      "Conductor Photo",
                      conductorPhotoFile,
                      () => pickImage(3),
                    ),
                    const SizedBox(height: 24),

                    // ROUTE & TRIPS SECTION 
                    section("🛣️ Route Details"),
                    field(routeNumberCtrl, "Route Number"),
                    const SizedBox(height: 12),
                    field(routeNameCtrl, "Route Name"),
                    const SizedBox(height: 24),

                    section("⏱️ Trips"),
                    tripCountInput(),
                    const SizedBox(height: 12),
                    if (trips.isNotEmpty) ...[
                      tripInputFields(),
                      const SizedBox(height: 24),
                    ],

                    // SUBMIT BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blueAccent.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          onPressed: loading ? null : submit,
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF3B82F6)]),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                loading ? "SAVING..." : "COMPLETE REGISTRATION",
                                style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    //login link
                    Center(
                      child: GestureDetector(
                        child: RichText(
                          text: TextSpan(
                            text: "Already joined? ",
                            style: GoogleFonts.inter(color: Colors.white38, fontWeight: FontWeight.w500),
                            children: [
                              TextSpan(
                                text: "Login here",
                                style: GoogleFonts.inter(color: Colors.blueAccent, fontWeight: FontWeight.w800, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Widgets 
  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 20, top: 10),
    child: Text(
      title.toUpperCase(),
      style: GoogleFonts.montserrat(
        fontSize: 13,
        fontWeight: FontWeight.w800,
        color: Colors.blueAccent,
        letterSpacing: 1.5,
      ),
    ),
  );

  Widget field(TextEditingController c, String hint, {bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      decoration: input(hint),
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
      style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
    );
  }

  // Date Picker Field for License Expiry
  Widget datePickerField(String label, DateTime? selectedDate) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final pickedDate = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime(2099),
            );
            if (pickedDate != null) {
              setState(() {
                licenseExpiryDate = pickedDate;
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.blueAccent, size: 22),
                const SizedBox(width: 15),
                Text(
                  licenseExpiryDate == null
                      ? "Select Expiry Date"
                      : "${licenseExpiryDate!.year}-${licenseExpiryDate!.month.toString().padLeft(2, '0')}-${licenseExpiryDate!.day.toString().padLeft(2, '0')}",
                  style: GoogleFonts.inter(
                    color: licenseExpiryDate == null
                        ? Colors.white38
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Trip Count Input
  Widget tripCountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How many trips?",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Trip Count",
                  hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 15),
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: Colors.blueAccent, size: 22),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: Colors.blueAccent),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                ),
                keyboardType: TextInputType.number,
                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w500),
                onChanged: (value) {
                  int count = int.tryParse(value) ?? 0;
                  if (count != tripCount) {
                    setState(() {
                      tripCount = count;
                      trips.clear();

                      for (int i = 0; i < count; i++) {
                        trips.add({
                          'beginTime': TextEditingController(),
                          'endTime': TextEditingController(),
                          'direction': 'SELECT_DIRECTION', // placeholder
                        });
                      }
                    });
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Trip Input Fields (auto generated)
  Widget tripInputFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(trips.length, (index) {
        final trip = trips[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Trip ${index + 1}",
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 12),
            // Begin Time Picker
            timePickerField("Begin Time", trip['beginTime']),
            const SizedBox(height: 8),
            // End Time Picker
            timePickerField("End Time", trip['endTime']),
            const SizedBox(height: 8),
            // Route Direction Dropdown
            routeDirectionDropdown(trip, index),
            const SizedBox(height: 16),
          ],
        );
      }),
    );
  }

  // Time Picker Field
  Widget timePickerField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final pickedTime = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.now(),
            );
            if (pickedTime != null) {
              controller.text =
                  "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time_rounded, color: Colors.blueAccent, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    controller.text.isEmpty
                        ? "Select ${label.toLowerCase()}"
                        : controller.text,
                    style: GoogleFonts.inter(
                      color: controller.text.isEmpty
                          ? Colors.white38
                          : Colors.white,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Route Direction Dropdown
  Widget routeDirectionDropdown(Map<String, dynamic> trip, int index) {
    // Parse route name to generate directions
    List<String> directions = [];

    if (routeNameCtrl.text.trim().isNotEmpty) {
      final routeName = routeNameCtrl.text.trim();
      if (routeName.contains('-')) {
        // Split by '-' and get parts
        final parts = routeName.split('-').map((s) => s.trim()).toList();
        if (parts.length == 2) {
          final direction1 = '${parts[0]} - ${parts[1]}';
          final direction2 = '${parts[1]} - ${parts[0]}';
          directions = [direction1, direction2];
        } else {
          directions = [routeName];
        }
      } else {
        directions = [routeName];
      }
    }

    // Initialize with placeholder if not set
    if (trip['direction'] == null ||
        trip['direction'] == 'No route selected' ||
        !directions.contains(trip['direction'])) {
      trip['direction'] = 'SELECT_DIRECTION'; // placeholder value
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Route Direction",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white70,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: DropdownButton<String>(
            value: trip['direction'],
            isExpanded: true,
            underline: const SizedBox(),
            hint: Text(
              'Select Direction',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
            ),
            style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
            dropdownColor: const Color(0xFF0F172A),
            items: [
              // Placeholder item
              const DropdownMenuItem<String>(
                value: 'SELECT_DIRECTION',
                child: Text(
                  'Select Direction',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
              // Actual directions
              ...directions.map((String direction) {
                return DropdownMenuItem<String>(
                  value: direction,
                  child: Text(direction),
                );
              }).toList(),
            ],
            onChanged: (String? newValue) {
              if (newValue != null && newValue != 'SELECT_DIRECTION') {
                setState(() {
                  trip['direction'] = newValue;
                });
              }
            },
          ),
        ),
      ],
    );
  }

  // Image Picker Button
  Widget imagePickerButton(
    String label,
    File? imageFile,
    VoidCallback onPressed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
          ),
          child: Column(
            children: [
              if (imageFile != null)
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    image: DecorationImage(
                      image: FileImage(imageFile),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(22),
                      topRight: Radius.circular(22),
                    ),
                    color: Colors.white.withOpacity(0.04),
                  ),
                  child: Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.blueAccent.withOpacity(0.5),
                    size: 40,
                  ),
                ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.04),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(22),
                    bottomRight: Radius.circular(22),
                  ),
                ),
                child: MaterialButton(
                  onPressed: onPressed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.add_a_photo_outlined,
                        color: Colors.blueAccent,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        imageFile == null ? "Capture / Upload" : "Change Image",
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Pick image (camera or gallery)
  Future<void> pickImage(int imageType) async {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text("Camera"),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFrom(ImageSource.camera, imageType);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image, color: Colors.green),
              title: const Text("Gallery"),
              onTap: () async {
                Navigator.pop(context);
                await _pickImageFrom(ImageSource.gallery, imageType);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick from camera or gallery
  Future<void> _pickImageFrom(ImageSource source, int imageType) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 80,
        maxWidth: 1200,
      );

      if (pickedFile != null) {
        setState(() {
          if (imageType == 1) {
            driverPhotoFile = File(pickedFile.path);
          } else if (imageType == 2) {
            licensePhotoFile = File(pickedFile.path);
          } else if (imageType == 3) {
            conductorPhotoFile = File(pickedFile.path);
          } else if (imageType == 4) {
            busPhotoFile = File(pickedFile.path);
          }
        });
        showMsg("✅ Image selected!", ok: true);
      }
    } catch (e) {
      showMsg("❌ Error picking image: $e", ok: false);
    }
  }




  // Upload image to Cloudinary and get URL
  Future<String?> uploadImageToCloudinary(
    File imageFile,
    String imageName,
  ) async {
    try {
      // Check if credentials are set
      if (cloudinaryCloudName == "YOUR_CLOUD_NAME" ||
          cloudinaryUploadPreset == "YOUR_UPLOAD_PRESET") {
        showMsg(
          "❌ Cloudinary NOT configured!\n\nUpdate in register.dart (lines ~51-54):\ncloud_name\nupload_preset",
          ok: false,
        );
        return null;
      }

      print("📤 Uploading to Cloudinary: $imageName");
      print("📤 Cloud: $cloudinaryCloudName");
      print("📤 Preset: $cloudinaryUploadPreset");

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload',
        ),
      );

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      // Add upload preset
      request.fields['upload_preset'] = cloudinaryUploadPreset;

      // Add public ID (folder structure)
      request.fields['public_id'] =
          'driver-registration/${DateTime.now().millisecondsSinceEpoch}_$imageName';

      // Send request
      final response = await request.send().timeout(
        const Duration(seconds: 60),
        onTimeout: () => throw Exception('Upload timeout'),
      );

      print("📤 Cloudinary Response: ${response.statusCode}");

      if (response.statusCode == 200) {
        // Parse response
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);

        // Extract secure URL from response
        final jsonResponse = responseString;
        if (jsonResponse.contains('secure_url')) {
          // Simple URL extraction
          final urlStart = jsonResponse.indexOf('"secure_url":"') + 14;
          final urlEnd = jsonResponse.indexOf('"', urlStart);
          final url = jsonResponse.substring(urlStart, urlEnd);

          print("✅ Upload successful: $url");
          return url;
        }
      } else {
        // Print full error response
        final responseData = await response.stream.toBytes();
        final responseString = String.fromCharCodes(responseData);
        print("❌ Upload failed: ${response.statusCode}");
        print("❌ Error: $responseString");

        String errorMsg = "❌ Upload failed (${response.statusCode})";

        if (response.statusCode == 401) {
          errorMsg =
              "❌ 401 Unauthorized!\n\nFix this:\n✓ Cloud name correct?\n✓ Upload preset correct?\n✓ Preset set to UNSIGNED?";
        } else if (response.statusCode == 400) {
          errorMsg =
              "❌ 400 Bad Request\n\nCheck:\n✓ Upload preset name spell\n✓ Form fields correct";
        }

        showMsg(errorMsg, ok: false);
      }

      return null;
    } catch (e) {
      print("❌ Upload error: $e");
      showMsg("❌ Error: $e", ok: false);
      return null;
    }
  }

  // Upload all images to Cloudinary before submission
  Future<bool> uploadAllImages() async {
    try {
      showMsg("📤 Uploading images to Cloudinary...", ok: true);

      // Upload driver photo
      if (driverPhotoFile != null) {
        driverPhotoUrl = await uploadImageToCloudinary(
          driverPhotoFile!,
          'driver_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (driverPhotoUrl == null) return false;
      }

      // Upload license photo
      if (licensePhotoFile != null) {
        licensePhotoUrl = await uploadImageToCloudinary(
          licensePhotoFile!,
          'license_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (licensePhotoUrl == null) return false;
      }

      // Upload conductor photo
      if (conductorPhotoFile != null) {
        conductorPhotoUrl = await uploadImageToCloudinary(
          conductorPhotoFile!,
          'conductor_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (conductorPhotoUrl == null) return false;
      }

      // Upload bus photo
      if (busPhotoFile != null) {
        busPhotoUrl = await uploadImageToCloudinary(
          busPhotoFile!,
          'bus_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (busPhotoUrl == null) return false;
      }

      showMsg("✅ All images uploaded to Cloudinary!", ok: true);
      return true;
    } catch (e) {
      print("❌ Upload all error: $e");
      showMsg("❌ Image upload failed: $e", ok: false);
      return false;
    }
  }

  //  Submit Function 
  void submit() async {
    if (!_formKey.currentState!.validate()) {
      showMsg("❌ Please fill all required fields", ok: false);
      return;
    }

    if (licenseExpiryDate == null) {
      showMsg("❌ Please select license expiry date", ok: false);
      return;
    }

    // Validate trip directions
    for (int i = 0; i < trips.length; i++) {
      if (trips[i]['direction'] == 'SELECT_DIRECTION') {
        showMsg("❌ Please select direction for Trip ${i + 1}", ok: false);
        return;
      }
    }

    setState(() => loading = true);

    try {
      print("DEBUG: Starting registration...");

      // Upload all images first
      print("DEBUG: Uploading images...");
      bool uploadSuccess = await uploadAllImages();
      if (!uploadSuccess) {
        setState(() => loading = false);
        return;
      }

      // Format Sri Lanka phone to +94XXXXXXXXX
      String clean = phoneCtrl.text.trim().replaceAll(" ", "");
      if (clean.startsWith("0")) clean = clean.substring(1);
      final phone = "+94$clean";

      // Format license expiry date
      final licenseExpiry =
          "${licenseExpiryDate!.year}-${licenseExpiryDate!.month.toString().padLeft(2, '0')}-${licenseExpiryDate!.day.toString().padLeft(2, '0')}";

      // Build trips JSON
      String? tripsJson;
      if (trips.isNotEmpty) {
        List<Map<String, String>> tripsList = [];
        for (var trip in trips) {
          tripsList.add({
            'beginTime': trip['beginTime'].text.trim(),
            'endTime': trip['endTime'].text.trim(),
            'direction': trip['direction'],
          });
        }
        tripsJson = jsonEncode(tripsList);
      }

      // Send data to BusMate backend (pending_regs table)
      print("DEBUG: Sending registration to backend...");
      final backendResponse = await ApiService.registerDriver(
        name: nameCtrl.text.trim(),
        email: emailCtrl.text.trim(),
        phone: phone,
        password: passwordCtrl.text.trim(),
        nic: nicCtrl.text.trim(),
        licenseNumber: licenseNumCtrl.text.trim(),
        licenseExpiry: licenseExpiry,
        busNumber: busNumCtrl.text.trim(),
        driverPhotoUrl: driverPhotoUrl,
        licensePhotoUrl: licensePhotoUrl,
        busType: busTypeCtrl.text.trim().isEmpty
            ? null
            : busTypeCtrl.text.trim(),
        depotName: depotCtrl.text.trim().isEmpty ? null : depotCtrl.text.trim(),
        conductorName: conductorNameCtrl.text.trim().isEmpty
            ? null
            : conductorNameCtrl.text.trim(),
        conductorNic: conductorNicCtrl.text.trim().isEmpty
            ? null
            : conductorNicCtrl.text.trim(),
        conductorPhone: conductorPhoneCtrl.text.trim().isEmpty
            ? null
            : conductorPhoneCtrl.text.trim(),
        conductorPhotoUrl: conductorPhotoUrl,
        routeNumber: routeNumberCtrl.text.trim().isEmpty
            ? null
            : routeNumberCtrl.text.trim(),
        routeName: routeNameCtrl.text.trim().isEmpty
            ? null
            : routeNameCtrl.text.trim(),
        tripsJson: tripsJson,
      );

      if (!backendResponse["success"]) {
        print("❌ Backend error: ${backendResponse["message"]}");
        showMsg("❌ ${backendResponse["message"]}", ok: false);
        setState(() => loading = false);
        return;
      }

      print("✅ Registration submitted successfully!");
      print("Backend Response: ${backendResponse["data"]}");

      showMsg(
        "✅ Registration submitted! Waiting for admin approval.",
        ok: true,
      );

      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.of(context).pop();
        });
      }
    } catch (e) {
      print("❌ ERROR: $e");
      showMsg("❌ Error: ${e.toString()}", ok: false);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
}

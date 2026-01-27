import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
// Removed import to avoid circular dependency with login.dart

class DriverRegisterScreen extends StatefulWidget {
  const DriverRegisterScreen({super.key});

  @override
  State<DriverRegisterScreen> createState() => _DriverRegisterScreenState();
}

class _DriverRegisterScreenState extends State<DriverRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();

  // Controllers
  final nameCtrl = TextEditingController();
  final nicCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  final licenseNoCtrl = TextEditingController();
  final licenseExpiryCtrl = TextEditingController();

  final conductorNameCtrl = TextEditingController();
  final conductorPhoneCtrl = TextEditingController();

  final busNoCtrl = TextEditingController();
  final routeNoCtrl = TextEditingController();
  final routeNameCtrl = TextEditingController();
  final depotCtrl = TextEditingController();
  final tripsCtrl = TextEditingController();

  String? busType;
  String? routeName;
  File? driverPhoto;
  File? licensePhoto;
  File? conductorPhoto;

  InputDecoration input(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: Colors.white70),
    filled: true,
    fillColor: Colors.white.withOpacity(0.25),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(50),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
  );

  @override
  void initState() {
    super.initState();
    // Trips functionality disabled - Section 4 is commented out
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ---------- Background Image with Shader ----------
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: ShaderMask(
              shaderCallback: (rect) {
                return LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ).createShader(rect);
              },
              blendMode: BlendMode.darken,
              child: Image.asset("assets/regi3.avif", fit: BoxFit.cover),
            ),
          ),
          // ---------- Form Overlay ----------
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Text(
                        "Register Here",
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    section("1. Basic Driver Information"),
                    field(nameCtrl, "Full Name"),
                    const SizedBox(height: 12),
                    field(nicCtrl, "NIC / National ID"),
                    const SizedBox(height: 12),
                    field(phoneCtrl, "Phone Number"),
                    const SizedBox(height: 12),
                    field(emailCtrl, "Email"),
                    const SizedBox(height: 12),
                    field(passwordCtrl, "Password", obscure: true),
                    const SizedBox(height: 12),

                    // imageField(
                    //   label: "Driver Profile Photo",
                    //   onSaved: (f) => driverPhoto = f,
                    // ),
                    section("2. Driving & Identity Verification"),
                    field(licenseNoCtrl, "Driving License Number"),
                    const SizedBox(height: 12),
                    datePickerField(
                      controller: licenseExpiryCtrl,
                      label: "License Expiry Date",
                    ),
                    const SizedBox(height: 12),

                    // imageField(
                    //   label: "License Photo",
                    //   onSaved: (f) => licensePhoto = f,
                    // ),
                    section("3. Conductor Details"),
                    field(conductorNameCtrl, "Conductor Name"),
                    const SizedBox(height: 12),
                    field(conductorPhoneCtrl, "Conductor Contact"),
                    const SizedBox(height: 12),
                    // imageField(
                    //   label: "Conductor Photo",
                    //   onSaved: (f) => conductorPhoto = f,
                    // ),

                    // ---------- COMMENTED OUT SECTION 4 FOR DEMO ----------
                    // section("4. Bus & Route Details"),
                    // field(busNoCtrl, "Bus Number"),
                    // const SizedBox(height: 12),
                    // dropdown(
                    //   value: busType,
                    //   hint: "Bus Type",
                    //   items: ["AC", "Non-AC", "School", "Private", "CTB"],
                    //   onChanged: (v) => setState(() => busType = v),
                    // ),
                    // const SizedBox(height: 12),
                    // field(routeNoCtrl, "Route Number"),
                    // const SizedBox(height: 12),
                    // dropdown(
                    //   value: routeName,
                    //   hint: "Route Name",
                    //   items: [
                    //     "Badulla - Colombo",
                    //     "Kandy - Colombo",
                    //     "Badulla - Bandarawela",
                    //     "Bandarawela - Welimada",
                    //     "Galkissa - Kottawa",
                    //   ],
                    //   onChanged: (v) {
                    //     setState(() {
                    //       routeName = v;
                    //       if (v != null) {
                    //         var parts = v.split(" - ");
                    //         availableDirections = [
                    //           "${parts[0]} - ${parts[1]}",
                    //           "${parts[1]} - ${parts[0]}",
                    //         ];
                    //         for (var trip in trips) {
                    //           trip["direction"] = null;
                    //         }
                    //       } else {
                    //         availableDirections = [];
                    //       }
                    //     });
                    //   },
                    // ),
                    // const SizedBox(height: 12),
                    // field(depotCtrl, "Depot / Company Name"),
                    // const SizedBox(height: 12),
                    // field(tripsCtrl, "Trips Per Day"),
                    // const SizedBox(height: 16),
                    //
                    // // ---------- Dynamic Time Table ----------
                    // if (trips.isNotEmpty) ...[
                    //   const SizedBox(height: 24),
                    //   const Text(
                    //     "Time Table",
                    //     style: TextStyle(
                    //       fontSize: 18,
                    //       fontWeight: FontWeight.bold,
                    //       color: Colors.white,
                    //     ),
                    //   ),
                    //   const SizedBox(height: 12),
                    //   ...trips.asMap().entries.map((entry) {
                    //     int idx = entry.key;
                    //     var trip = entry.value;
                    //     return Container(
                    //       margin: const EdgeInsets.symmetric(vertical: 8),
                    //       padding: const EdgeInsets.all(12),
                    //       decoration: BoxDecoration(
                    //         color: const Color.fromARGB(
                    //           255,
                    //           83,
                    //           83,
                    //           83,
                    //         ).withOpacity(0.9),
                    //         borderRadius: BorderRadius.circular(12),
                    //       ),
                    //       child: Column(
                    //         crossAxisAlignment: CrossAxisAlignment.start,
                    //         children: [
                    //           Text(
                    //             "Trip ${idx + 1}",
                    //             style: const TextStyle(
                    //               fontWeight: FontWeight.bold,
                    //             ),
                    //           ),
                    //           const SizedBox(height: 8),
                    //           dropdown(
                    //             value: trip["direction"],
                    //             hint: "Direction",
                    //             items: availableDirections,
                    //             onChanged: (v) =>
                    //                 setState(() => trip["direction"] = v),
                    //           ),
                    //           const SizedBox(height: 8),
                    //           timePickerField(
                    //             controller: trip["startTime"],
                    //             label: "Start Time",
                    //           ),
                    //           const SizedBox(height: 8),
                    //           timePickerField(
                    //             controller: trip["arrivalTime"],
                    //             label: "Arrival Time",
                    //           ),
                    //         ],
                    //       ),
                    //     );
                    //   }).toList(),
                    // ],
                    // ---------- END COMMENTED SECTION ----------
                    const SizedBox(height: 24),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 9, 7, 41),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: const StadiumBorder(),
                      ),
                      onPressed: submit,
                      child: const Text("Register Driver"),
                    ),

                    const SizedBox(height: 16),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: "Already have an account? ",
                            style: TextStyle(color: Colors.white70),
                            children: [
                              TextSpan(
                                text: "Login here",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
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

  // ---------- Widgets ----------
  Widget section(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );

  Widget field(TextEditingController c, String hint, {bool obscure = false}) {
    return TextFormField(
      controller: c,
      obscureText: obscure,
      decoration: input(hint),
      validator: (v) => v!.isEmpty ? "Required" : null,
    );
  }

  Widget datePickerField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: input(label),
      validator: (v) => null,
      onTap: () async {
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 3650)),
        );
        if (pickedDate != null) {
          controller.text =
              "${pickedDate.year}-${pickedDate.month.toString().padLeft(2, '0')}-${pickedDate.day.toString().padLeft(2, '0')}";
          setState(() {});
        }
      },
    );
  }

  Widget dropdown({
    required String hint,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(canvasColor: Colors.white),
      child: DropdownButtonFormField(
        value: value,
        onChanged: onChanged,
        validator: (v) => null,
        items: items
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(color: Colors.black)),
              ),
            )
            .toList(),
        decoration: input(hint),
      ),
    );
  }

  Widget timePickerField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      decoration: input(label),
      validator: (v) => null,
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );
        if (pickedTime != null) {
          controller.text =
              "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
          setState(() {});
        }
      },
    );
  }

  Widget imageField({
    required String label,
    required ValueChanged<File?> onSaved,
  }) {
    return FormField<File?>(
      validator: (f) => f == null ? "Required" : null,
      builder: (state) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: () async {
                final img = await picker.pickImage(source: ImageSource.gallery);
                if (img != null) {
                  final file = File(img.path);
                  state.didChange(file);
                  onSaved(file);
                }
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 156, 161, 175),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(
                    color: state.hasError ? Colors.red : Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.image),
                    const SizedBox(width: 12),
                    Text(state.value == null ? label : "Image Selected"),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 6),
                child: Text(
                  state.errorText!,
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ---------- Helper: Safe image upload ----------
  Future<String> _uploadImage(File? imageFile, String uid, String name) async {
    if (imageFile == null) {
      print("DEBUG: No $name to upload");
      return "";
    }

    try {
      print("DEBUG: Uploading $name...");
      final ref = FirebaseStorage.instance.ref("drivers/$uid/$name");
      await ref.putFile(imageFile);
      final url = await ref.getDownloadURL();
      print("DEBUG: $name URL: $url");
      return url;
    } catch (e) {
      print("DEBUG: Error uploading $name: $e");
      return "";
    }
  }

  // ---------- Submit Function ----------
  void submit() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Show loading indicator
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        // Step 1: Create user with Firebase Auth
        print("DEBUG: Creating user with email: ${emailCtrl.text.trim()}");
        UserCredential userCred = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: emailCtrl.text.trim(),
              password: passwordCtrl.text,
            );
        String uid = userCred.user!.uid;
        print("DEBUG: User created with UID: $uid");

        // Step 2: Upload images to Firebase Storage (safely)
        final driverPhotoUrl = await _uploadImage(
          driverPhoto,
          uid,
          "driver.jpg",
        );
        final licensePhotoUrl = await _uploadImage(
          licensePhoto,
          uid,
          "license.jpg",
        );
        final conductorPhotoUrl = await _uploadImage(
          conductorPhoto,
          uid,
          "conductor.jpg",
        );

        // Step 3: Build driver data map (type-safe)
        final String name = nameCtrl.text.trim();
        final String nic = nicCtrl.text.trim();
        final String phone = phoneCtrl.text.trim();
        final String email = emailCtrl.text.trim();
        final String licenseNo = licenseNoCtrl.text.trim();
        final String licenseExpiry = licenseExpiryCtrl.text.trim();
        final String conductorName = conductorNameCtrl.text.trim();
        final String conductorPhone = conductorPhoneCtrl.text.trim();
        final String busNo = busNoCtrl.text.trim();
        final String routeNo = routeNoCtrl.text.trim();
        final String depot = depotCtrl.text.trim();
        final String tripsPerDay = tripsCtrl.text.trim();
        final String busTypeValue = busType ?? "";
        final String routeNameValue = routeName ?? "";

        // Build the map with explicit types
        final Map<String, dynamic> driverData = <String, dynamic>{
          "uid": uid,
          "name": name,
          "nic": nic,
          "phone": phone,
          "email": email,
          "licenseNo": licenseNo,
          "licenseExpiry": licenseExpiry,
          "conductorName": conductorName,
          "conductorPhone": conductorPhone,
          "busNo": busNo,
          "busType": busTypeValue,
          "routeNo": routeNo,
          "routeName": routeNameValue,
          "depot": depot,
          "tripsPerDay": tripsPerDay,
          "driverPhotoUrl": driverPhotoUrl,
          "licensePhotoUrl": licensePhotoUrl,
          "conductorPhotoUrl": conductorPhotoUrl,
          "createdAt": FieldValue.serverTimestamp(),
        };

        // Step 4: Save to Firestore
        print("DEBUG: Saving driver data to Firestore for UID: $uid");
        await FirebaseFirestore.instance
            .collection("drivers")
            .doc(uid)
            .set(driverData, SetOptions(merge: false));

        print("DEBUG: Driver data saved successfully!");

        // Close loading dialog and go back to login
        if (mounted) {
          // Close both dialogs/screens
          Navigator.of(context).pop(); // Close loading dialog
          Navigator.of(context).pop(); // Go back to login
        }

        Fluttertoast.showToast(
          msg: "✅ Registration successful!",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          Navigator.pop(context);
        }
        String errorMsg = "Registration failed";
        if (e.code == 'weak-password') {
          errorMsg = "❌ Password too weak (min 6 chars)";
        } else if (e.code == 'email-already-in-use') {
          errorMsg = "❌ Email already registered";
        } else if (e.code == 'invalid-email') {
          errorMsg = "❌ Invalid email format";
        }
        print("DEBUG: Auth error: ${e.code} - ${e.message}");
        Fluttertoast.showToast(
          msg: errorMsg,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      } catch (e) {
        if (mounted) {
          Navigator.pop(context);
        }
        print("DEBUG: Unexpected error: $e");
        Fluttertoast.showToast(
          msg: "❌ Error: ${e.toString()}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}

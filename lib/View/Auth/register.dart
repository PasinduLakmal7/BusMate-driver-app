import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  // Dynamic trips list
  List<Map<String, dynamic>> trips = [];

  // Store available directions dynamically
  List<String> availableDirections = [];

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

    // Auto-generate trips when tripsCtrl changes
    tripsCtrl.addListener(() {
      final text = tripsCtrl.text;
      if (text.isNotEmpty) {
        int numTrips = int.tryParse(text) ?? 0;
        if (numTrips != trips.length) {
          trips = List.generate(numTrips, (index) {
            return {
              "direction": null,
              "startTime": TextEditingController(),
              "arrivalTime": TextEditingController(),
            };
          });
          setState(() {});
        }
      } else {
        if (trips.isNotEmpty) {
          trips = [];
          setState(() {});
        }
      }
    });
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
                    imageField(
                      label: "Driver Profile Photo",
                      onSaved: (f) => driverPhoto = f,
                    ),

                    section("2. Driving & Identity Verification"),
                    field(licenseNoCtrl, "Driving License Number"),
                    const SizedBox(height: 12),
                    datePickerField(
                      controller: licenseExpiryCtrl,
                      label: "License Expiry Date",
                    ),
                    const SizedBox(height: 12),
                    imageField(
                      label: "License Photo",
                      onSaved: (f) => licensePhoto = f,
                    ),

                    section("3. Conductor Details"),
                    field(conductorNameCtrl, "Conductor Name"),
                    const SizedBox(height: 12),
                    field(conductorPhoneCtrl, "Conductor Contact"),
                    const SizedBox(height: 12),
                    imageField(
                      label: "Conductor Photo",
                      onSaved: (f) => conductorPhoto = f,
                    ),

                    section("4. Bus & Route Details"),
                    field(busNoCtrl, "Bus Number"),
                    const SizedBox(height: 12),
                    dropdown(
                      value: busType,
                      hint: "Bus Type",
                      items: ["AC", "Non-AC", "School", "Private", "CTB"],
                      onChanged: (v) => setState(() => busType = v),
                    ),
                    const SizedBox(height: 12),
                    field(routeNoCtrl, "Route Number"),
                    const SizedBox(height: 12),
                    dropdown(
                      value: routeName,
                      hint: "Route Name",
                      items: [
                        "Badulla - Colombo",
                        "Kandy - Colombo",
                        "Badulla - Bandarawela",
                        "Bandarawela - Welimada",
                        "Galkissa - Kottawa",
                      ],
                      onChanged: (v) {
                        setState(() {
                          routeName = v;
                          if (v != null) {
                            var parts = v.split(" - ");
                            availableDirections = [
                              "${parts[0]} - ${parts[1]}",
                              "${parts[1]} - ${parts[0]}",
                            ];
                            for (var trip in trips) {
                              trip["direction"] = null;
                            }
                          } else {
                            availableDirections = [];
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    field(depotCtrl, "Depot / Company Name"),
                    const SizedBox(height: 12),
                    field(tripsCtrl, "Trips Per Day"),
                    const SizedBox(height: 16),

                    // ---------- Dynamic Time Table ----------
                    if (trips.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "Time Table",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...trips.asMap().entries.map((entry) {
                        int idx = entry.key;
                        var trip = entry.value;
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color.fromARGB(
                              255,
                              83,
                              83,
                              83,
                            ).withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Trip ${idx + 1}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              dropdown(
                                value: trip["direction"],
                                hint: "Direction",
                                items: availableDirections,
                                onChanged: (v) =>
                                    setState(() => trip["direction"] = v),
                              ),
                              const SizedBox(height: 8),
                              timePickerField(
                                controller: trip["startTime"],
                                label: "Start Time",
                              ),
                              const SizedBox(height: 8),
                              timePickerField(
                                controller: trip["arrivalTime"],
                                label: "Arrival Time",
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

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
      validator: (v) => v!.isEmpty ? "Required" : null,
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
        validator: (v) => v == null ? "Required" : null,
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
      validator: (v) => v!.isEmpty ? "Required" : null,
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

  // ---------- Submit Function ----------
  void submit() async {
    if (_formKey.currentState!.validate()) {
      if (driverPhoto == null ||
          licensePhoto == null ||
          conductorPhoto == null) {
        Fluttertoast.showToast(msg: "Please upload all required photos");
        return;
      }

      try {
        String driverPhotoUrl = "";
        String licensePhotoUrl = "";
        String conductorPhotoUrl = "";

        final storage = FirebaseStorage.instance;

        // Upload images
        driverPhotoUrl =
            await (await storage
                    .ref("drivers/${phoneCtrl.text}/driver.jpg")
                    .putFile(driverPhoto!))
                .ref
                .getDownloadURL();
        licensePhotoUrl =
            await (await storage
                    .ref("drivers/${phoneCtrl.text}/license.jpg")
                    .putFile(licensePhoto!))
                .ref
                .getDownloadURL();
        conductorPhotoUrl =
            await (await storage
                    .ref("drivers/${phoneCtrl.text}/conductor.jpg")
                    .putFile(conductorPhoto!))
                .ref
                .getDownloadURL();

        // Save data to Firestore
        await FirebaseFirestore.instance
            .collection("drivers")
            .doc(phoneCtrl.text)
            .set({
              "name": nameCtrl.text,
              "nic": nicCtrl.text,
              "phone": phoneCtrl.text,
              "email": emailCtrl.text,
              "password": passwordCtrl.text,
              "licenseNo": licenseNoCtrl.text,
              "licenseExpiry": licenseExpiryCtrl.text,
              "conductorName": conductorNameCtrl.text,
              "conductorPhone": conductorPhoneCtrl.text,
              "busNo": busNoCtrl.text,
              "busType": busType,
              "routeNo": routeNoCtrl.text,
              "routeName": routeName,
              "depot": depotCtrl.text,
              "tripsPerDay": tripsCtrl.text,
              "trips": trips
                  .map(
                    (t) => {
                      "direction": t["direction"],
                      "startTime": t["startTime"].text,
                      "arrivalTime": t["arrivalTime"].text,
                    },
                  )
                  .toList(),
              "driverPhotoUrl": driverPhotoUrl,
              "licensePhotoUrl": licensePhotoUrl,
              "conductorPhotoUrl": conductorPhotoUrl,
              "createdAt": FieldValue.serverTimestamp(),
            });

        Fluttertoast.showToast(
          msg: "Driver registered successfully! Please login.",
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        // Navigate back to previous screen (login) to avoid circular import
        Navigator.pop(context);
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error: $e",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }
}

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:school_test/models/AddFullScreeningRequest.dart';
import 'package:school_test/models/DetectedDiseaseRequest.dart';
import 'package:school_test/models/ReferralDiseaseRequest.dart';
import 'package:school_test/models/ReferralRequest.dart';
// import 'package:school_test/config/endpoints.dart';
import 'package:school_test/screens/anganWadi_screening-forms/anganwadi_screening_form1.dart';
import 'package:http/http.dart' as http;
import 'package:school_test/screens/student_info_screen.dart';
import 'package:school_test/utils/error_popup.dart';

class AnganWadiScreeningFormSeven extends StatefulWidget {
  final Map<String, dynamic> combinedData;

  const AnganWadiScreeningFormSeven({super.key, required this.combinedData});

  @override
  State<AnganWadiScreeningFormSeven> createState() =>
      _AnganWadiScreeningFormSevenState();
}

class _AnganWadiScreeningFormSevenState
    extends State<AnganWadiScreeningFormSeven> {
  final TextEditingController _doctorNameController = TextEditingController();

  /// Logger instance
  final _logger = Logger();
  // Location state
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;
  bool _isLoading = false;
  late String className;
  // Disease categories mapping with exact C# model field names
  // CORRECTED Disease categories mapping - matches backend model exactly

  @override
  void initState() {
    super.initState();
    _doctorNameController.text = widget.combinedData['DoctorName'];

    debugPrint("=== Form 7 - Review & Submit ===");
    debugPrint("DoctorId: ${widget.combinedData['DoctorId']}");
    debugPrint("DoctorName: ${widget.combinedData['DoctorName']}");
    debugPrint("ClassName: ${widget.combinedData['ClassName']}");
    debugPrint(
      "Detected Diseases: ${widget.combinedData['allDetectedDiseases']}",
    );
    _logger.d(
      "DetectedDiseases: ${widget.combinedData['allDetectedDiseases']}",
    );
    _getCurrentLocation();
    className = widget.combinedData['ClassName'];
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    super.dispose();
  }

  /// Get current location using Geolocator
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception(
            'Location permission denied. Please grant permission in settings.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'Location permission permanently denied. Please enable in app settings.',
        );
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      print('=== LOCATION OBTAINED ===');
      print('Latitude: ${position.latitude}');
      print('Longitude: ${position.longitude}');
      print('Accuracy: ${position.accuracy}m');
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = e.toString();
      });

      print('=== LOCATION ERROR ===');
      print(e.toString());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location error: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Widget _buildDiseaseSummary(Map<String, dynamic> data) {
    // Get the detected diseases array
    List<dynamic> allDetectedDiseases = data['allDetectedDiseases'] ?? [];

    if (allDetectedDiseases.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No diseases detected from screening",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    // Group diseases by category for better display
    Map<int, List<Map<String, dynamic>>> groupedDiseases = {};
    for (var disease in allDetectedDiseases) {
      int categoryId = disease['categoryId'] ?? 0;
      if (!groupedDiseases.containsKey(categoryId)) {
        groupedDiseases[categoryId] = [];
      }
      groupedDiseases[categoryId]!.add(disease);
    }

    // Category names mapping
    Map<int, String> categoryNames = {
      1: 'A. Defects at Birth',
      2: 'B. Deficiencies at Birth',
      3: 'C. Diseases',
      4: 'D. Developmental Delay Including Disability',
      5: 'E. Adolescent Specific Questionnaire',
      6: 'F. Disability',
    };

    List<Widget> allWidgets = [];
    int diseaseCounter = 1;

    // Sort by category ID
    var sortedCategories = groupedDiseases.keys.toList()..sort();

    for (int categoryId in sortedCategories) {
      List<Map<String, dynamic>> diseases = groupedDiseases[categoryId]!;

      // Add category header
      allWidgets.add(
        Container(
          width: double.infinity,
          color: Colors.grey[200],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            categoryNames[categoryId] ?? 'Category $categoryId',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      );

      // Add diseases in this category
      for (var disease in diseases) {
        int diseaseId = disease['diseaseId'];
        String diseaseName = disease['diseaseName'] ?? 'Unknown';
        bool treated = disease['treated'] ?? false;
        bool referred = disease['referred'] ?? false;
        String hospitalName = disease['hospitalName'] ?? '';
        String note = disease['note'] ?? '';

        allWidgets.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$diseaseCounter. $diseaseName',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Treated checkbox
                    InkWell(
                      onTap: () {
                        setState(() {
                          disease['treated'] = !treated;
                          if (disease['treated']) {
                            disease['referred'] = false;
                          }
                        });
                      },
                      child: Row(
                        children: [
                          const Text(
                            'Treated  ',
                            style: TextStyle(fontSize: 15),
                          ),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                              color: Colors.white,
                            ),
                            child: treated
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Refer checkbox
                    InkWell(
                      onTap: () {
                        setState(() {
                          disease['referred'] = !referred;
                          if (disease['referred']) {
                            disease['treated'] = false;
                          }
                        });
                      },
                      child: Row(
                        children: [
                          const Text('Refer  ', style: TextStyle(fontSize: 15)),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[400]!,
                                width: 2,
                              ),
                              color: Colors.white,
                            ),
                            child: referred
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.blue,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Hospital name
                    if (referred && hospitalName.isNotEmpty)
                      Expanded(
                        child: Text(
                          hospitalName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Note field
                if (treated || referred)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        treated ? 'Enter Treated Note' : 'Enter Refer Note',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: TextField(
                          controller: TextEditingController(text: note),
                          onChanged: (value) {
                            disease['note'] = value;
                          },
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(12),
                          ),
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
        diseaseCounter++;
      }
    }

    return ListView(children: allWidgets);
  }

  Future<void> _submitForm() async {
    if (_doctorNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter doctor name"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _locationError != null
                ? "Location unavailable: $_locationError"
                : "Getting location... Please wait",
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: _getCurrentLocation,
          ),
        ),
      );

      if (!_isLoadingLocation) {
        await _getCurrentLocation();
      }
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Submitting form...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      setState(() => _isLoading = true);

      // =============================
      // ✅ BUILD DETECTED DISEASE MODELS
      // =============================
      List<dynamic> allDetectedDiseases =
          widget.combinedData['allDetectedDiseases'] ?? [];

      List<DetectedDiseaseRequest> detectedDiseasesModels = allDetectedDiseases
          .map<DetectedDiseaseRequest>((disease) {
            int diseaseId = disease['diseaseId'];
            bool treated = disease['treated'] ?? false;
            bool referred = disease['referred'] ?? false;
            String note = disease['note'] ?? '';

            ReferralRequest? referral;

            if (referred && disease['hospitalId'] != null) {
              referral = ReferralRequest(
                hospitalId: disease['hospitalId'],
                referralDate: DateTime.now(),
                referralNotes: note.isNotEmpty ? note : null,
                treatmentDate: DateTime.now(),
                treatmentNotes: treated ? note : null,
                referralDiseases: [
                  ReferralDiseaseRequest(diseaseId: diseaseId),
                ],
              );
            } else {
              referral = null; // ✅ BACKEND ALLOWS NULL
            }

            return DetectedDiseaseRequest(
              diseaseId: diseaseId,
              treatedAtScreening: treated,
              detectionNotes: note.isNotEmpty ? note : "",
              treatmentNotes: treated && note.isNotEmpty ? note : "",
              referral: referral,
            );
          })
          .toList();

      // =============================
      // ✅ BUILD PAYLOAD USING MODEL
      // =============================
      final payload = AddFullScreeningRequest(
        studentId: widget.combinedData['StudentId'],
        schoolId: widget.combinedData['SchoolId'],
        teamId: widget.combinedData['TeamId'],
        doctorId: widget.combinedData['DoctorId'],
        screeningDate: DateTime.now(),

        // ✅ NUMBERS STAY NUMBERS, NULL STAYS NULL
        weightKg: widget.combinedData['WeightInKg'] == null
            ? null
            : double.parse(widget.combinedData['WeightInKg'].toString()),

        heightCm: widget.combinedData['HeightInCm'] == null
            ? null
            : double.parse(widget.combinedData['HeightInCm'].toString()),

        bmi: widget.combinedData['bmi'] == null
            ? null
            : double.parse(widget.combinedData['bmi'].toString()),

        bloodPressure: widget.combinedData['bloodPressure'] ?? "",
        visionLeft: widget.combinedData['visionLeft'] ?? "",
        visionRight: widget.combinedData['visionRight'] ?? "",
        requiresReferral: widget.combinedData['requiresReferral'] ?? false,

        latitude: _currentPosition?.latitude,
        longitude: _currentPosition?.longitude,

        createdBy: widget.combinedData['UserId'].toString(),
        screeningStatus: "Completed",

        detectedDiseases: detectedDiseasesModels,
      ).toJson(); // ✅ payload is Map<String, dynamic>

      debugPrint("=== FINAL PAYLOAD Anganwadi ===\n${json.encode(payload)}");

      final url = Uri.parse(
        "https://NewAPIS.rbsknagpur.in/api/Rbsk/AddFullScreening",
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      _logger.i("=== RESPONSE ===");
      _logger.i("Status Code: ${response.statusCode}");
      _logger.i("Body: ${response.body}");
      debugPrint("=== RESPONSE ===\n${response.body}");

      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode == 200) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Form submitted successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );

          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => StudentInfoScreen(
                className: className,
                isSchool: false,
                teamName: _doctorNameController.text.trim(),
                schoolId: widget.combinedData['SchoolId'],
                schoolName: widget.combinedData['SchoolName'],
                doctorId: widget.combinedData['DoctorId'],
              ),
            ),
            (Route<dynamic> route) => false,
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${response.body}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();

      _logger.f("Error submitting form: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again later.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Screening Form ",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "7/7",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor Name and Location Status
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Doctor Name
                Row(
                  children: const [
                    Text(
                      "Doctor Name",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    Text(" *", style: TextStyle(color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: TextField(
                    controller: _doctorNameController,
                    decoration: const InputDecoration(
                      hintText: "Enter doctor name",
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Location Status Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _currentPosition != null
                        ? Colors.green[50]
                        : _locationError != null
                        ? Colors.red[50]
                        : Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentPosition != null
                          ? Colors.green
                          : _locationError != null
                          ? Colors.red
                          : Colors.blue,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _currentPosition != null
                            ? Icons.location_on
                            : _isLoadingLocation
                            ? Icons.location_searching
                            : Icons.location_off,
                        color: _currentPosition != null
                            ? Colors.green
                            : _locationError != null
                            ? Colors.red
                            : Colors.blue,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPosition != null
                                  ? 'Location obtained'
                                  : _isLoadingLocation
                                  ? 'Getting location...'
                                  : 'Location unavailable',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: _currentPosition != null
                                    ? Colors.green[700]
                                    : _locationError != null
                                    ? Colors.red[700]
                                    : Colors.blue[700],
                              ),
                            ),
                            if (_currentPosition != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Lat: ${_currentPosition!.latitude.toStringAsFixed(6)}, '
                                'Lon: ${_currentPosition!.longitude.toStringAsFixed(6)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                            if (_locationError != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _locationError!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (_locationError != null || _currentPosition == null)
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isLoadingLocation
                              ? null
                              : _getCurrentLocation,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // Disease summary (expanded list)
          Expanded(child: _buildDiseaseSummary(widget.combinedData)),

          // Submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
            child: ElevatedButton(
              onPressed: _isLoadingLocation ? null : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5568),
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isLoadingLocation ? "Getting Location..." : "Submit",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

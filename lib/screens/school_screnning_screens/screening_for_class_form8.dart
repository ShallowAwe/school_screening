import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:logger/logger.dart';
import 'package:school_test/models/diseases_model.dart';
import 'package:school_test/models/hospitals_model.dart';
import 'package:school_test/screens/student_info_screen.dart';
import 'package:http/http.dart' as http;

class ScreeningForClassFormEight extends StatefulWidget {
  final Map<String, dynamic> combinedData;

  const ScreeningForClassFormEight({super.key, required this.combinedData});

  @override
  State<ScreeningForClassFormEight> createState() =>
      _ScreeningForClassFormEightState();
}

class _ScreeningForClassFormEightState
    extends State<ScreeningForClassFormEight> {
  bool _isLoading = false;
  final _doctorNameController = TextEditingController();
  final _logger = Logger();

  // Location state
  Position? _currentPosition;
  bool _isLoadingLocation = false;
  String? _locationError;

  // Disease and hospital data
  Map<int, Disease> diseasesMap = {};
  Map<int, String> diseaseCategoryMap = {}; // Added to track category names
  Map<int, Hospital> hospitalsMap = {};
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _logger.i('=== COMBINED DATA RECEIVED IN FORM 8 ===');
    _logger.i(json.encode(widget.combinedData));
    debugPrint('Combined Data: ${widget.combinedData.toString()}');

    // Initialize doctor name from previous data if available
    if (widget.combinedData['DoctorName'] != null) {
      _doctorNameController.text = widget.combinedData['DoctorName'].toString();
    }

    _getCurrentLocation();
    _loadDiseasesAndHospitals();
  }

  @override
  void dispose() {
    _doctorNameController.dispose();
    super.dispose();
  }

  void _showLoader() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _hideLoader() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submission Failed"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  /// Load all diseases and hospitals from API
  Future<void> _loadDiseasesAndHospitals() async {
    setState(() => _isLoadingData = true);

    try {
      // Fetch hospitals
      final hospitalsUrl = Uri.parse(
        "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetHospitals",
      );
      final hospitalsResponse = await http.get(hospitalsUrl);

      if (hospitalsResponse.statusCode == 200) {
        final hospitalsData = jsonDecode(hospitalsResponse.body);
        if (hospitalsData['success'] == true) {
          final hospitalsList = (hospitalsData['data'] as List)
              .map((e) => Hospital.fromJson(e))
              .toList();

          for (var hospital in hospitalsList) {
            hospitalsMap[hospital.hospitalId] = hospital;
          }
        }
      }

      // Fetch diseases from all categories (1-6)
      for (int categoryId = 1; categoryId <= 6; categoryId++) {
        final diseasesUrl = Uri.parse(
          "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetDiseaseByCategoryId?categoryId=$categoryId",
        );
        final diseasesResponse = await http.get(diseasesUrl);

        if (diseasesResponse.statusCode == 200) {
          final diseasesData = jsonDecode(diseasesResponse.body);
          if (diseasesData['success'] == true) {
            final categoryResponse = DiseaseCategoryResponse.fromJson(
              diseasesData['data'],
            );

            for (var disease in categoryResponse.diseases) {
              diseasesMap[disease.diseaseId] = disease;
              diseaseCategoryMap[disease.diseaseId] =
                  categoryResponse.categoryName;
            }
          }
        }
      }

      setState(() => _isLoadingData = false);
      _logger.i(
        'Loaded ${diseasesMap.length} diseases and ${hospitalsMap.length} hospitals',
      );
    } catch (e) {
      setState(() => _isLoadingData = false);
      _logger.e('Error loading diseases and hospitals: $e');
    }
  }

  /// Get current location using Geolocator
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled. Please enable GPS.');
      }

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

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _currentPosition = position;
        _isLoadingLocation = false;
      });

      // _logger.i('=== LOCATION OBTAINED ===');
      // _logger.i('Latitude: ${position.latitude}');
      // _logger.i('Longitude: ${position.longitude}');
    } catch (e) {
      setState(() {
        _isLoadingLocation = false;
        _locationError = e.toString();
      });

      _logger.e('=== LOCATION ERROR ===');
      _logger.e(e.toString());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location error: ${e.toString()}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Build disease summary from detectedDiseases array
  Widget _buildDiseaseSummary() {
    if (_isLoadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    List<Map<String, dynamic>> detectedDiseases = [];
    if (widget.combinedData['detectedDiseases'] != null &&
        widget.combinedData['detectedDiseases'] is List) {
      detectedDiseases = List<Map<String, dynamic>>.from(
        (widget.combinedData['detectedDiseases'] as List).map(
          (e) => e as Map<String, dynamic>,
        ),
      );
    }

    if (detectedDiseases.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            "No diseases selected from previous forms",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: detectedDiseases.length,
      itemBuilder: (context, index) {
        final diseaseData = detectedDiseases[index];
        final diseaseId = diseaseData['diseaseId'];
        final disease = diseasesMap[diseaseId];
        final categoryName =
            diseaseCategoryMap[diseaseId] ?? 'Unknown Category';

        if (disease == null) {
          return const SizedBox.shrink();
        }

        final isTreated = diseaseData['treatedAtScreening'] ?? false;
        final notes = diseaseData['detectionNotes'] ?? '';
        final referral = diseaseData['referral'];

        String hospitalName = '';
        if (referral != null && referral is Map) {
          final hospitalId = referral['hospitalId'];
          if (hospitalId != null) {
            final hospital = hospitalsMap[hospitalId];
            hospitalName = hospital?.hospitalName ?? 'Unknown Hospital';
          }
        }

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${index + 1}. ${disease.diseaseName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Category: $categoryName',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      isTreated ? Icons.check_circle : Icons.local_hospital,
                      color: isTreated ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTreated ? 'Treated' : 'Referred',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isTreated ? Colors.green : Colors.orange,
                      ),
                    ),
                    if (!isTreated && hospitalName.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      const Text('→', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
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
                  ],
                ),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notes:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(notes, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
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
        ),
      );
      return;
    }

    _showLoader();

    try {
      setState(() => _isLoading = true);

      // ============================
      // BUILD DETECTED DISEASES ARRAY
      // ============================
      final rawDiseases = widget.combinedData['detectedDiseases'];
      List<dynamic> allDetectedDiseases = rawDiseases is List
          ? rawDiseases
          : [];

      // ✅ Build diseases array directly as Map
      List<Map<String, dynamic>> detectedDiseasesPayload = [];

      for (var disease in allDetectedDiseases) {
        final int diseaseId = disease['diseaseId'];
        final bool treated = disease['treatedAtScreening'] ?? false;

        // ✅ Always strings, never null
        final String detectionNotes =
            disease['detectionNotes']?.toString() ?? "";

        // ✅ Handle treatmentNotes - convert null to empty string
        final dynamic rawTreatmentNotes = disease['treatmentNotes'];
        final String finalTreatmentNotes =
            (rawTreatmentNotes == null ||
                rawTreatmentNotes.toString().trim().isEmpty)
            ? ""
            : rawTreatmentNotes.toString();

        // ✅ ALWAYS create referral object
        Map<String, dynamic> referralPayload;

        if (disease['referral'] != null &&
            disease['referral']['hospitalId'] != null) {
          // Use existing referral data
          final referralData = disease['referral'];
          referralPayload = {
            "hospitalId": referralData['hospitalId'],
            "referralDate":
                referralData['referralDate'] ??
                DateTime.now().toIso8601String(),
            "referralNotes": referralData['referralNotes']?.toString() ?? "",
            "treatmentDate": referralData['treatmentDate'],
            "treatmentNotes":
                referralData['treatmentNotes']?.toString() ??
                "", // ✅ Never null
            "referralDiseases": [
              {"diseaseId": diseaseId},
            ],
          };
        } else {
          // ✅ Create default referral
          final now = DateTime.now().toIso8601String();
          referralPayload = {
            "hospitalId": 1,
            "referralDate": now,
            "referralNotes": treated
                ? "Treated at screening - no external referral needed"
                : "Pending referral",
            "treatmentDate": treated ? now : null,
            "treatmentNotes": "", // ✅ Always empty string, never null
            "referralDiseases": [
              {"diseaseId": diseaseId},
            ],
          };
        }

        // Add disease to payload
        detectedDiseasesPayload.add({
          "diseaseId": diseaseId,
          "treatedAtScreening": treated,
          "detectionNotes": detectionNotes,
          "treatmentNotes": finalTreatmentNotes, // ✅ Always string, never null
          "referral": referralPayload,
        });
      }

      // ============================
      // BUILD FINAL PAYLOAD
      // ============================
      final payload = {
        "studentId": widget.combinedData['StudentId'],
        "schoolId": widget.combinedData['SchoolId'],
        "teamId": widget.combinedData['TeamId'],
        "doctorId": widget.combinedData['DoctorId'],
        "screeningDate": DateTime.now().toIso8601String(),
        "weightKg": _forceDouble(widget.combinedData['WeightInKg']),
        "heightCm": _forceDouble(widget.combinedData['HeightInCm']),
        "bmi": _forceDouble(widget.combinedData['bmi']),
        "bloodPressure": _forceString(
          widget.combinedData['bloodPressure'] ??
              widget.combinedData['BloodPressure'],
        ),
        "visionLeft": _forceString(widget.combinedData['AcuityOfLeftEye']),
        "visionRight": _forceString(widget.combinedData['AcuityOfRightEye']),
        "requiresReferral": widget.combinedData['requiresReferral'] ?? false,
        "latitude": _currentPosition?.latitude,
        "longitude": _currentPosition?.longitude,
        "createdBy": widget.combinedData['UserId'].toString(),
        "screeningStatus": "Completed",
        "detectedDiseases": detectedDiseasesPayload, // ✅ Direct Map array
      };

      // ============================
      // DEBUG LOGGING
      // ============================
      debugPrint("=== FINAL PAYLOAD ===");
      debugPrint(json.encode(payload));

      debugPrint("\n=== DETECTED DISEASES DEBUG ===");
      for (var i = 0; i < detectedDiseasesPayload.length; i++) {
        final disease = detectedDiseasesPayload[i];
        debugPrint("Disease $i:");
        debugPrint("  - diseaseId: ${disease['diseaseId']}");
        debugPrint("  - treatedAtScreening: ${disease['treatedAtScreening']}");
        debugPrint("  - referral exists: ${disease['referral'] != null}");
        if (disease['referral'] != null) {
          debugPrint("  - hospitalId: ${disease['referral']['hospitalId']}");
          debugPrint(
            "  - referralNotes: ${disease['referral']['referralNotes']}",
          );
        }
      }

      // ============================
      // DEBUG LOGGING
      // ============================
      _logPayloadDetails(payload);

      // ============================
      // API CALL
      // ============================
      final response = await http.post(
        Uri.parse("https://NewAPIS.rbsknagpur.in/api/Rbsk/AddFullScreening"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(payload),
      );

      _hideLoader();

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint("Response: ${response.body}");
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            title: const Text("Success"),
            content: const Text("Form submitted successfully."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => StudentInfoScreen(
                        className:
                            widget.combinedData['ClassName'] ?? "FirstClass",
                        isSchool: true,
                        teamName: _doctorNameController.text.trim(),
                        schoolId: widget.combinedData['SchoolId'] ?? 0,
                        schoolName:
                            widget.combinedData['SchoolName'] ?? 'Unknown',
                        doctorId: widget.combinedData['DoctorId'] ?? 0,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("OK"),
              ),
            ],
          ),
        );
      } else {
        debugPrint("Server Error (${response.statusCode})\n\n${response.body}");
        _showErrorDialog(
          "Server Error (${response.statusCode})\n\n${response.body}",
        );
      }
    } catch (e) {
      _hideLoader();
      debugPrint("Unexpected error:\n$e");
      _showErrorDialog("Unexpected error:\n$e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logPayloadDetails(Map<String, dynamic> payload) {
    debugPrint("\n" + "=" * 50);
    debugPrint("PAYLOAD VALIDATION CHECK");
    debugPrint("=" * 50);

    debugPrint("✓ Student ID: ${payload['studentId']}");
    debugPrint("✓ School ID: ${payload['schoolId']}");
    debugPrint("✓ Weight: ${payload['weightKg']} kg");
    debugPrint("✓ Height: ${payload['heightCm']} cm");
    debugPrint("✓ BMI: ${payload['bmi']}");
    debugPrint("✓ Blood Pressure: ${payload['bloodPressure']}");
    debugPrint("✓ Location: (${payload['latitude']}, ${payload['longitude']})");

    final diseases = payload['detectedDiseases'] as List;
    debugPrint("\n✓ Total Diseases: ${diseases.length}");

    for (var i = 0; i < diseases.length; i++) {
      final disease = diseases[i];
      debugPrint("\n  Disease #${i + 1}:");
      debugPrint("    - ID: ${disease['diseaseId']}");
      debugPrint("    - Treated: ${disease['treatedAtScreening']}");
      debugPrint(
        "    - Has Referral: ${disease['referral'] != null ? '✓ YES' : '✗ NO (ERROR!)'}",
      );

      if (disease['referral'] != null) {
        final ref = disease['referral'];
        debugPrint("    - Hospital ID: ${ref['hospitalId']}");
        debugPrint("    - Referral Note: ${ref['referralNotes']}");
        debugPrint(
          "    - Referral Diseases: ${ref['referralDiseases']?.length ?? 0}",
        );
      }
    }

    debugPrint("\n" + "=" * 50);
    debugPrint("JSON OUTPUT:");
    debugPrint(json.encode(payload));
    debugPrint("=" * 50 + "\n");
  }

  double _forceDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  // Add this helper method to safely convert values to String
  String _forceString(dynamic value) {
    if (value == null) return "";
    if (value is String) return value;
    return value.toString();
  }

  DateTime _safeParseDate(dynamic v) {
    if (v == null) return DateTime.now();
    final s = v.toString().trim();
    if (s.isEmpty) return DateTime.now();
    return DateTime.parse(s);
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
        title: const Text(
          "Screening Form - Preview",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "8/8",
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
                const Row(
                  children: [
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

          // Disease summary header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.medical_services, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Detected Diseases',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          // Disease summary (expanded list)
          Expanded(child: _buildDiseaseSummary()),

          // Submit button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 25),
            child: ElevatedButton(
              onPressed: _isLoadingLocation || _isLoadingData
                  ? null
                  : _submitForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5568),
                disabledBackgroundColor: Colors.grey,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                _isLoadingLocation
                    ? "Getting Location..."
                    : _isLoadingData
                    ? "Loading Data..."
                    : "Submit",
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

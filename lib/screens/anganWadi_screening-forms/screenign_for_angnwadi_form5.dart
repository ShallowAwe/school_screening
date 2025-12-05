import 'package:flutter/material.dart';
import 'package:logger/web.dart';
import 'package:school_test/models/diseases_model.dart';
import 'package:school_test/models/hospitals_model.dart';
import 'package:school_test/screens/anganWadi_screening-forms/screening_for_anganwadi_form6.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScreenignForAngnwadiFormFive extends StatefulWidget {
  final Map<String, dynamic> previousData;
  const ScreenignForAngnwadiFormFive({super.key, required this.previousData});

  @override
  State<ScreenignForAngnwadiFormFive> createState() =>
      _ScreenignForAngnwadiFormFiveState();
}

class _ScreenignForAngnwadiFormFiveState
    extends State<ScreenignForAngnwadiFormFive> {
  // State management
  bool hasNoDiseases = true;
  bool hasYesDiseases = false;

  // NEW: Dynamic disease approach
  late List<Disease> diseases = [];
  bool _isLoadingDiseases = false;
  String? _diseaseError;

  Map<int, bool> selectedDiseases = {};
  Map<int, String> diseaseTreatment = {};
  String currentDeseaseCategory = '';
  Map<int, int?> diseaseReferralHospital = {};
  final Map<int, TextEditingController> _diseaseNoteControllers = {};
  Logger _logger = Logger();
  // Hospitals
  late List<Hospital> hospitals = [];
  bool _isLoadingHospitals = false;

  @override
  void initState() {
    super.initState();
    print(
      "Anganwadi Form 5 - Category: Developmental Delay Including Disability (categoryId: 4)",
    );
    fetchDiseaseCategory(); // 4 = DevelopmentalDelayIncludingDisability
    fetchHospitals();
  }

  Future<void> fetchDiseaseCategory() async {
    print('🟢 Starting fetchDiseaseCategory...');
    final url = Uri.parse(
      "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetDiseaseByCategoryId?categoryId=4",
    );
    try {
      print('🟢 Making request to: $url');
      final response = await http.get(url);
      print('🟢 Response status code: ${response.statusCode}');
      print('🟢 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🟢 Decoded data: $data');

        if (data['success'] == true) {
          final categoryResponse = DiseaseCategoryResponse.fromJson(
            data['data'],
          );
          print('🟢 Parsed ${categoryResponse.diseases.length} diseases');

          setState(() {
            currentDeseaseCategory = categoryResponse.categoryName;
            diseases = categoryResponse.diseases;

            // Initialize maps for each disease
            for (var disease in diseases) {
              selectedDiseases[disease.diseaseId] = false;
              diseaseTreatment[disease.diseaseId] = '';
              diseaseReferralHospital[disease.diseaseId] = null;
              _diseaseNoteControllers[disease.diseaseId] =
                  TextEditingController();
            }

            _logger.d("Diseases loaded: ${diseases.length}");
            _logger.i("Current Disease Category: $currentDeseaseCategory");
          });
        }
      }
    } catch (e) {
      print('❌ Exception in fetchDiseaseCategory: $e');
      _logger.e('Error: $e');
    }
  }

  Future<void> fetchHospitals() async {
    setState(() {
      _isLoadingHospitals = true;
    });

    final url = Uri.parse(
      "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetHospitals",
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          setState(() {
            hospitals = (data['data'] as List)
                .map((e) => Hospital.fromJson(e))
                .toList();
            _isLoadingHospitals = false;
          });
          print('🔵 Loaded ${hospitals.length} hospitals');
        }
      }
    } catch (e) {
      print('❌ Error fetching hospitals: $e');
      setState(() {
        _isLoadingHospitals = false;
      });
    }
  }

  void _showReferralPopup(int diseaseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Referral Hospital',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(Icons.close, color: Colors.grey[600]),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                if (_isLoadingHospitals)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (hospitals.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('No hospitals available'),
                  )
                else
                  ...hospitals.asMap().entries.map((entry) {
                    int index = entry.key;
                    Hospital hospital = entry.value;

                    return Column(
                      children: [
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              diseaseReferralHospital[diseaseId] =
                                  hospital.hospitalId;
                            });
                            Navigator.of(context).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 8,
                            ),
                            child: Text(
                              '${index + 1}. ${hospital.hospitalName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                        if (index < hospitals.length - 1)
                          Divider(height: 1, color: Colors.grey[300]),
                      ],
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _buildOutputData() {
    Map<String, dynamic> outputData = Map<String, dynamic>.from(
      widget.previousData,
    );

    outputData['developmentalDelayIncludingDisability'] = hasYesDiseases;

    // Collect diseases for this category
    List<Map<String, dynamic>> detectedDiseases = [];

    if (hasYesDiseases) {
      selectedDiseases.forEach((diseaseId, isSelected) {
        if (isSelected) {
          detectedDiseases.add({
            'diseaseId': diseaseId,
            'diseaseName': diseases
                .firstWhere((d) => d.diseaseId == diseaseId)
                .diseaseName,
            'categoryId': 4, // DevelopmentalDelayIncludingDisability
            'treated': diseaseTreatment[diseaseId] == 'Treated',
            'referred': diseaseTreatment[diseaseId] == 'Refer',
            'hospitalId': diseaseReferralHospital[diseaseId],
            'hospitalName': diseaseReferralHospital[diseaseId] != null
                ? hospitals
                      .firstWhere(
                        (h) =>
                            h.hospitalId == diseaseReferralHospital[diseaseId],
                      )
                      .hospitalName
                : null,
            'note': _diseaseNoteControllers[diseaseId]?.text ?? '',
          });
        }
      });
    }

    // Append to existing detected diseases
    if (!outputData.containsKey('allDetectedDiseases')) {
      outputData['allDetectedDiseases'] = [];
    }
    outputData['allDetectedDiseases'].addAll(detectedDiseases);

    print('📋 Form 5 - Detected Diseases: $detectedDiseases');

    return outputData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Color(0xFF2196F3),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Screening Form",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '5/7',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'D. Developmental Delay\nIncluding Disability',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Text('No', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          hasNoDiseases = true;
                          hasYesDiseases = false;
                          selectedDiseases.updateAll((key, value) => false);
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: hasNoDiseases
                              ? Color(0xFF2196F3)
                              : Colors.transparent,
                          border: Border.all(
                            color: hasNoDiseases
                                ? Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: hasNoDiseases
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                    SizedBox(width: 16),
                    Text('Yes', style: TextStyle(fontSize: 16)),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          hasNoDiseases = false;
                          hasYesDiseases = true;
                        });
                      },
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: hasYesDiseases
                              ? Color(0xFF2196F3)
                              : Colors.transparent,
                          border: Border.all(
                            color: hasYesDiseases
                                ? Color(0xFF2196F3)
                                : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: hasYesDiseases
                            ? Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            SizedBox(height: 24),

            if (hasYesDiseases) ...[
              if (_isLoadingDiseases)
                Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_diseaseError != null)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    _diseaseError!,
                    style: TextStyle(color: Colors.red),
                  ),
                )
              else if (diseases.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Text('No diseases found for this category'),
                )
              else
                ...diseases.asMap().entries.map((entry) {
                  int index = entry.key;
                  Disease disease = entry.value;
                  int diseaseId = disease.diseaseId;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${index + 1}. ${disease.diseaseName}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedDiseases[diseaseId] =
                                    !selectedDiseases[diseaseId]!;
                                if (!selectedDiseases[diseaseId]!) {
                                  diseaseTreatment[diseaseId] = '';
                                  diseaseReferralHospital[diseaseId] = null;
                                  _diseaseNoteControllers[diseaseId]?.clear();
                                }
                              });
                            },
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: selectedDiseases[diseaseId]!
                                    ? Color(0xFF2196F3)
                                    : Colors.transparent,
                                border: Border.all(
                                  color: selectedDiseases[diseaseId]!
                                      ? Color(0xFF2196F3)
                                      : Colors.grey,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                              child: selectedDiseases[diseaseId]!
                                  ? Icon(
                                      Icons.check,
                                      color: Colors.white,
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),

                      if (selectedDiseases[diseaseId]!) ...[
                        SizedBox(height: 16),
                        Padding(
                          padding: EdgeInsets.only(left: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    'Treated',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        diseaseTreatment[diseaseId] = 'Treated';
                                        diseaseReferralHospital[diseaseId] =
                                            null;
                                      });
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color:
                                            diseaseTreatment[diseaseId] ==
                                                'Treated'
                                            ? Color(0xFF2196F3)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              diseaseTreatment[diseaseId] ==
                                                  'Treated'
                                              ? Color(0xFF2196F3)
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child:
                                          diseaseTreatment[diseaseId] ==
                                              'Treated'
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                  ),
                                  SizedBox(width: 24),
                                  Text('Refer', style: TextStyle(fontSize: 16)),
                                  SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        diseaseTreatment[diseaseId] = 'Refer';
                                      });
                                      _showReferralPopup(diseaseId);
                                    },
                                    child: Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color:
                                            diseaseTreatment[diseaseId] ==
                                                'Refer'
                                            ? Color(0xFF2196F3)
                                            : Colors.transparent,
                                        border: Border.all(
                                          color:
                                              diseaseTreatment[diseaseId] ==
                                                  'Refer'
                                              ? Color(0xFF2196F3)
                                              : Colors.grey,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                      child:
                                          diseaseTreatment[diseaseId] == 'Refer'
                                          ? Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            )
                                          : null,
                                    ),
                                  ),
                                  if (diseaseTreatment[diseaseId] == 'Refer' &&
                                      diseaseReferralHospital[diseaseId] !=
                                          null) ...[
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        hospitals
                                            .firstWhere(
                                              (h) =>
                                                  h.hospitalId ==
                                                  diseaseReferralHospital[diseaseId],
                                            )
                                            .hospitalName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              SizedBox(height: 16),
                              Text(
                                diseaseTreatment[diseaseId] == 'Treated'
                                    ? 'Enter Treated Note'
                                    : 'Enter Refer Note',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                child: TextField(
                                  controller:
                                      _diseaseNoteControllers[diseaseId],
                                  maxLines: 1,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.grey,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF2196F3),
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    contentPadding: EdgeInsets.all(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 24),
                      ] else ...[
                        SizedBox(height: 16),
                      ],
                    ],
                  );
                }),
            ],

            SizedBox(height: 40),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.only(bottom: 25.0),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5568),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Previous',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Map<String, dynamic> combinedData =
                              _buildOutputData();

                          // Debug print
                          print('Combined Data: $combinedData');

                          // Navigate to next page with combined data
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ScreeningForAngnwadiFormSix(
                                previousData: combinedData,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A5568),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (var controller in _diseaseNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }
}

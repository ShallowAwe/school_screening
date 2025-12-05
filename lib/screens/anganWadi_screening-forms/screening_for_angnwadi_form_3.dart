import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:school_test/models/diseases_model.dart';
import 'package:school_test/models/hospitals_model.dart';
import 'package:school_test/screens/anganWadi_screening-forms/screening_for_angnwadi_form4.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ScreeningFormAngnwadiScreenThree extends StatefulWidget {
  final Map<String, dynamic> previousFormData;
  const ScreeningFormAngnwadiScreenThree({
    super.key,
    required this.previousFormData,
  });

  @override
  State<ScreeningFormAngnwadiScreenThree> createState() =>
      _ScreeningFormAngnwadiScreenThreeState();
}

class _ScreeningFormAngnwadiScreenThreeState
    extends State<ScreeningFormAngnwadiScreenThree> {
  final _formKey = GlobalKey<FormState>();
  bool hasDeficiency = false;
  Logger _logger = Logger();
  // NEW: Dynamic disease approach
  late List<Disease> diseases = [];
  bool _isLoadingDiseases = false;
  String? _diseaseError;
  String currentDeseaseCategory = '';
  Map<int, bool> selectedDiseases = {};
  Map<int, String> diseaseTreatment = {};
  Map<int, int?> diseaseReferralHospital = {};
  final Map<int, TextEditingController> _diseaseNoteControllers = {};

  // Hospitals
  late List<Hospital> hospitals = [];
  bool _isLoadingHospitals = false;

  @override
  void initState() {
    super.initState();
    print("Anganwadi Form 3 - Category: Deficiencies at Birth (categoryId: 2)");
    fetchDiseaseCategory(); // 2 = DeficiencesAtBirth
    fetchHospitals();
  }

  Future<void> fetchDiseaseCategory() async {
    print('🟢 Starting fetchDiseaseCategory...');
    final url = Uri.parse(
      "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetDiseaseByCategoryId?categoryId=2",
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

  @override
  void dispose() {
    for (var controller in _diseaseNoteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        title: Text("Screening Form"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '3/7',
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
      body: Container(
        color: Colors.grey[50],
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B. Deficiencies at Birth',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('No', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: !hasDeficiency,
                        onChanged: (value) {
                          setState(() {
                            hasDeficiency = !(value ?? false);
                            if (!hasDeficiency) {
                              selectedDiseases.updateAll((key, value) => false);
                              diseaseTreatment.updateAll((key, value) => '');
                              diseaseReferralHospital.updateAll(
                                (key, value) => null,
                              );
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text('Yes', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: hasDeficiency,
                        onChanged: (value) {
                          setState(() {
                            hasDeficiency = value ?? false;
                            if (!hasDeficiency) {
                              selectedDiseases.updateAll((key, value) => false);
                              diseaseTreatment.updateAll((key, value) => '');
                              diseaseReferralHospital.updateAll(
                                (key, value) => null,
                              );
                            }
                          });
                        },
                        activeColor: Colors.blue,
                      ),
                    ),
                  ],
                ),
                if (hasDeficiency) ...[
                  const SizedBox(height: 16),

                  if (_isLoadingDiseases)
                    Center(child: CircularProgressIndicator())
                  else if (_diseaseError != null)
                    Text(_diseaseError!, style: TextStyle(color: Colors.red))
                  else if (diseases.isEmpty)
                    Text('No diseases found for this category')
                  else
                    ...diseases.asMap().entries.map((entry) {
                      int index = entry.key;
                      Disease disease = entry.value;
                      int diseaseId = disease.diseaseId;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${index + 1}. ',
                                style: TextStyle(fontSize: 16),
                              ),
                              Expanded(
                                child: Text(
                                  disease.diseaseName,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: Checkbox(
                                  value: selectedDiseases[diseaseId] ?? false,
                                  onChanged: (value) {
                                    setState(() {
                                      selectedDiseases[diseaseId] =
                                          value ?? false;
                                      if (!selectedDiseases[diseaseId]!) {
                                        diseaseTreatment[diseaseId] = '';
                                        diseaseReferralHospital[diseaseId] =
                                            null;
                                        _diseaseNoteControllers[diseaseId]
                                            ?.clear();
                                      }
                                    });
                                  },
                                  activeColor: Colors.blue,
                                  checkColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (selectedDiseases[diseaseId] == true) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Row(
                                children: [
                                  const Text(
                                    'Treated',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value:
                                          diseaseTreatment[diseaseId] ==
                                          'Treated',
                                      onChanged: (value) {
                                        setState(() {
                                          if (value ?? false) {
                                            diseaseTreatment[diseaseId] =
                                                'Treated';
                                            diseaseReferralHospital[diseaseId] =
                                                null;
                                          } else {
                                            diseaseTreatment[diseaseId] = '';
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  const Text(
                                    'Refer',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: Checkbox(
                                      value:
                                          diseaseTreatment[diseaseId] ==
                                          'Refer',
                                      onChanged: (value) {
                                        setState(() {
                                          if (value ?? false) {
                                            diseaseTreatment[diseaseId] =
                                                'Refer';
                                            _showReferralOptions(diseaseId);
                                          } else {
                                            diseaseTreatment[diseaseId] = '';
                                            diseaseReferralHospital[diseaseId] =
                                                null;
                                          }
                                        });
                                      },
                                      activeColor: Colors.blue,
                                    ),
                                  ),
                                  if (diseaseReferralHospital[diseaseId] !=
                                      null) ...[
                                    const SizedBox(width: 8),
                                    Text(
                                      hospitals
                                          .firstWhere(
                                            (h) =>
                                                h.hospitalId ==
                                                diseaseReferralHospital[diseaseId],
                                          )
                                          .hospitalName,
                                      style: TextStyle(fontSize: 16),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            if (diseaseTreatment[diseaseId] == 'Refer' &&
                                diseaseReferralHospital[diseaseId] != null) ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: TextFormField(
                                  controller:
                                      _diseaseNoteControllers[diseaseId],
                                  decoration: InputDecoration(
                                    labelText: 'Enter Refer Note',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (diseaseTreatment[diseaseId] ==
                                            'Refer' &&
                                        diseaseReferralHospital[diseaseId] !=
                                            null &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter refer note';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                            if (diseaseTreatment[diseaseId] == 'Treated') ...[
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0),
                                child: TextFormField(
                                  controller:
                                      _diseaseNoteControllers[diseaseId],
                                  decoration: InputDecoration(
                                    labelText: 'Enter Treated Note',
                                    border: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.black,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Color(0xFF2196F3),
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (diseaseTreatment[diseaseId] ==
                                            'Treated' &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter treated note';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ],
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                ],
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 25),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A5F7A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Previous',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              final combinedData = _prepareFormData();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ScreeningForAngnwadiClassFormFour(
                                        previousData: combinedData,
                                      ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4A5F7A),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReferralOptions(int diseaseId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Referral Hospital',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                if (_isLoadingHospitals)
                  Center(child: CircularProgressIndicator())
                else if (hospitals.isEmpty)
                  Text('No hospitals available')
                else
                  ...hospitals.asMap().entries.map((entry) {
                    int index = entry.key;
                    Hospital hospital = entry.value;
                    return InkWell(
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
                          vertical: 12,
                          horizontal: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          '${index + 1}. ${hospital.hospitalName}',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    );
                  }),

                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _prepareFormData() {
    Map<String, dynamic> formData = Map.from(widget.previousFormData);

    formData['deficiencesAtBirth'] = hasDeficiency;

    // Collect diseases for this category
    List<Map<String, dynamic>> detectedDiseases = [];

    selectedDiseases.forEach((diseaseId, isSelected) {
      if (isSelected) {
        detectedDiseases.add({
          'diseaseId': diseaseId,
          'diseaseName': diseases
              .firstWhere((d) => d.diseaseId == diseaseId)
              .diseaseName,
          'categoryId': 2, // DeficiencesAtBirth
          'treated': diseaseTreatment[diseaseId] == 'Treated',
          'referred': diseaseTreatment[diseaseId] == 'Refer',
          'hospitalId': diseaseReferralHospital[diseaseId],
          'hospitalName': diseaseReferralHospital[diseaseId] != null
              ? hospitals
                    .firstWhere(
                      (h) => h.hospitalId == diseaseReferralHospital[diseaseId],
                    )
                    .hospitalName
              : null,
          'note': _diseaseNoteControllers[diseaseId]?.text ?? '',
        });
      }
    });

    // Append to existing detected diseases
    if (!formData.containsKey('allDetectedDiseases')) {
      formData['allDetectedDiseases'] = [];
    }
    formData['allDetectedDiseases'].addAll(detectedDiseases);

    print('📋 Form 3 - Detected Diseases: $detectedDiseases');

    return formData;
  }
}

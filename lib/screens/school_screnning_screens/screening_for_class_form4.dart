import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:school_test/models/diseases_model.dart';
import 'package:school_test/models/hospitals_model.dart';
import 'package:school_test/screens/school_screnning_screens/screenign_for_class_form5.dart';
import 'package:http/http.dart' as http;

class ScreeningForClassFormFour extends StatefulWidget {
  final Map<String, dynamic> previousData;

  const ScreeningForClassFormFour({super.key, required this.previousData});

  @override
  State<ScreeningForClassFormFour> createState() =>
      _ScreeningForClassFormFourState();
}

class _ScreeningForClassFormFourState extends State<ScreeningForClassFormFour> {
  final _formKey = GlobalKey<FormState>();
  bool hasCondition = false;
  List<Disease> diseases = [];
  Map<int, bool> selectedDiseases = {};
  Map<int, String> diseaseTreatment = {};
  Map<int, int?> diseaseReferralHospital = {};
  Map<int, TextEditingController> diseaseNoteControllers = {};
  List<Hospital> hospitals = [];
  bool _isLoadingHospitals = false;
  String? _hospitalError;
  final _logger = Logger();

  @override
  void initState() {
    super.initState();
    fetchDiseasesByCategory();
    fetchHospitals();
    _logger.i("Form Data from page 3: ${widget.previousData}");
  }

  Future<void> fetchHospitals() async {
    setState(() => _isLoadingHospitals = true);
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
        }
      }
    } catch (e) {
      setState(() {
        _hospitalError = 'Failed to load hospitals';
        _isLoadingHospitals = false;
      });
      _logger.e('Error fetching hospitals: $e');
    }
  }

  Future<void> fetchDiseasesByCategory() async {
    final url = Uri.parse(
      "https://NewAPIS.rbsknagpur.in/api/Rbsk/GetDiseaseByCategoryId?categoryId=3",
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final categoryResponse = DiseaseCategoryResponse.fromJson(
            data['data'],
          );
          setState(() {
            diseases = categoryResponse.diseases;
            for (var disease in diseases) {
              selectedDiseases[disease.diseaseId] = false;
              diseaseTreatment[disease.diseaseId] = '';
              diseaseReferralHospital[disease.diseaseId] = null;
              diseaseNoteControllers[disease.diseaseId] =
                  TextEditingController();
            }
          });
        }
      }
    } catch (e) {
      _logger.e('Error fetching diseases: $e');
    }
  }

  @override
  void dispose() {
    for (var controller in diseaseNoteControllers.values) {
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
        title: Text("Screening Form "),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                '4/8',
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
                  'C. Diseases',
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
                        value: !hasCondition,
                        onChanged: (value) {
                          setState(() {
                            hasCondition = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text('Yes', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: hasCondition,
                        onChanged: (value) {
                          setState(() {
                            hasCondition = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (hasCondition) ...[
                  const SizedBox(height: 16),
                  ...diseases.asMap().entries.map((entry) {
                    int index = entry.key;
                    Disease disease = entry.value;
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
                                value:
                                    selectedDiseases[disease.diseaseId] ??
                                    false,
                                onChanged: (value) {
                                  setState(() {
                                    selectedDiseases[disease.diseaseId] =
                                        value ?? false;
                                    if (!(selectedDiseases[disease.diseaseId] ??
                                        false)) {
                                      diseaseTreatment[disease.diseaseId] = '';
                                      diseaseReferralHospital[disease
                                              .diseaseId] =
                                          null;
                                      diseaseNoteControllers[disease.diseaseId]
                                          ?.clear();
                                    }
                                  });
                                },
                                activeColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                        if (selectedDiseases[disease.diseaseId] ?? false) ...[
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
                                        diseaseTreatment[disease.diseaseId] ==
                                        'Treated',
                                    onChanged: (value) {
                                      setState(() {
                                        diseaseTreatment[disease.diseaseId] =
                                            (value ?? false) ? 'Treated' : '';
                                        if (value ?? false) {
                                          diseaseReferralHospital[disease
                                                  .diseaseId] =
                                              null;
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
                                        diseaseTreatment[disease.diseaseId] ==
                                        'Refer',
                                    onChanged: (value) {
                                      setState(() {
                                        if (value ?? false) {
                                          diseaseTreatment[disease.diseaseId] =
                                              'Refer';
                                          _showReferralOptions(
                                            disease.diseaseId,
                                          );
                                        } else {
                                          diseaseTreatment[disease.diseaseId] =
                                              '';
                                          diseaseReferralHospital[disease
                                                  .diseaseId] =
                                              null;
                                        }
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                ),
                                if (diseaseReferralHospital[disease
                                        .diseaseId] !=
                                    null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    hospitals
                                        .firstWhere(
                                          (h) =>
                                              h.hospitalId ==
                                              diseaseReferralHospital[disease
                                                  .diseaseId],
                                        )
                                        .hospitalName,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (diseaseTreatment[disease.diseaseId] == 'Refer' &&
                              diseaseReferralHospital[disease.diseaseId] !=
                                  null) ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: TextFormField(
                                controller:
                                    diseaseNoteControllers[disease.diseaseId],
                                decoration: InputDecoration(
                                  labelText: 'Enter Refer Note',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                ),
                                validator: (value) {
                                  if (diseaseTreatment[disease.diseaseId] ==
                                          'Refer' &&
                                      diseaseReferralHospital[disease
                                              .diseaseId] !=
                                          null &&
                                      (value == null || value.isEmpty)) {
                                    return 'Please enter refer note';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                          if (diseaseTreatment[disease.diseaseId] ==
                              'Treated') ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: TextFormField(
                                controller:
                                    diseaseNoteControllers[disease.diseaseId],
                                decoration: InputDecoration(
                                  labelText: 'Enter Treated Note',
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.black),
                                  ),
                                ),
                                validator: (value) {
                                  if (diseaseTreatment[disease.diseaseId] ==
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
                  padding: const EdgeInsets.fromLTRB(8.0, 8, 8, 25),
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
                                      ScreenignForClassFormFive(
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
                else if (_hospitalError != null)
                  Text(_hospitalError!, style: TextStyle(color: Colors.red))
                else if (hospitals.isEmpty)
                  Text('No hospitals available')
                else
                  ...hospitals.asMap().entries.map((entry) {
                    return InkWell(
                      onTap: () {
                        setState(
                          () => diseaseReferralHospital[diseaseId] =
                              entry.value.hospitalId,
                        );
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
                          '${entry.key + 1}. ${entry.value.hospitalName}',
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
    Map<String, dynamic> formData = Map.from(widget.previousData);

    // Safely handle existing detectedDiseases
    List<Map<String, dynamic>> detectedDiseases = [];
    if (formData['detectedDiseases'] != null) {
      if (formData['detectedDiseases'] is List) {
        detectedDiseases = List<Map<String, dynamic>>.from(
          (formData['detectedDiseases'] as List).map(
            (e) => e as Map<String, dynamic>,
          ),
        );
      }
    }

    for (var disease in diseases) {
      if (selectedDiseases[disease.diseaseId] == true) {
        bool isTreated = diseaseTreatment[disease.diseaseId] == 'Treated';
        int? hospitalId = diseaseReferralHospital[disease.diseaseId];
        String notes = diseaseNoteControllers[disease.diseaseId]?.text ?? '';

        Map<String, dynamic> diseaseData = {
          'diseaseId': disease.diseaseId,
          'treatedAtScreening': isTreated,
          'detectionNotes': notes,
          'treatmentNotes': isTreated ? notes : null,
        };

        if (!isTreated && hospitalId != null) {
          diseaseData['referral'] = {
            'hospitalId': hospitalId,
            'referralDate': DateTime.now().toIso8601String(),
            'referralNotes': notes,
            'treatmentDate': null,
            'treatmentNotes': null,
            'referralDiseases': [
              {'diseaseId': disease.diseaseId},
            ],
          };
        } else {
          diseaseData['referral'] = null;
        }

        detectedDiseases.add(diseaseData);
      }
    }

    formData['detectedDiseases'] = detectedDiseases;
    _logger.d("Prepared Form Data: $formData");
    _logger.d("Detected diseases: $detectedDiseases");
    return formData;
  }
}

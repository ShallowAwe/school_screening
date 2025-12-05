import 'package:flutter/material.dart';

/// Model to group all form controllers and state for AddSchoolScreen
class SchoolFormData {
  // Text Controllers
  final schoolNameController = TextEditingController();
  final schoolIdController = TextEditingController();
  final principalNameController = TextEditingController();
  final contactNoController = TextEditingController();
  final addressController = TextEditingController();
  final boysController = TextEditingController();
  final girlsController = TextEditingController();

  // Form State
  DateTime? visitDate;
  String? latitude;
  String? longitude;
  bool? isPrivateSchool;
  List<bool> classSelections = List.filled(12, false);

  // Service Flags
  bool? nationalDeworming = false;
  bool? anemiaMukt = true;
  bool? vitASupplement = false;

  // Image
  String? base64Image;

  // Computed
  int get totalStudents {
    final boys = int.tryParse(boysController.text) ?? 0;
    final girls = int.tryParse(girlsController.text) ?? 0;
    return boys + girls;
  }

  /// Dispose all controllers
  void dispose() {
    schoolNameController.dispose();
    schoolIdController.dispose();
    principalNameController.dispose();
    contactNoController.dispose();
    addressController.dispose();
    boysController.dispose();
    girlsController.dispose();
  }

  /// Validate required fields
  bool validate() {
    return schoolNameController.text.trim().isNotEmpty &&
        schoolIdController.text.trim().isNotEmpty &&
        principalNameController.text.trim().isNotEmpty &&
        contactNoController.text.trim().isNotEmpty &&
        addressController.text.trim().isNotEmpty;
  }

  void reset() {
    schoolNameController.clear();
    schoolIdController.clear();
    principalNameController.clear();
    contactNoController.clear();
    addressController.clear();
    boysController.clear();
    girlsController.clear();
    visitDate = null;
    latitude = null;
    longitude = null;
    isPrivateSchool = null;
    classSelections = List.filled(12, false);
    nationalDeworming = false;
    anemiaMukt = true;
    vitASupplement = false;
    base64Image = null;
  }
}

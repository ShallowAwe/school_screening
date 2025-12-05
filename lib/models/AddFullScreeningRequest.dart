import 'package:school_test/models/DetectedDiseaseRequest.dart';

class AddFullScreeningRequest {
  int studentId;
  int schoolId;
  int teamId;
  int doctorId;

  DateTime screeningDate;

  double? weightKg; // decimal?
  double? heightCm; // decimal?
  double? bmi; // decimal?

  String bloodPressure;
  String visionLeft;
  String visionRight;

  bool requiresReferral;

  double? latitude; // float?
  double? longitude; // float?

  String createdBy;
  String screeningStatus;

  List<DetectedDiseaseRequest> detectedDiseases;

  AddFullScreeningRequest({
    required this.studentId,
    required this.schoolId,
    required this.teamId,
    required this.doctorId,
    required this.screeningDate,
    this.weightKg,
    this.heightCm,
    this.bmi,
    required this.bloodPressure,
    required this.visionLeft,
    required this.visionRight,
    required this.requiresReferral,
    this.latitude,
    this.longitude,
    required this.createdBy,
    required this.screeningStatus,
    required this.detectedDiseases,
  });

  Map<String, dynamic> toJson() => {
    "studentId": studentId,
    "schoolId": schoolId,
    "teamId": teamId,
    "doctorId": doctorId,
    "screeningDate": screeningDate.toIso8601String(),
    "weightKg": weightKg,
    "heightCm": heightCm,
    "bmi": bmi,
    "bloodPressure": bloodPressure,
    "visionLeft": visionLeft,
    "visionRight": visionRight,
    "requiresReferral": requiresReferral,
    "latitude": latitude,
    "longitude": longitude,
    "createdBy": createdBy,
    "screeningStatus": screeningStatus,
    "detectedDiseases": detectedDiseases.map((e) => e.toJson()).toList(),
  };
}

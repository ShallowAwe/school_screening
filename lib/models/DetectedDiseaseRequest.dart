import 'package:school_test/models/ReferralRequest.dart';

class DetectedDiseaseRequest {
  int diseaseId;
  bool treatedAtScreening;
  String detectionNotes;
  String treatmentNotes;
  ReferralRequest? referral; // nullable

  DetectedDiseaseRequest({
    required this.diseaseId,
    required this.treatedAtScreening,
    required this.detectionNotes,
    required this.treatmentNotes,
    this.referral,
  });

  Map<String, dynamic> toJson() => {
    "diseaseId": diseaseId,
    "treatedAtScreening": treatedAtScreening,
    "detectionNotes": detectionNotes,
    "treatmentNotes": treatmentNotes,
    "referral": referral?.toJson(),
  };
}

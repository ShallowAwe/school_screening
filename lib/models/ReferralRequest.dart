import 'package:school_test/models/ReferralDiseaseRequest.dart';

class ReferralRequest {
  int hospitalId;
  DateTime referralDate;

  String? referralNotes;
  DateTime? treatmentDate;
  String? treatmentNotes;

  List<ReferralDiseaseRequest> referralDiseases;

  ReferralRequest({
    required this.hospitalId,
    required this.referralDate,
    this.referralNotes,
    this.treatmentDate,
    this.treatmentNotes,
    required this.referralDiseases,
  });

  Map<String, dynamic> toJson() => {
    "hospitalId": hospitalId,
    "referralDate": referralDate.toIso8601String(),
    "referralNotes": referralNotes,
    "treatmentDate": treatmentDate?.toIso8601String(),
    "treatmentNotes": treatmentNotes,
    "referralDiseases": referralDiseases.map((e) => e.toJson()).toList(),
  };
}

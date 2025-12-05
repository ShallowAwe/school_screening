class ReferralDiseaseRequest {
  int diseaseId;

  ReferralDiseaseRequest({required this.diseaseId});

  Map<String, dynamic> toJson() => {"diseaseId": diseaseId};
}

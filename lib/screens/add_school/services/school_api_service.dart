import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:school_test/config/api_config.dart';
import 'package:school_test/config/endpoints.dart';
import 'package:school_test/models/api_response.dart';
import 'package:school_test/models/district_model.dart';
import 'package:school_test/models/grampanchayat_model.dart';
import 'package:school_test/models/school_model.dart';
import 'package:school_test/models/taluka_model.dart';

/// Service class for all school-related API calls
class SchoolApiService {
  static final String _baseUrl = ApiConfig.baseUrl;

  /// Fetch all districts
  static Future<List<District>> getDistricts() async {
    try {
      final url = Uri.parse("$_baseUrl${Endpoints.getDistrict}");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map<String, dynamic>
            ? decoded['data'] ?? []
            : decoded;

        return data.map((e) => District.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch districts: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching districts: $e');
      return [];
    }
  }

  /// Fetch talukas by district ID
  static Future<List<Taluka>> getTalukas(int districtId) async {
    if (districtId == 0) return [];

    try {
      final url = Uri.parse(
        "$_baseUrl${Endpoints.getTaluka}?districtId=$districtId",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map<String, dynamic>
            ? decoded['data'] ?? []
            : decoded;

        return data.map((e) => Taluka.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch talukas: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching talukas: $e');
      return [];
    }
  }

  /// Fetch grampanchayats by taluka ID
  static Future<List<Grampanchayat>> getGrampanchayats(int talukaId) async {
    if (talukaId == 0) return [];

    try {
      final url = Uri.parse(
        "$_baseUrl${Endpoints.getGrampanchayat}?talukaId=$talukaId",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final List<dynamic> data = decoded is Map<String, dynamic>
            ? decoded['data'] ?? []
            : decoded;

        return data.map((e) => Grampanchayat.fromJson(e)).toList();
      } else {
        throw Exception("Failed to fetch villages: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching villages: $e');
      return [];
    }
  }

  /// Add a new school
  static Future<ApiResponse<dynamic>> addSchool(SchoolDetails school) async {
    final url = Uri.parse("$_baseUrl${Endpoints.addSchool}");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(school.toJson()),
    );

    final data = jsonDecode(response.body);
    print("📡 addSchool API raw response: $data");

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return ApiResponse<dynamic>.fromJson(data, null);
    } else {
      final message = data['responseMessage'] ?? "Failed to add school";
      throw Exception(message);
    }
  }
}

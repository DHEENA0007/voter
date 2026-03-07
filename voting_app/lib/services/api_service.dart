import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// API Service - handles all HTTP communication with Django backend
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;
  String? _role;

  String get baseUrl => AppConstants.baseUrl;

  /// Helper to get full image URL from relative path
  String getImageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '${AppConstants.mediaBaseUrl}$path';
  }

  /// Initialize token from storage
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(AppConstants.tokenKey);
    _role = prefs.getString(AppConstants.roleKey);
  }

  /// Get auth headers
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Token $_token';
    }
    return headers;
  }

  /// Save auth info
  Future<void> saveAuth(String token, String role) async {
    _token = token;
    _role = role;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.roleKey, role);
  }

  /// Clear auth info
  Future<void> clearAuth() async {
    _token = null;
    _role = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.roleKey);
    await prefs.remove(AppConstants.voterIdKey);
    await prefs.remove(AppConstants.userDataKey);
  }

  bool get isLoggedIn => _token != null;
  String? get role => _role;
  String? get token => _token;

  // ============================================================
  // Authentication
  // ============================================================

  Future<Map<String, dynamic>> adminLogin(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/admin/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> voterLogin(String voterId, String passcode) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/voter/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'voter_id': voterId, 'passcode': passcode}),
    );
    return _handleResponse(response);
  }



  Future<Map<String, dynamic>> voterRegister(Map<String, dynamic> data, {File? photo, dynamic photoXFile}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/auth/voter/register/'));
    
    data.forEach((key, value) {
      if (key != 'photo') {
        request.fields[key] = value.toString();
      }
    });

    // Handle photo upload for both web and mobile
    if (photoXFile != null) {
      // Web: use bytes from XFile
      final bytes = await photoXFile.readAsBytes();
      final fileName = photoXFile.name ?? 'photo.jpg';
      request.files.add(http.MultipartFile.fromBytes(
        'photo',
        bytes,
        filename: fileName,
      ));
    } else if (photo != null) {
      // Mobile: use file path
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }



  Future<void> logout() async {
    try {
      await http.post(Uri.parse('$baseUrl/auth/logout/'), headers: _headers);
    } catch (_) {}
    await clearAuth();
  }

  // ============================================================
  // Admin Dashboard
  // ============================================================

  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('$baseUrl/admin/dashboard/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Voter Management
  // ============================================================

  Future<Map<String, dynamic>> getVoters({String? statusFilter, String? search, int page = 1}) async {
    var url = '$baseUrl/voters/?page=$page';
    if (statusFilter != null) url += '&status=$statusFilter';
    if (search != null) url += '&search=$search';
    
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createVoter(Map<String, dynamic> data, {File? photo}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/voters/'));
    request.headers.addAll({'Authorization': 'Token $_token'});
    
    data.forEach((key, value) {
      if (key != 'photo') {
        request.fields[key] = value.toString();
      }
    });

    if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  /// Create voter with photo bytes (for web platform)
  Future<Map<String, dynamic>> createVoterWithBytes(Map<String, dynamic> data, 
      {required List<int> photoBytes, required String photoName}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/voters/'));
    request.headers.addAll({'Authorization': 'Token $_token'});
    
    data.forEach((key, value) {
      if (key != 'photo') {
        request.fields[key] = value.toString();
      }
    });

    request.files.add(http.MultipartFile.fromBytes(
      'photo',
      photoBytes,
      filename: photoName,
    ));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> approveVoter(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voters/$id/approve/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> rejectVoter(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voters/$id/reject/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> blockVoter(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voters/$id/block/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> unblockVoter(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/voters/$id/unblock/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> removeDuplicateVoters() async {
    final response = await http.post(
      Uri.parse('$baseUrl/voters/remove_duplicates/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Election Management
  // ============================================================

  Future<Map<String, dynamic>> getElections({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/elections/?page=$page'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getElection(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/elections/$id/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createElection(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/elections/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateElection(int id, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/elections/$id/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> startElection(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/elections/$id/start/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> stopElection(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/elections/$id/stop/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> extendElection(int id, String endDate) async {
    final response = await http.post(
      Uri.parse('$baseUrl/elections/$id/extend/'),
      headers: _headers,
      body: jsonEncode({'end_date': endDate}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getElectionResults(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/elections/$id/results/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> publishResults(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/elections/$id/publish_results/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getElectionMonitoring(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/elections/$id/monitoring/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Party Management
  // ============================================================

  Future<Map<String, dynamic>> getParties({int page = 1}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/parties/?page=$page'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createParty(String name, String description, 
      {File? symbol, List<int>? symbolBytes, String? symbolName}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/parties/'));
    request.headers.addAll({'Authorization': 'Token $_token'});
    request.fields['name'] = name;
    request.fields['description'] = description;

    if (symbolBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'symbol', symbolBytes, filename: symbolName ?? 'symbol.png',
      ));
    } else if (symbol != null) {
      request.files.add(await http.MultipartFile.fromPath('symbol', symbol.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteParty(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/parties/$id/'),
      headers: _headers,
    );
    if (response.statusCode == 204) return {'message': 'Deleted'};
    return _handleResponse(response);
  }

  // ============================================================
  // Candidate Management
  // ============================================================

  Future<Map<String, dynamic>> getCandidates({int? electionId, int page = 1}) async {
    var url = '$baseUrl/candidates/?page=$page';
    if (electionId != null) url += '&election=$electionId';
    
    final response = await http.get(Uri.parse(url), headers: _headers);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> createCandidate(Map<String, dynamic> data, 
      {File? photo, List<int>? photoBytes, String? photoName}) async {
    var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/candidates/'));
    request.headers.addAll({'Authorization': 'Token $_token'});
    
    data.forEach((key, value) {
      if (key != 'photo') {
        request.fields[key] = value.toString();
      }
    });

    if (photoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'photo', photoBytes, filename: photoName ?? 'photo.jpg',
      ));
    } else if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateCandidate(int id, Map<String, dynamic> data, 
      {File? photo, List<int>? photoBytes, String? photoName}) async {
    var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/candidates/$id/'));
    request.headers.addAll({'Authorization': 'Token $_token'});
    
    data.forEach((key, value) {
      if (key != 'photo') {
        request.fields[key] = value.toString();
      }
    });

    if (photoBytes != null) {
      request.files.add(http.MultipartFile.fromBytes(
        'photo', photoBytes, filename: photoName ?? 'photo.jpg',
      ));
    } else if (photo != null) {
      request.files.add(await http.MultipartFile.fromPath('photo', photo.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> deleteCandidate(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/candidates/$id/'),
      headers: _headers,
    );
    if (response.statusCode == 204) return {'message': 'Deleted'};
    return _handleResponse(response);
  }

  // ============================================================
  // Voting
  // ============================================================

  Future<Map<String, dynamic>> castVote(int electionId, int candidateId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/vote/cast/'),
      headers: _headers,
      body: jsonEncode({
        'election_id': electionId,
        'candidate_id': candidateId,
      }),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> checkVoteStatus(int electionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/vote/status/$electionId/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Voter Portal
  // ============================================================

  Future<Map<String, dynamic>> getVoterProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl/voter/profile/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<List<dynamic>> getVoterElections() async {
    final response = await http.get(
      Uri.parse('$baseUrl/voter/elections/'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as List<dynamic>;
    }
    _handleResponse(response); // will throw ApiException
    return [];
  }

  Future<Map<String, dynamic>> getVoterElectionResults(int electionId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/voter/results/$electionId/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Corrections
  // ============================================================

  Future<Map<String, dynamic>> submitCorrection(Map<String, String> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/corrections/'),
      headers: _headers,
      body: jsonEncode(data),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> getCorrections() async {
    final response = await http.get(
      Uri.parse('$baseUrl/corrections/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> approveCorrection(int id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/corrections/$id/approve/'),
      headers: _headers,
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> rejectCorrection(int id, {String? notes}) async {
    final response = await http.post(
      Uri.parse('$baseUrl/corrections/$id/reject/'),
      headers: _headers,
      body: jsonEncode({'notes': notes}),
    );
    return _handleResponse(response);
  }

  // ============================================================
  // Helper
  // ============================================================

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      throw ApiException(
        statusCode: response.statusCode,
        message: body['error'] ?? body['detail'] ?? 'Something went wrong',
      );
    }
  }
}

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException({required this.statusCode, required this.message});

  @override
  String toString() => message;
}

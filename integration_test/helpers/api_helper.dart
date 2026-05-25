import 'dart:convert';
import 'package:http/http.dart' as http;

/// Base URL of the backend under test.
///
/// The iOS Simulator shares the host machine's network, so the backend is
/// reachable at localhost. Override with the API_BASE_URL environment variable
/// in CI.
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost',
);

/// Minimal HTTP helper that bypasses the Flutter app's DioClient so tests
/// can pre-seed data directly against the backend.
class ApiHelper {
  ApiHelper({required this.deviceId});

  final String deviceId;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'X-Device-Id': deviceId,
      };

  // ─── Trips ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createTrip({
    required String title,
    String? description,
    String? currency,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/trips'),
      headers: _headers,
      body: jsonEncode({
        'title': title,
        if (description != null) 'description': description,
        if (currency != null) 'currency': currency,
      }),
    );
    _assertSuccess(res, 'createTrip');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getTrip(String tripId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId'),
      headers: _headers,
    );
    _assertSuccess(res, 'getTrip');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> getMembers(String tripId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/members'),
      headers: _headers,
    );
    _assertSuccess(res, 'getMembers');
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<void> removeMember(String tripId, String memberId) async {
    final res = await http.delete(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/members/$memberId'),
      headers: _headers,
    );
    _assertSuccess(res, 'removeMember');
  }

  Future<Map<String, dynamic>> getInvitation(String tripId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/invitation'),
      headers: _headers,
    );
    _assertSuccess(res, 'getInvitation');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> joinTrip(String tripId, String token) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/join'),
      headers: _headers,
      body: jsonEncode({'token': token}),
    );
    _assertSuccess(res, 'joinTrip');
  }

  // ─── Polls ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createPoll({
    required String tripId,
    required String title,
    required List<Map<String, String>> slots,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/polls'),
      headers: _headers,
      body: jsonEncode({'title': title, 'slots': slots}),
    );
    _assertSuccess(res, 'createPoll');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Submit or update a vote on a poll slot.
  /// [status] must be one of 'YES', 'MAYBE', 'NO'.
  Future<Map<String, dynamic>> castVote({
    required String pollId,
    required String slotId,
    required String status,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/v1/polls/$pollId/respond'),
      headers: _headers,
      body: jsonEncode({'slotId': slotId, 'status': status}),
    );
    _assertSuccess(res, 'castVote');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> lockPoll({
    required String pollId,
    required String slotId,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/v1/polls/$pollId/lock'),
      headers: _headers,
      body: jsonEncode({'slotId': slotId}),
    );
    _assertSuccess(res, 'lockPoll');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ─── Destinations ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> createDestination({
    required String tripId,
    required String name,
    String? description,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/destinations'),
      headers: _headers,
      body: jsonEncode({
        'name': name,
        if (description != null) 'description': description,
      }),
    );
    _assertSuccess(res, 'createDestination');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Cast a vote on a destination. [rank] is required for ranking mode,
  /// must be null for simple/approval modes.
  Future<Map<String, dynamic>> voteDestination({
    required String destinationId,
    int? rank,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/destinations/$destinationId/vote'),
      headers: _headers,
      body: jsonEncode({if (rank != null) 'rank': rank}),
    );
    _assertSuccess(res, 'voteDestination');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  /// Mark a destination as the selected one for the trip (organizer only).
  Future<Map<String, dynamic>> selectDestination(String destinationId) async {
    final res = await http.patch(
      Uri.parse('$_baseUrl/api/v1/destinations/$destinationId/select'),
      headers: _headers,
    );
    _assertSuccess(res, 'selectDestination');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> addDestinationComment({
    required String destinationId,
    required String content,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/api/v1/destinations/$destinationId/comments'),
      headers: _headers,
      body: jsonEncode({'content': content}),
    );
    _assertSuccess(res, 'addDestinationComment');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listDestinationComments(String destinationId) async {
    final res = await http.get(
      Uri.parse('$_baseUrl/api/v1/destinations/$destinationId/comments'),
      headers: _headers,
    );
    _assertSuccess(res, 'listDestinationComments');
    return jsonDecode(res.body) as List<dynamic>;
  }

  /// Set the trip's destination vote mode.
  /// [mode] must be one of 'SIMPLE', 'APPROVAL', 'RANKING'.
  Future<Map<String, dynamic>> setVoteConfig({
    required String tripId,
    required String mode,
  }) async {
    final res = await http.put(
      Uri.parse('$_baseUrl/api/v1/trips/$tripId/destinations/vote-config'),
      headers: _headers,
      body: jsonEncode({'mode': mode}),
    );
    _assertSuccess(res, 'setVoteConfig');
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  void _assertSuccess(http.Response res, String op) {
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw StateError('[$op] HTTP ${res.statusCode}: ${res.body}');
    }
  }
}

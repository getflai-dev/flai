import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'cmmd_config.dart';

/// Shared base for all CMMD API providers.
///
/// Extracts the common infrastructure (auth headers, CSRF, org scoping,
/// error handling) so each provider only implements its domain logic.
/// Adding a new backend provider? Copy this pattern — swap the base URL
/// and header shape; the provider interfaces stay the same.
mixin CmmdClientBase {
  CmmdConfig get config;
  String Function() get accessTokenProvider;
  String? Function()? get organizationIdProvider;
  Map<String, String> Function()? get csrfHeadersProvider;

  /// Build authenticated headers for a CMMD API request.
  ///
  /// [accept] defaults to `application/json`. Override for SSE
  /// (`text/event-stream`) or binary (`application/octet-stream`).
  Map<String, String> cmmdHeaders({String accept = 'application/json'}) {
    final orgId = organizationIdProvider?.call() ?? config.organizationId;
    return {
      'Content-Type': 'application/json',
      'Accept': accept,
      'User-Agent': 'FlAI/1.0 (cmmd_providers)',
      'Authorization': 'Bearer ${accessTokenProvider()}',
      'X-Auth-Type': 'jwt',
      'X-Organization-ID': ?orgId,
      ...?csrfHeadersProvider?.call(),
    };
  }

  /// Base URL for API requests.
  String get baseUrl => config.baseUrl;

  // ── HTTP helpers ────────────────────────────────────────────────────

  Future<http.Response> cmmdGet(String path) async {
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: cmmdHeaders(),
    );
    checkResponse(response);
    return response;
  }

  Future<http.Response> cmmdPost(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: cmmdHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    checkResponse(response);
    return response;
  }

  Future<http.Response> cmmdPatch(
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl$path'),
      headers: cmmdHeaders(),
      body: body != null ? jsonEncode(body) : null,
    );
    checkResponse(response);
    return response;
  }

  Future<http.Response> cmmdDelete(String path) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: cmmdHeaders(),
    );
    checkResponse(response);
    return response;
  }

  /// Throws [CmmdApiException] for non-2xx responses.
  void checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw CmmdApiException(
      statusCode: response.statusCode,
      message: extractErrorMessage(response.body) ??
          'Request failed (${response.statusCode})',
    );
  }

  // ── Error helpers ──────────────────────────────────────────────────

  /// Extract error message from a JSON response body.
  static String? extractErrorMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['error'] as String? ?? json['message'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// Convert a low-level exception into a user-friendly message.
  static String friendlyError(Object error) {
    if (error is SocketException) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is http.ClientException) {
      return 'Connection error. Please try again.';
    }
    final text = error.toString();
    if (text.contains('SocketException') || text.contains('Connection refused')) {
      return 'Could not connect to server. Check your internet connection.';
    }
    if (!text.contains('Exception') && text.length < 120) {
      return text;
    }
    return 'Something went wrong. Please try again.';
  }

  /// Parse a CMMD API datetime (ISO string or epoch millis).
  static DateTime parseDateTime(dynamic value) {
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    return DateTime.now();
  }
}

/// Exception thrown by CMMD API providers.
///
/// Shared across all providers so consumers can catch a single type.
class CmmdApiException implements Exception {
  final int? statusCode;
  final String message;

  const CmmdApiException({this.statusCode, required this.message});

  @override
  String toString() => 'CmmdApiException($statusCode): $message';
}

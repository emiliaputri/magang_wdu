import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../constants/endpoints.dart';
import '../utils/storage.dart';
import '../utils/logger.dart';

// ── RESPONSE WRAPPER ──────────────────────────────────────────
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });
}

// ── CUSTOM EXCEPTIONS ─────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  UnauthorizedException()
    : super('Sesi habis, silakan login kembali', statusCode: 401);
}

class NetworkException extends ApiException {
  NetworkException() : super('Tidak ada koneksi internet');
}

class ServerException extends ApiException {
  ServerException(String message) : super(message, statusCode: 500);
}

// ── API CLIENT ────────────────────────────────────────────────
class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  final http.Client _client = http.Client();

  // ── TIMEOUT DURATION ──
  static const Duration _timeout = Duration(seconds: 30);

  // ── BUILD HEADERS ──────────────────────────────────────────
  Future<Map<String, String>> _buildHeaders({bool requireAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requireAuth) {
      final token = await StorageHelper.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  // ── LOG REQUEST (hanya di debug mode) ──────────────────────
  void _logRequest(
    String method,
    String url, {
    dynamic body,
    Map<String, String>? headers,
  }) {
    assert(() {
      print('── API REQUEST ──────────────────────');
      print('$method $url');
      if (headers != null) {
        final auth = headers['Authorization'];
        if (auth != null) {
          final prefix = auth.length > 15 ? auth.substring(0, 15) : auth;
          print('Auth: $prefix...');
        } else {
          print('Auth: MISSING');
        }
      }
      if (body != null) print('Body: $body');
      print('─────────────────────────────────────');
      return true;
    }());
  }

  void _logResponse(http.Response response) {
    assert(() {
      print('── API RESPONSE ─────────────────────');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');
      print('─────────────────────────────────────');
      return true;
    }());
  }

  // ── HANDLE RESPONSE ────────────────────────────────────────
  ApiResponse<Map<String, dynamic>> _handleResponse(http.Response response) {
    _logResponse(response);

    Map<String, dynamic> body = {};
    try {
      final String trimmedBody = response.body.trim();
      if (trimmedBody.isNotEmpty) {
        final decoded = jsonDecode(trimmedBody);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else {
          body = {'data': decoded};
        }
      }
    } catch (e, st) {
      AppLogger.error(
        'API DECODE ERROR - Status: ${response.statusCode}, URL: ${response.request?.url}',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      AppLogger.warning(
        'Response Body Snippet: ${response.body.length > 500 ? response.body.substring(0, 500) + "..." : response.body}',
        category: 'API',
      );
      throw ServerException(
        'Gagal memproses data server (Error ${response.statusCode}). Pastikan endpoint API sudah benar.',
      );
    }

    switch (response.statusCode) {
      case 200:
      case 201:
        return ApiResponse(
          success: true,
          statusCode: response.statusCode,
          data: body,
          message: body['message'] as String?,
        );

      case 401:
        throw UnauthorizedException();

      case 422:
        // Validation error dari Laravel
        final errors = body['errors'];
        final msg = errors != null
            ? (errors as Map).values.first[0].toString()
            : body['message'] ?? 'Validasi gagal';
        throw ApiException(msg, statusCode: 422);

      case 404:
        throw ApiException(
          'Data atau Endpoint tidak ditemukan (404)',
          statusCode: 404,
        );

      case 500:
        throw ServerException(
          body['message'] ?? 'Terjadi kesalahan internal server (500)',
        );

      default:
        throw ApiException(
          body['message'] ?? 'Terjadi kesalahan sistem',
          statusCode: response.statusCode,
        );
    }
  }

  // ── GET ────────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    bool requireAuth = true,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('${Endpoints.baseUrl}$endpoint');
      if (queryParams != null) {
        uri = uri.replace(queryParameters: queryParams);
      }

      final headers = await _buildHeaders(requireAuth: requireAuth);
      _logRequest('GET', uri.toString(), headers: headers);
      final response = await _client
          .get(uri, headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException catch (e, st) {
      AppLogger.error(
        'SocketException pada GET $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend menyala dan IP/Firewall benar.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'TimeoutException pada GET $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Koneksi ke server timeout (30s). Periksa koneksi internet atau Firewall Anda.',
        statusCode: 408,
      );
    } on HttpException catch (e, st) {
      AppLogger.error(
        'HttpException pada GET $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw NetworkException();
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error pada GET $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      rethrow;
    }
  }

  // ── POST ───────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$endpoint');
      final encodedBody = jsonEncode(body);

      final headers = await _buildHeaders(requireAuth: requireAuth);
      _logRequest('POST', uri.toString(), body: encodedBody, headers: headers);
      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException catch (e, st) {
      AppLogger.error(
        'SocketException pada POST $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend menyala dan IP/Firewall benar.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'TimeoutException pada POST $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Koneksi ke server timeout (30s). Periksa koneksi internet atau Firewall Anda.',
        statusCode: 408,
      );
    } on HttpException catch (e, st) {
      AppLogger.error(
        'HttpException pada POST $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw NetworkException();
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error pada POST $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      rethrow;
    }
  }

  // ── PUT ────────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$endpoint');
      final encodedBody = jsonEncode(body);

      final headers = await _buildHeaders(requireAuth: requireAuth);
      _logRequest('PUT', uri.toString(), body: encodedBody, headers: headers);
      final response = await _client
          .put(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException catch (e, st) {
      AppLogger.error(
        'SocketException pada PUT $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend menyala dan IP/Firewall benar.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'TimeoutException pada PUT $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Koneksi ke server timeout (30s). Periksa koneksi internet atau Firewall Anda.',
        statusCode: 408,
      );
    } on HttpException catch (e, st) {
      AppLogger.error(
        'HttpException pada PUT $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw NetworkException();
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error pada PUT $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      rethrow;
    }
  }

  // ── PATCH ──────────────────────────────────────────────────
  Future<ApiResponse<Map<String, dynamic>>> patch(
    String endpoint, {
    required Map<String, dynamic> body,
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$endpoint');
      final encodedBody = jsonEncode(body);

      final headers = await _buildHeaders(requireAuth: requireAuth);
      _logRequest('PATCH', uri.toString(), body: encodedBody, headers: headers);
      final response = await _client
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException catch (e, st) {
      AppLogger.error(
        'SocketException pada PATCH $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend menyala dan IP/Firewall benar.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'TimeoutException pada PATCH $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Koneksi ke server timeout (30s). Periksa koneksi internet atau Firewall Anda.',
        statusCode: 408,
      );
    } on HttpException catch (e, st) {
      AppLogger.error(
        'HttpException pada PATCH $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw NetworkException();
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error pada PATCH $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      rethrow;
    }
  }

  // ── DELETE ─────────────────────────────────────────────────

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    bool requireAuth = true,
  }) async {
    try {
      final uri = Uri.parse('${Endpoints.baseUrl}$endpoint');

      final headers = await _buildHeaders(requireAuth: requireAuth);
      _logRequest('DELETE', uri.toString(), headers: headers);
      final response = await _client
          .delete(uri, headers: headers)
          .timeout(_timeout);

      return _handleResponse(response);
    } on SocketException catch (e, st) {
      AppLogger.error(
        'SocketException pada DELETE $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Tidak dapat terhubung ke server. Pastikan backend menyala dan IP/Firewall benar.',
        statusCode: 0,
      );
    } on TimeoutException catch (e, st) {
      AppLogger.error(
        'TimeoutException pada DELETE $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw ApiException(
        'Koneksi ke server timeout (30s). Periksa koneksi internet atau Firewall Anda.',
        statusCode: 408,
      );
    } on HttpException catch (e, st) {
      AppLogger.error(
        'HttpException pada DELETE $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      throw NetworkException();
    } catch (e, st) {
      AppLogger.error(
        'Unexpected error pada DELETE $endpoint',
        error: e,
        stackTrace: st,
        category: 'API',
      );
      rethrow;
    }
  }

  // ── DISPOSE ────────────────────────────────────────────────
  void dispose() => _client.close();
}

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../domain/entities/file_type.dart';
import '../services/directory_parser_service.dart';

/// Data source for fetching files from a remote HTTP/HTTPS server.
///
/// Handles HTTP requests with Basic Authentication and parses
/// HTML directory listings or JSON API responses.
class FileRemoteDataSource {
  final DirectoryParserService _parserService = DirectoryParserService();
  final http.Client _httpClient;

  FileRemoteDataSource({http.Client? httpClient})
      : _httpClient = httpClient ?? _createHttpClient();

  /// Creates an HTTP client that accepts self-signed certificates for local servers.
  ///
  /// This is useful for connecting to local HTTPS servers (e.g., on Android phone)
  /// that use self-signed certificates.
  static http.Client _createHttpClient() {
    final httpClient = HttpClient();
    // Allow self-signed certificates (for local development/servers)
    httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
      // Allow certificates for local/private IP addresses
      return _isLocalOrPrivateIP(host);
    };
    return IOClient(httpClient);
  }

  /// Checks if the host is a local or private IP address.
  static bool _isLocalOrPrivateIP(String host) {
    // Localhost
    if (host == 'localhost' || host == '127.0.0.1' || host == '::1') {
      return true;
    }
    
    // Private IP ranges (10.x.x.x, 192.168.x.x, 172.16-31.x.x)
    final privateIPPattern = RegExp(
      r'^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[0-1])\.)',
    );
    if (privateIPPattern.hasMatch(host)) {
      return true;
    }
    
    return false;
  }

  /// Fetches all files from the server.
  ///
  /// Uses the provided [config] to authenticate and fetch the directory listing.
  /// Returns a list of [CloudFile] entities.
  ///
  /// Throws an exception if the server cannot be accessed or the response cannot be parsed.
  Future<List<CloudFile>> getFiles(FileServerConfig config) async {
    if (!config.isValid) {
      throw Exception('Invalid server configuration: baseUrl is required');
    }

    try {
      // Normalize and validate URL
      String normalizedUrl = config.baseUrl.trim();
      if (!normalizedUrl.startsWith('http://') && !normalizedUrl.startsWith('https://')) {
        throw Exception('URL must start with http:// or https://');
      }
      
      // Fix common URL format issues (e.g., https:/192.168.0.10 -> https://192.168.0.10)
      // Fix single slash after protocol
      if (normalizedUrl.contains(RegExp(r'https?:/[^/]'))) {
        final protocol = normalizedUrl.startsWith('https') ? 'https://' : 'http://';
        final afterProtocol = normalizedUrl.substring(protocol.length - 1);
        normalizedUrl = protocol + afterProtocol;
      }
      
      final uri = Uri.parse(normalizedUrl);
      
      if (uri.host.isEmpty) {
        throw Exception('Invalid URL: host is required. Make sure the URL includes the protocol (http:// or https://)');
      }
      final request = http.Request('GET', uri);

      // Add Basic Auth if credentials are provided
      if (config.requiresAuth) {
        final credentials = base64Encode(
          utf8.encode('${config.username}:${config.password}'),
        );
        request.headers['Authorization'] = 'Basic $credentials';
      }

      // Set headers for directory listing
      request.headers['Accept'] = 'text/html,application/json';

      final response = await _httpClient.send(request);
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('Authentication required (${response.statusCode}):\n'
            'The server requires username and password.\n'
            'Please configure credentials in the server settings.\n'
            'Server response: ${responseBody.isNotEmpty ? responseBody : "Unauthorized"}');
      }

      if (response.statusCode != 200) {
        throw Exception(
          'Failed to fetch files: Server returned status ${response.statusCode}. '
          'Response: ${responseBody.length > 200 ? responseBody.substring(0, 200) : responseBody}',
        );
      }

      // Check content type to determine parsing strategy
      final contentType = response.headers['content-type'] ?? '';
      
      if (contentType.contains('application/json')) {
        // Parse JSON response
        return _parseJsonResponse(responseBody, normalizedUrl);
      } else {
        // Parse HTML directory listing
        return _parserService.parseHtmlDirectory(responseBody, normalizedUrl);
      }
    } on http.ClientException catch (e) {
      // Provide more detailed error information
      String errorMessage = 'Network error: ${e.message}';
      if (e.message.contains('connection refused')) {
        errorMessage = 'Connection refused. Troubleshooting steps:\n'
            '1. Check server URL format: https://192.168.0.10/files (or http://)\n'
            '2. Verify both devices (iPhone & Android) are on the SAME WiFi network\n'
            '3. Make sure the file server app on Android is running\n'
            '4. Get the correct IP address from Android server app\n'
            '5. For local servers, try HTTP instead: http://192.168.0.10/files\n'
            '6. Check firewall settings on both devices';
      } else if (e.message.contains('handshake') || 
                 e.message.contains('certificate') ||
                 e.message.contains('SSL')) {
        errorMessage = 'SSL/TLS handshake failed. Solutions:\n'
            '1. For local servers (Android phone), try using HTTP instead:\n'
            '   Change https:// to http://\n'
            '   Example: http://192.168.0.10/files\n'
            '2. Make sure both devices are on the same WiFi network\n'
            '3. Check that the server is running and accessible';
      } else if (e.message.contains('Failed host lookup')) {
        errorMessage = 'Host not found. Please check:\n'
            '1. The server IP address is correct\n'
            '2. Your device can reach the server (try pinging it)';
      }
      throw Exception(errorMessage);
    } on FormatException catch (e) {
      throw Exception('Invalid URL format: ${e.message}\n'
          'Make sure the URL includes the protocol (http:// or https://)');
    } catch (e) {
      // For other exceptions, include the original message
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Unexpected error: $e');
    }
  }

  /// Parses a JSON response containing file information.
  ///
  /// Expected JSON format:
  /// ```json
  /// {
  ///   "files": [
  ///     {
  ///       "name": "photo.jpg",
  ///       "url": "https://example.com/photos/photo.jpg",
  ///       "size": 1024000,
  ///       "modified": "2024-01-15T10:30:00Z",
  ///       "type": "image/jpeg"
  ///     }
  ///   ]
  /// }
  /// ```
  List<CloudFile> _parseJsonResponse(String jsonBody, String baseUrl) {
    try {
      final json = jsonDecode(jsonBody) as Map<String, dynamic>;
      final files = <CloudFile>[];

      // Handle different JSON structures
      dynamic filesList;
      if (json.containsKey('files')) {
        filesList = json['files'];
      } else if (json.containsKey('items')) {
        filesList = json['items'];
      } else if (json is List) {
        filesList = json;
      } else {
        return files;
      }

      if (filesList is List) {
        for (final item in filesList) {
          if (item is Map<String, dynamic>) {
            final name = item['name'] as String? ?? '';
            if (name.isEmpty) continue;

            final url = item['url'] as String? ??
                item['href'] as String? ??
                '$baseUrl/$name';
            final size = item['size'] as int?;
            final modifiedStr = item['modified'] as String? ??
                item['modifiedDate'] as String? ??
                item['date'] as String?;
            final mimeType = item['type'] as String? ?? item['mimeType'] as String?;
            final folder = item['folder'] as String? ??
                item['path'] as String? ??
                '';

            DateTime? modifiedDate;
            if (modifiedStr != null) {
              try {
                modifiedDate = DateTime.parse(modifiedStr);
              } catch (e) {
                // Ignore parse errors
              }
            }

            // Determine file type from extension
            final fileType = FileTypeHelper.fromExtension(name);

            files.add(CloudFile(
              url: url,
              name: name,
              type: fileType,
              size: size,
              modifiedDate: modifiedDate,
              folder: folder,
              mimeType: mimeType,
            ));
          }
        }
      }

      return files;
    } catch (e) {
      throw Exception('Failed to parse JSON response: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}


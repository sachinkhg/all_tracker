import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../domain/entities/book_search_result.dart';

/// Data source for Google Books API operations.
///
/// Provides methods to search for books using the Google Books API.
/// API key is optional but recommended for higher quotas.
class GoogleBooksDataSource {
  static const String _baseUrl = 'https://www.googleapis.com/books/v1';
  static const Duration _timeout = Duration(seconds: 10);
  
  /// Optional API key for higher quota limits.
  /// If not provided, the API will work but with lower rate limits.
  final String? apiKey;
  
  GoogleBooksDataSource({this.apiKey});

  /// Searches for books by title.
  ///
  /// Returns a list of [BookSearchResult] objects matching the search query.
  /// Returns an empty list if no results are found or if an error occurs.
  Future<List<BookSearchResult>> searchBooks(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final encodedQuery = Uri.encodeComponent(query.trim());
      var urlString = '$_baseUrl/volumes?q=intitle:$encodedQuery&maxResults=10';
      
      // Add API key if provided
      if (apiKey != null && apiKey!.isNotEmpty) {
        urlString += '&key=$apiKey';
      }
      
      final url = Uri.parse(urlString);
      final response = await http.get(url).timeout(_timeout);

      if (response.statusCode != 200) {
        print('[GoogleBooksDataSource] API returned status ${response.statusCode}');
        return [];
      }

      final jsonData = json.decode(response.body) as Map<String, dynamic>;
      final items = jsonData['items'] as List<dynamic>?;

      if (items == null || items.isEmpty) {
        return [];
      }

      return items
          .map((item) {
            final volumeInfo = (item as Map<String, dynamic>)['volumeInfo'] as Map<String, dynamic>?;
            if (volumeInfo == null) return null;
            return _parseVolumeInfo(volumeInfo);
          })
          .where((result) => result != null)
          .cast<BookSearchResult>()
          .toList();
    } catch (e) {
      print('[GoogleBooksDataSource] Error searching books: $e');
      return [];
    }
  }

  /// Parses volumeInfo from Google Books API response.
  BookSearchResult? _parseVolumeInfo(Map<String, dynamic> volumeInfo) {
    try {
      // Extract title
      final title = volumeInfo['title'] as String?;
      if (title == null || title.isEmpty) {
        return null;
      }

      // Extract authors
      final authorNames = volumeInfo['authors'] as List<dynamic>?;
      final authors = authorNames
              ?.map((name) => name.toString())
              .where((name) => name.isNotEmpty)
              .toList() ??
          [];

      // Extract page count
      int? pageCount;
      final pageCountValue = volumeInfo['pageCount'] as num?;
      if (pageCountValue != null && pageCountValue > 0) {
        pageCount = pageCountValue.toInt();
      }

      // Extract publication date
      // Google Books API provides publishedDate which can be:
      // - Full date: "2020-01-15"
      // - Year and month: "2020-01"
      // - Just year: "2020"
      DateTime? datePublished;
      final publishedDateStr = volumeInfo['publishedDate'] as String?;
      if (publishedDateStr != null && publishedDateStr.isNotEmpty) {
        try {
          // Only parse if it's a full date (contains dashes and has more than 4 chars)
          if (publishedDateStr.length > 4 && publishedDateStr.contains('-')) {
            // Try parsing as ISO date (YYYY-MM-DD or YYYY-MM)
            final parts = publishedDateStr.split('-');
            if (parts.length >= 2) {
              final year = int.parse(parts[0]);
              final month = parts.length >= 2 ? int.parse(parts[1]) : 1;
              final day = parts.length >= 3 ? int.parse(parts[2]) : 1;
              datePublished = DateTime(year, month, day);
            }
          }
          // If it's just a year (4 digits), leave datePublished as null
          // to avoid creating misleading "Jan 1" dates
        } catch (e) {
          // If parsing fails, leave as null
        }
      }

      // Extract ISBN (from industryIdentifiers array)
      String? isbn;
      final identifiers = volumeInfo['industryIdentifiers'] as List<dynamic>?;
      if (identifiers != null) {
        for (final identifier in identifiers) {
          final idMap = identifier as Map<String, dynamic>;
          final type = idMap['type'] as String?;
          if (type == 'ISBN_13' || type == 'ISBN_10') {
            isbn = idMap['identifier'] as String?;
            if (isbn != null && isbn.isNotEmpty) {
              break; // Prefer ISBN_13, but use first available
            }
          }
        }
      }

      // Extract cover URL (optional)
      String? coverUrl;
      final imageLinks = volumeInfo['imageLinks'] as Map<String, dynamic>?;
      if (imageLinks != null) {
        // Try medium, then small, then thumbnail
        coverUrl = imageLinks['medium'] as String? ??
            imageLinks['small'] as String? ??
            imageLinks['thumbnail'] as String?;
      }

      return BookSearchResult(
        title: title,
        authors: authors,
        pageCount: pageCount,
        datePublished: datePublished,
        isbn: isbn,
        coverUrl: coverUrl,
      );
    } catch (e) {
      print('[GoogleBooksDataSource] Error parsing volume info: $e');
      return null;
    }
  }
}


import 'package:html/parser.dart' as html_parser;
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_type.dart';

/// Service for parsing HTML directory listings from web servers.
///
/// Supports common Apache and Nginx directory listing formats.
class DirectoryParserService {
  /// Parses an HTML directory listing and extracts file information.
  ///
  /// [html] - The HTML content of the directory listing page.
  /// [baseUrl] - The base URL to construct full file URLs.
  ///
  /// Returns a list of [CloudFile] entities found in the directory.
  List<CloudFile> parseHtmlDirectory(String html, String baseUrl) {
    final document = html_parser.parse(html);
    final files = <CloudFile>[];

    // Ensure baseUrl doesn't end with a slash
    final cleanBaseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;

    // Strategy 0: Look for embedded JSON data in script tags
    // Some file servers embed file lists as JSON in script tags
    final scripts = document.querySelectorAll('script');
    for (final script in scripts) {
      final scriptContent = script.text;
      if (scriptContent.isEmpty) continue;
      
      // Look for JSON-like structures (file arrays, etc.)
      try {
        // Try to find JSON data structures
        final jsonMatch = RegExp(r'\[.*?\{.*?"(?:name|path|url|file)".*?\}.*?\]', 
            dotAll: true, caseSensitive: false).firstMatch(scriptContent);
        if (jsonMatch != null) {
          // Could parse this if it contains file data
        }
      } catch (e) {
        // Ignore parsing errors
      }
    }

    // Strategy 1: Look for image and video tags directly (but filter UI assets)
    // Note: Most file servers don't use img tags for file listings, but we'll check anyway
    // However, we'll skip this strategy entirely for now as img tags are usually UI elements
    // final images = document.querySelectorAll('img[src]');
    // for (final img in images) {
    //   final src = img.attributes['src'];
    //   if (src != null && src.isNotEmpty) {
    //     final file = _createCloudFileFromSrc(src, cleanBaseUrl, baseUrl);
    //     if (file != null && (file.type.isImage || file.type.isVideo)) {
    //       files.add(file);
    //     }
    //   }
    // }

    // Strategy 2: Skip video tags too - they're usually UI elements in file browsers
    // We'll focus on actual file links instead
    
    // Strategy 2.5: Look for file links in common data attributes or custom attributes
    // Some modern file browsers use data-file, data-href, or similar attributes
    final fileLinks = document.querySelectorAll('[data-file], [data-href], [data-url]');
    for (final link in fileLinks) {
      final filePath = link.attributes['data-file'] ?? 
                       link.attributes['data-href'] ?? 
                       link.attributes['data-url'];
      if (filePath != null && filePath.isNotEmpty) {
        final lowerPath = filePath.toLowerCase();
        // Skip UI assets
        if (!lowerPath.contains('/data/') && 
            !lowerPath.contains('/static/') && 
            !lowerPath.contains('/assets/')) {
          final fileType = FileTypeHelper.fromExtension(filePath);
          if (fileType.isImage || fileType.isVideo) {
            String fileUrl;
            if (filePath.startsWith('http://') || filePath.startsWith('https://')) {
              fileUrl = filePath;
            } else if (filePath.startsWith('/')) {
              fileUrl = '$cleanBaseUrl$filePath';
            } else {
              fileUrl = '$cleanBaseUrl/$filePath';
            }
            files.add(CloudFile(
              url: fileUrl,
              name: filePath.split('/').last,
              type: fileType,
              folder: _extractFolder(filePath, baseUrl),
            ));
          }
        }
      }
    }

    // Strategy 3: Look for links (common in directory listings)
    final links = document.querySelectorAll('a[href]');
    
    for (final link in links) {
      final href = link.attributes['href'];
      if (href == null || href.isEmpty) continue;

      // Skip parent directory links
      if (href == '../' || href == '..') continue;

      // Skip current directory links
      if (href == './' || href == '.') continue;

      // Skip navigation/internal links
      if (href.startsWith('#') || href.startsWith('javascript:')) continue;

      // Skip UI assets (common web app asset paths) - be very aggressive
      final lowerHref = href.toLowerCase();
      
      // Filter out common UI asset patterns
      if (lowerHref.contains('/data/') || 
          lowerHref.contains('/static/') || 
          lowerHref.contains('/assets/') ||
          lowerHref.contains('/css/') ||
          lowerHref.contains('/js/') ||
          lowerHref.contains('/images/ui/') ||
          lowerHref.contains('/icons/') ||
          lowerHref.contains('favicon') ||
          lowerHref.contains('logo') ||
          lowerHref.contains('upload-fab') ||
          lowerHref.contains('folder.png') ||
          lowerHref.contains('document.png') ||
          lowerHref.contains('folder') && lowerHref.endsWith('.png') ||
          lowerHref.contains('document') && lowerHref.endsWith('.png') ||
          lowerHref == 'data' ||
          lowerHref.startsWith('data/')) {
        continue;
      }
      
      // Check if it's a directory (ends with /)
      // We'll include folders in the results
      final isDirectory = href.endsWith('/');
      
      if (isDirectory) {
        // Extract folder name (last segment only for display)
        String folderName = href;
        if (folderName.endsWith('/')) {
          folderName = folderName.substring(0, folderName.length - 1);
        }
        
        // Extract just the last segment for the folder name
        if (folderName.contains('/')) {
          final segments = folderName.split('/').where((s) => s.isNotEmpty && s != '.' && s != '..').toList();
          if (segments.isEmpty) continue;
          folderName = segments.last;
        }
        
        // Skip parent directory, current directory, and empty names
        if (folderName == '..' || folderName == '.' || folderName.isEmpty) {
          continue;
        }
        
        // Construct full URL properly
        String folderUrl;
        if (href.startsWith('http://') || href.startsWith('https://')) {
          // Already a full URL
          folderUrl = href;
        } else if (href.startsWith('/')) {
          // Absolute path from root - combine with cleanBaseUrl's scheme/host
          try {
            final baseUri = Uri.parse(cleanBaseUrl);
            folderUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}$href';
          } catch (e) {
            folderUrl = '$cleanBaseUrl$href';
          }
        } else {
          // Relative path - resolve it relative to current baseUrl
          // For a relative path like "folder/", it should be a direct child
          // Simple case: just append to baseUrl
          final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
          folderUrl = '$normalizedBase$href';
          
          // Clean up any './' in the URL
          folderUrl = folderUrl.replaceAll('/./', '/');
        }
        
        // Validate: The folder URL should be a child of the base URL
        // If the resolved URL doesn't start with the base URL (after normalization), skip it
        // This prevents showing parent directories or invalid paths
        final normalizedBaseUrl = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
        if (!folderUrl.startsWith(normalizedBaseUrl)) {
          continue;
        }
        
        // Additional check: Skip folders whose names match segments in the current path
        // This filters out breadcrumb navigation links that appear as folders
        try {
          final baseUri = Uri.parse(baseUrl);
          final currentPathSegments = baseUri.path.split('/').where((s) => s.isNotEmpty).toList();
          final decodedFolderName = Uri.decodeComponent(folderName);
          
          // If the folder name matches any segment in the current path, it's likely a breadcrumb
          if (currentPathSegments.any((segment) {
            try {
              return Uri.decodeComponent(segment) == decodedFolderName || segment == folderName;
            } catch (e) {
              return segment == folderName || segment == decodedFolderName;
            }
          })) {
            continue;
          }
        } catch (e) {
          // Continue if path parsing fails
        }
        
        // Decode URL-encoded folder names (e.g., Google%20Photos -> Google Photos)
        try {
          folderName = Uri.decodeComponent(folderName);
        } catch (e) {
          // Keep original if decoding fails
        }
        
        // Create a CloudFile representing a folder (using FileType.other for folders)
        files.add(CloudFile(
          url: folderUrl,
          name: '$folderName/',
          type: FileType.other,
          folder: _extractFolder(folderUrl, baseUrl),
        ));
        continue;
      }

      // Extract filename from href
      // Handle query parameters like ?img=filename.jpg
      String filename = '';
      String hrefToProcess = href;
      
      // Check if there's an img parameter in query string
      if (hrefToProcess.contains('?img=')) {
        final parts = hrefToProcess.split('?img=');
        if (parts.length > 1) {
          // Extract filename from query parameter
          filename = parts[1].split('&').first.split('#').first;
          // Also construct the actual image URL from the path and img parameter
          hrefToProcess = parts[0]; // This will be used to construct the URL
        }
      }
      
      // If no img parameter, extract from path
      if (filename.isEmpty) {
        // Handle relative paths like "./image.jpg" or "../folder/image.jpg"
        // Clean up relative path indicators
        if (hrefToProcess.startsWith('./')) {
          hrefToProcess = hrefToProcess.substring(2);
        }
        
        filename = hrefToProcess;
        if (filename.contains('/')) {
          filename = filename.split('/').last;
        }
        if (filename.contains('?')) {
          filename = filename.split('?').first;
        }
        // Remove URL fragments
        if (filename.contains('#')) {
          filename = filename.split('#').first;
        }
      }

      // Skip if empty filename
      if (filename.isEmpty) {
        continue;
      }

      // Additional check: if the filename matches common UI icon names, skip it
      final lowerFilename = filename.toLowerCase();
      if (lowerFilename == 'folder.png' || 
          lowerFilename == 'document.png' ||
          lowerFilename == 'file.png' ||
          lowerFilename.startsWith('icon-') ||
          lowerFilename.contains('fab') ||
          lowerFilename.contains('upload')) {
        continue;
      }

      // Determine file type
      final fileType = FileTypeHelper.fromExtension(filename);

      // Only include images and videos (folders are handled above)
      if (!fileType.isImage && !fileType.isVideo) continue;

      // Construct full URL properly
      String fileUrl;
      
      // If href contains ?img= parameter, construct URL differently
      if (href.contains('?img=')) {
        // For gallery links like /gallery/DCIM/Restored?img=filename.jpg
        // The actual image file is at /files/DCIM/Restored/filename.jpg
        try {
          final baseUri = Uri.parse(baseUrl);
          // Get the path without the /files prefix if it exists
          String imagePath = baseUri.path;
          if (!imagePath.endsWith('/')) {
            imagePath = '$imagePath/';
          }
          // Add the filename
          imagePath = '$imagePath$filename';
          // Construct full URL
          fileUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}$imagePath';
        } catch (e) {
          // Fallback: try to construct from cleanBaseUrl
          final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
          fileUrl = '$normalizedBase$filename';
        }
      } else if (href.startsWith('http://') || href.startsWith('https://')) {
        // Already a full URL
        fileUrl = href;
      } else if (href.startsWith('/')) {
        // Absolute path from root
        try {
          final baseUri = Uri.parse(cleanBaseUrl);
          fileUrl = '${baseUri.scheme}://${baseUri.host}${baseUri.hasPort ? ':${baseUri.port}' : ''}$href';
        } catch (e) {
          fileUrl = '$cleanBaseUrl$href';
        }
      } else {
        // Relative path - resolve relative to current directory
        // Handle paths starting with './'
        String processedHref = href;
        if (processedHref.startsWith('./')) {
          processedHref = processedHref.substring(2);
        }
        
        final normalizedBase = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
        fileUrl = '$normalizedBase$processedHref';
        
        // Clean up any './' or '//' in the URL
        fileUrl = fileUrl.replaceAll('/./', '/').replaceAll('//', '/');
        
        // Fix protocol double slashes (http:// -> http://)
        if (fileUrl.startsWith('http:/') && !fileUrl.startsWith('http://')) {
          fileUrl = fileUrl.replaceFirst('http:/', 'http://');
        }
        if (fileUrl.startsWith('https:/') && !fileUrl.startsWith('https://')) {
          fileUrl = fileUrl.replaceFirst('https:/', 'https://');
        }
      }

      // Try to extract size and date from the table row or parent elements
      int? size;
      DateTime? modifiedDate;

      // Look for parent table row (common in Apache listings)
      final parentRow = link.parent?.parent;
      if (parentRow != null && parentRow.localName == 'tr') {
        final cells = parentRow.querySelectorAll('td');
        if (cells.length >= 3) {
          // Usually: name, last modified, size
          try {
            // Try to parse size (last cell)
            final sizeText = cells.last.text.trim();
            size = _parseSize(sizeText);

            // Try to parse date (second to last cell or similar)
            if (cells.length >= 2) {
              final dateText = cells[cells.length - 2].text.trim();
              modifiedDate = _parseDate(dateText);
            }
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }

      // Try to extract from link text if available
      final linkText = link.text.trim();
      if (linkText.isNotEmpty && linkText != filename) {
        // Might contain additional metadata
      }

      files.add(CloudFile(
        url: fileUrl,
        name: filename,
        type: fileType,
        size: size,
        modifiedDate: modifiedDate,
        folder: _extractFolder(href, baseUrl),
      ));
    }

    return files;
  }

  /// Parses a size string (e.g., "1.5M", "500K", "1024") into bytes.
  int? _parseSize(String sizeText) {
    if (sizeText.isEmpty) return null;

    final text = sizeText.trim().toUpperCase();
    if (text == '-' || text == 'DIR' || text == 'DIRECTORY') return null;

    try {
      // Try to parse as number with unit
      final regex = RegExp(r'([\d.]+)\s*([KMG]?)');
      final match = regex.firstMatch(text);
      if (match != null) {
        final value = double.parse(match.group(1)!);
        final unit = match.group(2) ?? '';

        switch (unit) {
          case 'K':
            return (value * 1024).round();
          case 'M':
            return (value * 1024 * 1024).round();
          case 'G':
            return (value * 1024 * 1024 * 1024).round();
          default:
            return value.round();
        }
      }

      // Try to parse as plain number
      return int.parse(text);
    } catch (e) {
      return null;
    }
  }

  /// Parses a date string into a DateTime object.
  DateTime? _parseDate(String dateText) {
    if (dateText.isEmpty) return null;

    try {
      // Common formats:
      // "2024-01-15 10:30:00"
      // "15-Jan-2024 10:30"
      // "2024-01-15"

      // Try ISO format first
      if (dateText.contains('-')) {
        final parts = dateText.trim().split(RegExp(r'\s+'));
        if (parts.isNotEmpty) {
          final datePart = parts[0];
          if (datePart.contains('-')) {
            final dateComponents = datePart.split('-');
            if (dateComponents.length == 3) {
              final year = int.parse(dateComponents[0]);
              final month = int.parse(dateComponents[1]);
              final day = int.parse(dateComponents[2]);

              int hour = 0, minute = 0, second = 0;
              if (parts.length > 1) {
                final timePart = parts[1];
                final timeComponents = timePart.split(':');
                if (timeComponents.length >= 2) {
                  hour = int.parse(timeComponents[0]);
                  minute = int.parse(timeComponents[1]);
                  if (timeComponents.length >= 3) {
                    second = int.parse(timeComponents[2]);
                  }
                }
              }

              return DateTime(year, month, day, hour, minute, second);
            }
          }
        }
      }

      // Try other formats if needed
      // For now, return null if we can't parse
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Extracts the folder path from a href relative to baseUrl.
  String _extractFolder(String href, String baseUrl) {
    if (href.startsWith('http://') || href.startsWith('https://')) {
      final uri = Uri.parse(href);
      final path = uri.path;
      final lastSlash = path.lastIndexOf('/');
      if (lastSlash > 0) {
        return path.substring(0, lastSlash);
      }
      return '';
    } else if (href.contains('/')) {
      final parts = href.split('/');
      if (parts.length > 1) {
        return parts.sublist(0, parts.length - 1).join('/');
      }
    }
    return '';
  }

  /// Creates a CloudFile from a src attribute (img, video, source tags).
  CloudFile? _createCloudFileFromSrc(String src, String cleanBaseUrl, String baseUrl) {
    if (src.isEmpty) return null;

    // Skip data URIs and external URLs if needed
    if (src.startsWith('data:') || src.startsWith('javascript:')) {
      return null;
    }

    // Skip UI assets (common web app asset paths)
    final lowerSrc = src.toLowerCase();
    if (lowerSrc.contains('/data/') || 
        lowerSrc.contains('/static/') || 
        lowerSrc.contains('/assets/') ||
        lowerSrc.contains('/css/') ||
        lowerSrc.contains('/js/') ||
        lowerSrc.contains('/images/ui/') ||
        lowerSrc.contains('/icons/') ||
        lowerSrc.contains('favicon') ||
        lowerSrc.contains('logo') ||
        lowerSrc.contains('upload-fab')) {
      return null;
    }

    // Extract filename
    String filename = src;
    if (filename.contains('/')) {
      filename = filename.split('/').last;
    }
    if (filename.contains('?')) {
      filename = filename.split('?').first;
    }
    if (filename.contains('#')) {
      filename = filename.split('#').first;
    }

    if (filename.isEmpty) return null;

    // Determine file type
    final fileType = FileTypeHelper.fromExtension(filename);
    if (!fileType.isImage && !fileType.isVideo) return null;

    // Construct full URL
    String fileUrl;
    if (src.startsWith('http://') || src.startsWith('https://')) {
      fileUrl = src;
    } else if (src.startsWith('/')) {
      fileUrl = '$cleanBaseUrl$src';
    } else {
      fileUrl = '$cleanBaseUrl/$src';
    }

    return CloudFile(
      url: fileUrl,
      name: filename,
      type: fileType,
      folder: _extractFolder(src, baseUrl),
    );
  }
}


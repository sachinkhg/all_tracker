import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';

/// Widget for displaying a thumbnail of a cloud file (image or video).
class FileThumbnailWidget extends StatefulWidget {
  final CloudFile file;
  final FileServerConfig config;
  final double? width;
  final double? height;
  final BoxFit fit;

  const FileThumbnailWidget({
    super.key,
    required this.file,
    required this.config,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  State<FileThumbnailWidget> createState() => _FileThumbnailWidgetState();
}

class _FileThumbnailWidgetState extends State<FileThumbnailWidget> {
  String? _videoThumbnailPath;

  @override
  void initState() {
    super.initState();
    if (widget.file.isVideo) {
      _generateVideoThumbnail();
    }
  }

  Future<void> _generateVideoThumbnail() async {
    try {
      // Generate thumbnail for video
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.file.url,
        thumbnailPath: (await Directory.systemTemp).path,
        imageFormat: ImageFormat.PNG,
        maxWidth: widget.width?.toInt() ?? 300,
        quality: 75,
        headers: widget.config.requiresAuth
            ? {
                'Authorization':
                    'Basic ${_getBasicAuth(widget.config.username, widget.config.password)}',
              }
            : null,
      );

      if (mounted && thumbnailPath != null) {
        setState(() {
          _videoThumbnailPath = thumbnailPath;
        });
      }
    } catch (e) {
      // If thumbnail generation fails, we'll show a placeholder
    }
  }

  String _getBasicAuth(String username, String password) {
    return base64Encode(utf8.encode('$username:$password'));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.file.isImage) {
      return _buildImageThumbnail();
    } else if (widget.file.isVideo) {
      return _buildVideoThumbnail();
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildImageThumbnail() {
    // Build headers for authenticated requests
    final headers = widget.config.requiresAuth
        ? {
            'Authorization':
                'Basic ${_getBasicAuth(widget.config.username, widget.config.password)}',
          }
        : null;

    return CachedNetworkImage(
      imageUrl: widget.file.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      httpHeaders: headers,
      placeholder: (context, url) => Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      errorWidget: (context, url, error) => _buildPlaceholder(),
    );
  }

  Widget _buildVideoThumbnail() {
    if (_videoThumbnailPath != null) {
      return Image.file(
        File(_videoThumbnailPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else {
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam, size: 32, color: Colors.grey),
            const SizedBox(height: 8),
            const CircularProgressIndicator(),
          ],
        ),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Icon(
        widget.file.isImage ? Icons.image : Icons.videocam,
        size: 32,
        color: Colors.grey[600],
      ),
    );
  }
}


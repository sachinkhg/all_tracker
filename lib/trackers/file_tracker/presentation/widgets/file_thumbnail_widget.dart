import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';
import '../../data/services/thumbnail_cache_service.dart';

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
  Uint8List? _videoThumbnailBytes;
  bool _thumbnailGenerationFailed = false;
  VideoPlayerController? _videoController;
  bool _useVideoPlayerFallback = false;
  final _cacheService = ThumbnailCacheService.instance;

  @override
  void initState() {
    super.initState();
    if (widget.file.isVideo) {
      _loadOrGenerateVideoThumbnail();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  /// Loads thumbnail from cache or generates a new one if not cached.
  Future<void> _loadOrGenerateVideoThumbnail() async {
    // Initialize cache service
    await _cacheService.initialize();

    // Try to load from cache first
    final stableId = widget.file.stableIdentifier;
    final cachedBytes = await _cacheService.getCachedThumbnailBytes(stableId);
    
    if (cachedBytes != null && mounted) {
      setState(() {
        _videoThumbnailBytes = cachedBytes;
        _thumbnailGenerationFailed = false;
      });
      return;
    }

    // If not in cache, check for cached file path
    final cachedPath = await _cacheService.getCachedThumbnailPath(stableId);
    if (cachedPath != null && mounted) {
      setState(() {
        _videoThumbnailPath = cachedPath;
        _thumbnailGenerationFailed = false;
      });
      return;
    }

    // If not cached, generate new thumbnail
    await _generateVideoThumbnail();
  }

  Future<void> _generateVideoThumbnail() async {
    try {
      // First, try to generate thumbnail using video_thumbnail package
      // Try thumbnailData first (works better with network URLs)
      try {
        final thumbnailBytes = await VideoThumbnail.thumbnailData(
          video: widget.file.url,
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

        if (mounted && thumbnailBytes != null) {
          // Cache the thumbnail bytes
          final stableId = widget.file.stableIdentifier;
          await _cacheService.cacheThumbnail(stableId, thumbnailBytes);
          
          setState(() {
            _videoThumbnailBytes = thumbnailBytes;
            _thumbnailGenerationFailed = false;
          });
          return;
        }
      } catch (e) {
        // If thumbnailData fails, try thumbnailFile
      }

      // Fallback to thumbnailFile method
      final thumbnailPath = await VideoThumbnail.thumbnailFile(
        video: widget.file.url,
        thumbnailPath: (Directory.systemTemp).path,
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
        // Cache the thumbnail file
        final stableId = widget.file.stableIdentifier;
        await _cacheService.cacheThumbnailFromFile(stableId, thumbnailPath);
        
        setState(() {
          _videoThumbnailPath = thumbnailPath;
          _thumbnailGenerationFailed = false;
        });
      } else if (mounted) {
        setState(() {
          _thumbnailGenerationFailed = true;
        });
      }
    } catch (e) {
      // If thumbnail generation fails, try video_player as fallback
      if (mounted) {
        _tryVideoPlayerFallback();
      }
    }
  }

  Future<void> _tryVideoPlayerFallback() async {
    try {
      // Build headers for authenticated requests
      final headers = widget.config.requiresAuth
          ? {
              'Authorization':
                  'Basic ${_getBasicAuth(widget.config.username, widget.config.password)}',
            }
          : <String, String>{};

      // Create video player controller
      _videoController = headers.isNotEmpty
          ? VideoPlayerController.networkUrl(
              Uri.parse(widget.file.url),
              httpHeaders: headers,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : VideoPlayerController.networkUrl(
              Uri.parse(widget.file.url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            );

      await _videoController!.initialize();
      
      // Seek to 1 second to get a frame
      await _videoController!.seekTo(const Duration(seconds: 1));
      
      if (mounted) {
        setState(() {
          _useVideoPlayerFallback = true;
          _thumbnailGenerationFailed = false;
        });
      }
    } catch (e) {
      // If video player also fails, show placeholder
      if (mounted) {
        setState(() {
          _thumbnailGenerationFailed = true;
        });
      }
      _videoController?.dispose();
      _videoController = null;
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
      key: ValueKey(widget.file.stableIdentifier),
      imageUrl: widget.file.url,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      httpHeaders: headers,
      cacheKey: widget.file.stableIdentifier,
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
    if (_videoThumbnailBytes != null) {
      return Image.memory(
        _videoThumbnailBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_videoThumbnailPath != null) {
      return Image.file(
        File(_videoThumbnailPath!),
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholder(),
      );
    } else if (_useVideoPlayerFallback && _videoController != null && _videoController!.value.isInitialized) {
      // Use video player to show a frame as thumbnail
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
      );
    } else if (_thumbnailGenerationFailed) {
      // Show placeholder if thumbnail generation failed
      return _buildPlaceholder();
    } else {
      // Show loading indicator while generating thumbnail
      return Container(
        width: widget.width,
        height: widget.height,
        color: Colors.grey[300],
        child: Center(
        child: Column(
            mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
              const Icon(Icons.videocam, size: 24, color: Colors.grey),
              const SizedBox(height: 4),
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
          ],
          ),
        ),
      );
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: widget.width,
      height: widget.height,
      color: Colors.grey[300],
      child: Center(
      child: Icon(
        widget.file.isImage ? Icons.image : Icons.videocam,
          size: widget.width != null && widget.width! < 60 ? 24 : 32,
        color: Colors.grey[600],
        ),
      ),
    );
  }
}


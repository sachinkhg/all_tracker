import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/file_server_config.dart';

/// Full-screen image viewer page with previous/next navigation.
class FileViewerPage extends StatefulWidget {
  final List<CloudFile> files;
  final int initialIndex;
  final FileServerConfig config;

  const FileViewerPage({
    super.key,
    required this.files,
    required this.initialIndex,
    required this.config,
  });

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  late PageController _pageController;
  late int _currentIndex;
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _showVideoControls = true;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _initializeVideoIfNeeded();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _initializeVideoIfNeeded() {
    final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();
    if (_currentIndex < mediaFiles.length) {
      final currentFile = mediaFiles[_currentIndex];
      if (currentFile.isVideo) {
        _initializeVideo(currentFile);
      }
    }
  }

  void _initializeVideo(CloudFile file) {
    // Dispose previous controller
    _videoController?.dispose();
    _isVideoInitialized = false;

    // Build headers for authenticated requests
    final headers = widget.config.requiresAuth
        ? {
            'Authorization':
                'Basic ${_getBasicAuth(widget.config.username, widget.config.password)}',
          }
        : <String, String>{};

    // Initialize video player
    try {
      _videoController = headers.isNotEmpty
          ? VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              httpHeaders: headers,
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            )
          : VideoPlayerController.networkUrl(
              Uri.parse(file.url),
              videoPlayerOptions: VideoPlayerOptions(mixWithOthers: false),
            );
    } catch (e) {
      // Error creating video controller
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
      return;
    }

    _videoController!.initialize().then((_) {
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        // Auto-play video
        _videoController!.play();
      }
    }).catchError((error) {
      // Error initializing video
      if (mounted) {
        setState(() {
          _isVideoInitialized = false;
        });
      }
    });

    // Listen to video player state changes
    _videoController!.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.files.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();
    
    if (mediaFiles.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Viewer')),
        body: const Center(child: Text('No images or videos to display')),
      );
    }

    // Adjust current index to match filtered list
    int adjustedIndex = _currentIndex;
    if (adjustedIndex >= mediaFiles.length) {
      adjustedIndex = mediaFiles.length - 1;
    }
    if (adjustedIndex < 0) {
      adjustedIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          '${adjustedIndex + 1} / ${mediaFiles.length}',
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // File name
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Center(
              child: Text(
                mediaFiles[adjustedIndex].name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // PageView for images/videos
          PageView.builder(
            controller: _pageController,
            itemCount: mediaFiles.length,
            onPageChanged: (index) {
              // Dispose previous video controller
              _videoController?.pause();
              _videoController?.dispose();
              _videoController = null;
              _isVideoInitialized = false;

              setState(() {
                _currentIndex = index;
              });

              // Initialize video if the new page is a video
              final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();
              if (index < mediaFiles.length) {
                final newFile = mediaFiles[index];
                if (newFile.isVideo) {
                  _initializeVideo(newFile);
                }
              }
            },
            itemBuilder: (context, index) {
              final file = mediaFiles[index];
              if (file.isImage) {
                return Center(
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: _buildImageView(file),
                  ),
                );
              } else {
                // Videos don't use InteractiveViewer
                return _buildVideoView(file);
              }
            },
          ),

          // Previous button
          if (adjustedIndex > 0)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    heroTag: 'prev',
                    backgroundColor: Colors.black54,
                    onPressed: _goToPrevious,
                    child: const Icon(Icons.chevron_left),
                  ),
                ),
              ),
            ),

          // Next button
          if (adjustedIndex < mediaFiles.length - 1)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: FloatingActionButton(
                    heroTag: 'next',
                    backgroundColor: Colors.black54,
                    onPressed: _goToNext,
                    child: const Icon(Icons.chevron_right),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageView(CloudFile file) {
    // Build headers for authenticated requests
    final headers = widget.config.requiresAuth
        ? {
            'Authorization':
                'Basic ${_getBasicAuth(widget.config.username, widget.config.password)}',
          }
        : null;

    return CachedNetworkImage(
      imageUrl: file.url,
      fit: BoxFit.contain,
      httpHeaders: headers,
      placeholder: (context, url) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
      errorWidget: (context, url, error) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load image',
              style: const TextStyle(color: Colors.white),
            ),
            Text(
              error.toString(),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView(CloudFile file) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showVideoControls = !_showVideoControls;
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video player
          if (_videoController != null && _isVideoInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
            )
          else
            // Loading or error state
            Center(
              child: _videoController == null || !_isVideoInitialized
                  ? const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Loading video...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'Failed to load video',
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          file.name,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
            ),

          // Video controls overlay
          if (_videoController != null && _isVideoInitialized && _showVideoControls)
            Positioned.fill(
              child: Container(
                color: Colors.black38,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Play/Pause button
                    IconButton(
                      icon: Icon(
                        _videoController!.value.isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_filled,
                        size: 64,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        setState(() {
                          if (_videoController!.value.isPlaying) {
                            _videoController!.pause();
                          } else {
                            _videoController!.play();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    // Progress indicator and time
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Text(
                            _formatDuration(_videoController!.value.position),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          Expanded(
                            child: VideoProgressIndicator(
                              _videoController!,
                              allowScrubbing: true,
                              colors: const VideoProgressColors(
                                playedColor: Colors.white,
                                bufferedColor: Colors.white54,
                                backgroundColor: Colors.white24,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_videoController!.value.duration),
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }

  String _getBasicAuth(String username, String password) {
    return base64Encode(utf8.encode('$username:$password'));
  }
}


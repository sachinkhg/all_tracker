import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _isFullScreen = false;
  bool _isLandscapeLocked = false;
  bool _isShuffleOn = false;
  final Set<int> _playedIndices = {}; // Track played videos when shuffle is on
  final Random _random = Random();
  Timer? _controlsTimer;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _playedIndices.add(widget.initialIndex); // Mark initial video as played
    _initializeVideoIfNeeded();
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _exitFullScreen();
    _videoController?.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showControlsTemporarily() {
    setState(() {
      _showVideoControls = true;
    });
    
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _isFullScreen) {
        setState(() {
          _showVideoControls = false;
        });
      }
    });
  }

  void _enterFullScreen() {
    if (_isFullScreen) return;
    
    setState(() {
      _isFullScreen = true;
      _showVideoControls = false; // Hide controls initially in fullscreen
    });
    
    // Hide system UI for fullscreen
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    
    // Unlock orientation for fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  void _exitFullScreen() {
    if (!_isFullScreen) return;
    
    setState(() {
      _isFullScreen = false;
      _isLandscapeLocked = false;
    });
    
    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );
    
    // Force portrait mode when exiting fullscreen
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
    
    // After a short delay, restore all orientations
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    });
  }

  void _toggleOrientationLock() {
    setState(() {
      _isLandscapeLocked = !_isLandscapeLocked;
    });
    
    if (_isLandscapeLocked) {
      // Lock to landscape
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Unlock orientation - force portrait first, then allow all
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      
      // After a short delay, restore all orientations
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
            DeviceOrientation.landscapeLeft,
            DeviceOrientation.landscapeRight,
          ]);
        }
      });
    }
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
    final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();
    
    if (_isShuffleOn) {
      // In shuffle mode, go to a random unplayed video
      final unplayedIndices = List.generate(mediaFiles.length, (i) => i)
          .where((i) => !_playedIndices.contains(i) && i != _currentIndex)
          .toList();
      
      if (unplayedIndices.isEmpty) {
        // All videos played, reset and pick a random one
        _playedIndices.clear();
        _playedIndices.add(_currentIndex);
        final availableIndices = List.generate(mediaFiles.length, (i) => i)
            .where((i) => i != _currentIndex)
            .toList();
        if (availableIndices.isNotEmpty) {
          final randomIndex = availableIndices[_random.nextInt(availableIndices.length)];
          _navigateToIndex(randomIndex);
          _playedIndices.add(randomIndex);
        }
      } else {
        final randomIndex = unplayedIndices[_random.nextInt(unplayedIndices.length)];
        _navigateToIndex(randomIndex);
        _playedIndices.add(randomIndex);
      }
    } else {
      // Normal mode: go to previous index
      if (_currentIndex > 0) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _goToNext() {
    final mediaFiles = widget.files.where((f) => f.isImage || f.isVideo).toList();
    
    if (_isShuffleOn) {
      // In shuffle mode, go to a random unplayed video
      final unplayedIndices = List.generate(mediaFiles.length, (i) => i)
          .where((i) => !_playedIndices.contains(i) && i != _currentIndex)
          .toList();
      
      if (unplayedIndices.isEmpty) {
        // All videos played, reset and pick a random one
        _playedIndices.clear();
        _playedIndices.add(_currentIndex);
        final availableIndices = List.generate(mediaFiles.length, (i) => i)
            .where((i) => i != _currentIndex)
            .toList();
        if (availableIndices.isNotEmpty) {
          final randomIndex = availableIndices[_random.nextInt(availableIndices.length)];
          _navigateToIndex(randomIndex);
          _playedIndices.add(randomIndex);
        }
      } else {
        final randomIndex = unplayedIndices[_random.nextInt(unplayedIndices.length)];
        _navigateToIndex(randomIndex);
        _playedIndices.add(randomIndex);
      }
    } else {
      // Normal mode: go to next index
      if (_currentIndex < mediaFiles.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _navigateToIndex(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _toggleShuffle() {
    setState(() {
      _isShuffleOn = !_isShuffleOn;
      if (_isShuffleOn) {
        // When enabling shuffle, reset played list and add current
        _playedIndices.clear();
        _playedIndices.add(_currentIndex);
      }
    });
  }

  void _seekBackward() {
    if (_videoController != null && _isVideoInitialized) {
      final currentPosition = _videoController!.value.position;
      final newPosition = currentPosition - const Duration(seconds: 10);
      _videoController!.seekTo(newPosition < Duration.zero ? Duration.zero : newPosition);
      if (_isFullScreen) {
        _showControlsTemporarily();
      }
    }
  }

  void _seekForward() {
    if (_videoController != null && _isVideoInitialized) {
      final currentPosition = _videoController!.value.position;
      final duration = _videoController!.value.duration;
      final newPosition = currentPosition + const Duration(seconds: 10);
      _videoController!.seekTo(newPosition > duration ? duration : newPosition);
      if (_isFullScreen) {
        _showControlsTemporarily();
      }
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

    return PopScope(
      canPop: !_isFullScreen,
      onPopInvoked: (didPop) {
        if (!didPop && _isFullScreen) {
          _exitFullScreen();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: _isFullScreen ? null : AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          mediaFiles[adjustedIndex].decodedName,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          // Shuffle toggle button
          IconButton(
            icon: Icon(
              _isShuffleOn ? Icons.shuffle : Icons.shuffle_outlined,
              color: _isShuffleOn ? Colors.blue : Colors.white,
            ),
            onPressed: _toggleShuffle,
            tooltip: _isShuffleOn ? 'Shuffle: On' : 'Shuffle: Off',
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
                // Track played videos when shuffle is on
                if (_isShuffleOn) {
                  _playedIndices.add(index);
                }
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
                return GestureDetector(
                  onTap: () {
                    if (_isFullScreen) {
                      _exitFullScreen();
                    } else {
                      _enterFullScreen();
                    }
                  },
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 0.5,
                      maxScale: 4.0,
                      child: _buildImageView(file),
                    ),
                  ),
                );
              } else {
                // Videos don't use InteractiveViewer
                return _buildVideoView(file);
              }
            },
          ),

          // Exit fullscreen button (always visible when in fullscreen mode)
          if (_isFullScreen)
            Positioned(
              top: 0,
              right: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () {
                      _exitFullScreen();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                      padding: const EdgeInsets.all(12),
                    ),
                    tooltip: 'Exit fullscreen',
                  ),
                ),
              ),
            ),

          // Previous button
          // Show if: normal mode and not at first, OR shuffle mode and there are other videos
          if ((!_isShuffleOn && adjustedIndex > 0) || 
              (_isShuffleOn && mediaFiles.length > 1))
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
          // Show if: normal mode and not at last, OR shuffle mode and there are other videos
          if ((!_isShuffleOn && adjustedIndex < mediaFiles.length - 1) || 
              (_isShuffleOn && mediaFiles.length > 1))
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
        if (_isFullScreen) {
          _showControlsTemporarily();
        } else {
          setState(() {
            _showVideoControls = !_showVideoControls;
          });
        }
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
                          file.decodedName,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
            ),

          // Video controls overlay - positioned at bottom
          if (_videoController != null && _isVideoInitialized && _showVideoControls)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Progress indicator and time
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                      // Control buttons row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Seek backward button
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10,
                                size: 28,
                                color: Colors.white,
                              ),
                              onPressed: _seekBackward,
                              tooltip: 'Seek backward 10 seconds',
                            ),
                            // Play/Pause button
                            IconButton(
                              icon: Icon(
                                _videoController!.value.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                size: 32,
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
                                if (_isFullScreen) {
                                  _showControlsTemporarily();
                                }
                              },
                            ),
                            // Seek forward button
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10,
                                size: 28,
                                color: Colors.white,
                              ),
                              onPressed: _seekForward,
                              tooltip: 'Seek forward 10 seconds',
                            ),
                            // Fullscreen button
                            IconButton(
                              icon: Icon(
                                _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                                size: 28,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                if (_isFullScreen) {
                                  _exitFullScreen();
                                } else {
                                  _enterFullScreen();
                                }
                              },
                              tooltip: _isFullScreen ? 'Exit fullscreen' : 'Enter fullscreen',
                            ),
                            // Orientation lock button
                            IconButton(
                              icon: Icon(
                                _isLandscapeLocked ? Icons.screen_lock_rotation : Icons.screen_rotation,
                                size: 28,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _toggleOrientationLock();
                                if (_isFullScreen) {
                                  _showControlsTemporarily();
                                }
                              },
                              tooltip: _isLandscapeLocked ? 'Unlock orientation' : 'Lock to landscape',
                            ),
                            // Shuffle button
                            IconButton(
                              icon: Icon(
                                _isShuffleOn ? Icons.shuffle : Icons.shuffle_outlined,
                                size: 28,
                                color: _isShuffleOn ? Colors.blue : Colors.white,
                              ),
                              onPressed: () {
                                _toggleShuffle();
                                if (_isFullScreen) {
                                  _showControlsTemporarily();
                                }
                              },
                              tooltip: _isShuffleOn ? 'Shuffle: On' : 'Shuffle: Off',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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


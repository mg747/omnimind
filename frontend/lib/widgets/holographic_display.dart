import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:share_plus/share_plus.dart';

class HolographicDisplay extends StatefulWidget {
  final String videoUrl;
  final String assetId; // Unique ID for caching (e.g., hash of prompt)
  final double width;
  final double height;
  final bool isStream;
  final String? subtitleUrl;
  final bool showSubtitles;

  const HolographicDisplay({
    super.key,
    required this.videoUrl,
    required this.assetId,
    this.width = 300,
    this.height = 300,
    this.isStream = false,
    this.subtitleUrl,
    this.showSubtitles = true,
  });

  @override
  State<HolographicDisplay> createState() => _HolographicDisplayState();
}

class _HolographicDisplayState extends State<HolographicDisplay> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void didUpdateWidget(HolographicDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl || oldWidget.subtitleUrl != widget.subtitleUrl) {
      _disposeController();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    if (!widget.videoUrl.startsWith('http') && !widget.videoUrl.startsWith('https') && !widget.videoUrl.startsWith('file://')) {
       print("Invalid or mock video URL, skipping initialization: ${widget.videoUrl}");
       setState(() {
         _loading = false;
         _error = "Awaiting Visual Data..."; // Default idle state instead of error
       });
       return;
    }

    try {
      if (widget.isStream) {
        ClosedCaptionFile? captionFile;
        // ... (Closed caption logic remains)
        if (widget.subtitleUrl != null) {
          try {
            final response = await Dio().get(widget.subtitleUrl!);
            if (response.statusCode == 200) {
              captionFile = WebVTTCaptionFile(response.data.toString());
            }
          } catch (e) {
            print("Failed to load subtitles: $e");
          }
        }

        _controller = VideoPlayerController.networkUrl(
          Uri.parse(widget.videoUrl),
          closedCaptionFile: captionFile != null ? Future.value(captionFile) : null,
        )..initialize().then((_) {
            _controller!.setLooping(true);
            _controller!.play();
            if (mounted) {
               setState(() {
                 _isInitialized = true;
                 _loading = false;
               });
            }
          });
      } else {
        // Fallback for Web/Unsupported platforms for local files: just stream it.
        try {
           final directory = await getApplicationDocumentsDirectory();
           File videoFile = await _getCachedVideoFile(widget.videoUrl, widget.assetId, directory.path);
           _controller = VideoPlayerController.file(videoFile);
        } catch (e) {
           print("Local cache unsupported or failed ($e), falling back to network stream.");
           _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
        }
        
        _controller!.initialize().then((_) {
            _controller!.setLooping(true);
            _controller!.play();
            if (mounted) {
               setState(() {
                 _isInitialized = true;
                 _loading = false;
               });
            }
          });
      }
    } catch (e) {
      if (mounted) {
         setState(() {
           _error = "Hologram Malfunction: $e";
           _loading = false;
         });
      }
      print("Error loading video: $e");
    }
  }

  Future<File> _getCachedVideoFile(String url, String id, String dirPath) async {
    final filePath = '$dirPath/asset_$id.webm';
    final file = File(filePath);

    if (await file.exists()) {
      print("Loading from cache: $filePath");
      return file; // Return cached file
    }

    print("Downloading asset to cache: $url");
    try {
      await Dio().download(url, filePath);
      return file;
    } catch (e) {
      // If download fails, maybe return a fallback or rethrow
      rethrow;
    }
  }

  void _disposeController() {
    _controller?.dispose();
    _controller = null;
    _isInitialized = false;
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.cyanAccent.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 5,
          )
        ],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Center(
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return const CircularProgressIndicator(color: Colors.cyanAccent);
    }
    
    if (_error != null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 40),
          const SizedBox(height: 10),
          Text(
            "simulation.signal_lost".tr(),
            style: const TextStyle(color: Colors.redAccent, fontFamily: 'Courier'),
          ),
        ],
      );
    }

    if (_isInitialized && _controller != null) {
      return Stack(
        alignment: Alignment.bottomCenter,
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: VideoPlayer(_controller!),
          ),
          if (widget.showSubtitles)
            ClosedCaption(
              text: _controller!.value.caption.text,
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                backgroundColor: Colors.black54,
              ),
            ),
          Positioned(
            top: 10,
            right: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.download, color: Colors.white70),
                  tooltip: 'Download Video Data',
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('simulation.downloading_visuals'.tr())),
                     );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share, color: Colors.cyanAccent),
                  tooltip: 'Share Simulation',
                  onPressed: () {
                     Share.share('Watch my OmniMind cinematic generation: ${widget.videoUrl}');
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }

    return const SizedBox.shrink();
  }
}

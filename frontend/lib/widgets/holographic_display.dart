import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

class HolographicDisplay extends StatefulWidget {
  final String videoUrl;
  final String assetId; // Unique ID for caching (e.g., hash of prompt)
  final double width;
  final double height;

  const HolographicDisplay({
    super.key,
    required this.videoUrl,
    required this.assetId,
    this.width = 300,
    this.height = 300,
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
    if (oldWidget.videoUrl != widget.videoUrl) {
      _disposeController();
      _initializeVideo();
    }
  }

  Future<void> _initializeVideo() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      File videoFile = await _getCachedVideoFile(widget.videoUrl, widget.assetId);
      
      _controller = VideoPlayerController.file(videoFile)
        ..initialize().then((_) {
          _controller!.setLooping(true);
          _controller!.play();
          setState(() {
            _isInitialized = true;
            _loading = false;
          });
        });
    } catch (e) {
      setState(() {
        _error = "Hologram Malfunction: $e";
        _loading = false;
      });
      print("Error loading video: $e");
    }
  }

  Future<File> _getCachedVideoFile(String url, String id) async {
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/asset_$id.webm';
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
            "SIGNAL LOST",
            style: TextStyle(color: Colors.redAccent, fontFamily: 'Courier'),
          ),
        ],
      );
    }

    if (_isInitialized && _controller != null) {
      return AspectRatio(
        aspectRatio: _controller!.value.aspectRatio,
        child: VideoPlayer(_controller!),
      );
    }

    return const SizedBox.shrink();
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../services/kyc_service.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        debugPrint('No cameras found');
        return;
      }
      _controller = CameraController(cameras.first, ResolutionPreset.medium);
      await _controller!.initialize();
      await _controller!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isScanning) return;
    _isScanning = true;

    // Convert CameraImage to InputImage for ML Kit
    // (This requires specific format conversion, simplified here for conceptual flow)
    // In production, use Google ML Kit's input image factory
    
    // final recognizedText = await _textRecognizer.processImage(...);
    // if (recognizedText.text.contains('ID')) {
    //    // Found ID, perform verification
    //    _controller?.stopImageStream();
    // }

    _isScanning = false;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(_controller!);
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import '../services/kyc_service.dart';
import '../utils/ml_kit_utils.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({super.key});

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView> {
  CameraController? _controller;
  final TextRecognizer _textRecognizer = TextRecognizer();
  late ObjectDetector _objectDetector;
  bool _isScanning = false;
  String _message = 'Align your ID within the frame';
  bool _handDetected = false;
  final KycService _kycService = KycService();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeObjectDetector();
  }

  void _initializeObjectDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      _controller = CameraController(
        cameras.first, 
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.nv21,
      );
      
      await _controller!.initialize();
      await _controller!.startImageStream(_processCameraImage);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isScanning || _controller == null) return;
    _isScanning = true;

    try {
      final inputImage = MlKitUtils.inputImageFromCameraImage(
        image: image,
        camera: _controller!.description,
        controller: _controller!,
      );

      if (inputImage == null) {
        _isScanning = false;
        return;
      }

      // 1. Detect Hand/Objects
      final objects = await _objectDetector.processImage(inputImage);
      bool handInFrame = false;
      for (final obj in objects) {
        for (final label in obj.labels) {
          if (label.text.toLowerCase().contains('hand') || 
              label.text.toLowerCase().contains('person')) {
            handInFrame = true;
            break;
          }
        }
      }

      // 2. Detect Text
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text.toUpperCase();
      
      // Look for ID patterns (e.g., "NATIONAL ID" or "IDENTITY CARD")
      final hasIdKeywords = text.contains('NATIONAL ID') || text.contains('IDENTITY');
      
      // Look for 8-9 digit sequences
      final idNumberMatch = RegExp(r'\b\d{8,9}\b').firstMatch(text);
      final hasIdNumber = idNumberMatch != null;

      if (mounted) {
        setState(() {
          _handDetected = handInFrame;
          if (!handInFrame) {
            _message = 'Please hold your ID with your hand';
          } else if (hasIdKeywords && hasIdNumber) {
            _message = 'ID Detected! Processing...';
            _finalizeVerification(idNumberMatch!.group(0)!);
          } else {
            _message = 'Scan your National ID card';
          }
        });
      }
    } catch (e) {
      debugPrint('Processing error: $e');
    }

    _isScanning = false;
  }

  Future<void> _finalizeVerification(String idNumber) async {
    await _controller?.stopImageStream();
    // Update KYC status and store ID number
    await _kycService.updateKycStatus('verified', idNumber: idNumber);
    if (mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ID Verification Successful')),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _textRecognizer.close();
    _objectDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),
          // Overlay mask
          ColorFiltered(
            colorFilter: ColorFilter.mode(
              Colors.black.withOpacity(0.5),
              BlendMode.srcOut,
            ),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 250,
                    width: 350,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Guidance UI
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: _handDetected ? Colors.green.withOpacity(0.8) : Colors.red.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 40),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white, size: 32),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

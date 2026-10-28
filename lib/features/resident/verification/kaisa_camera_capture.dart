import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class KaisaCameraCapture extends StatefulWidget {
  const KaisaCameraCapture({super.key});
  @override
  State<KaisaCameraCapture> createState() => _KaisaCameraCaptureState();
}

class _KaisaCameraCaptureState extends State<KaisaCameraCapture>
    with WidgetsBindingObserver {
  CameraController? camera;
  bool saving = false;
  String? error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _open();
  }

  Future<void> _open() async {
    try {
      final available = await availableCameras();
      if (available.isEmpty) throw Exception('No camera available');
      final selected = available.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => available.first,
      );
      final next = CameraController(
        selected,
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() => camera = next);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      camera?.dispose();
      camera = null;
    } else if (state == AppLifecycleState.resumed && mounted) {
      _open();
    }
  }

  Future<void> _take() async {
    final c = camera;
    if (c == null || saving || !c.value.isInitialized) return;
    setState(() => saving = true);
    try {
      final photo = await c.takePicture();
      final Uint8List data = await photo.readAsBytes();
      if (mounted) Navigator.pop(context, data);
    } catch (e) {
      if (mounted) setState(() => error = 'Capture failed: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    camera?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = camera;
    return Scaffold(
      backgroundColor: const Color(0xFF101C15),
      appBar: AppBar(
        title: const Text('Capture your valid ID'),
        backgroundColor: const Color(0xFF101C15),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      )
                    : c == null
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: c.value.aspectRatio,
                        child: CameraPreview(c),
                      ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(15),
              child: Text(
                'Keep the full ID in frame and make all text readable.',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: FilledButton.icon(
                onPressed: c == null || saving ? null : _take,
                icon: const Icon(Icons.camera_alt_outlined),
                label: Text(saving ? 'Capturing...' : 'Take photo'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

part of '../feed_page.dart';

class _StoryCameraScreen extends StatefulWidget {
  const _StoryCameraScreen();
  @override
  State<_StoryCameraScreen> createState() => _StoryCameraScreenState();
}

class _StoryCameraScreenState extends State<_StoryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;
  bool _capturing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  Future<void> _initialize([int? selectedIndex]) async {
    final old = _controller;
    _controller = null;
    if (mounted) setState(() => _error = null);
    await old?.dispose();
    try {
      final devices = await availableCameras();
      if (devices.isEmpty) {
        throw StateError('No camera was detected on this device.');
      }
      _cameras = devices;
      _cameraIndex =
          selectedIndex ??
          devices.indexWhere(
            (d) => d.lensDirection == CameraLensDirection.front,
          );
      if (_cameraIndex < 0 || _cameraIndex >= devices.length) _cameraIndex = 0;
      final next = CameraController(
        devices[_cameraIndex],
        ResolutionPreset.medium,
        enableAudio: false,
      );
      await next.initialize();
      if (!mounted) {
        await next.dispose();
        return;
      }
      setState(() => _controller = next);
    } catch (e) {
      if (mounted) {
        setState(
          () => _error =
              'Camera unavailable: $e\n\nCheck browser/device camera permissions and close other apps using the camera.',
        );
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) {
      final previous = _controller;
      _controller = null;
      previous?.dispose();
    } else if (state == AppLifecycleState.resumed && mounted) {
      _initialize(_cameraIndex);
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (_capturing || controller == null || !controller.value.isInitialized) {
      return;
    }
    setState(() => _capturing = true);
    try {
      final picture = await controller.takePicture();
      final data = await picture.readAsBytes();
      if (mounted) Navigator.of(context).pop(data);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not take photo: $e');
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: const Color(0xFF101C15),
      appBar: AppBar(
        title: const Text('Take a Story Photo'),
        backgroundColor: const Color(0xFF101C15),
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Close camera',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _error != null
                    ? Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            textStyle: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    : controller == null || !controller.value.isInitialized
                    ? const CircularProgressIndicator()
                    : AspectRatio(
                        aspectRatio: controller.value.aspectRatio,
                        child: CameraPreview(controller),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_cameras.length > 1)
                    IconButton(
                      tooltip: 'Switch camera',
                      onPressed: _capturing
                          ? null
                          : () => _initialize(
                              (_cameraIndex + 1) % _cameras.length,
                            ),
                      icon: const Icon(
                        Icons.cameraswitch_outlined,
                        color: Colors.white,
                      ),
                    ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: controller == null || _capturing
                        ? null
                        : _capture,
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: Text(_capturing ? 'Capturing...' : 'Capture photo'),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(
                        textStyle: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

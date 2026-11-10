import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// Minimal camera abstraction used by the camera page.
///
/// Step 1 is backed by the `camera` plugin. Step 2 can add a native
/// implementation that exposes frames, timestamps and encoding without
/// changing the camera page.
abstract class CameraService {
  bool get isReady;

  bool get canSwitch;

  double get aspectRatio;

  CameraDescription? get currentCamera;

  Future<void> initialize({bool preferFront = false});

  Widget buildPreview();

  Future<XFile> takePicture();

  Future<void> switchCamera();

  Future<void> dispose();
}

class PluginCameraService implements CameraService {
  List<CameraDescription> _cameras = const <CameraDescription>[];
  CameraController? _controller;
  int _cameraIndex = 0;

  @override
  bool get isReady => _controller?.value.isInitialized ?? false;

  @override
  bool get canSwitch => _cameras.length > 1;

  @override
  double get aspectRatio => _controller?.value.aspectRatio ?? 1.0;

  @override
  CameraDescription? get currentCamera => _controller?.description;

  @override
  Future<void> initialize({bool preferFront = false}) async {
    await dispose();
    _cameras = await availableCameras();
    if (_cameras.isEmpty) {
      throw CameraException(
        'no_cameras',
        'No cameras are available on this device.',
      );
    }
    _cameraIndex = _pickCameraIndex(preferFront: preferFront);
    await _createController(_cameras[_cameraIndex]);
  }

  int _pickCameraIndex({required bool preferFront}) {
    final target = preferFront
        ? CameraLensDirection.front
        : CameraLensDirection.back;
    final index = _cameras.indexWhere(
      (camera) => camera.lensDirection == target,
    );
    return index >= 0 ? index : 0;
  }

  Future<void> _createController(CameraDescription description) async {
    final controller = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    await controller.initialize();
    _controller = controller;
  }

  @override
  Widget buildPreview() {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      return const ColoredBox(color: Colors.black);
    }
    return CameraPreview(controller);
  }

  @override
  Future<XFile> takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) {
      throw CameraException(
        'not_initialized',
        'The camera is not ready yet.',
      );
    }
    return controller.takePicture();
  }

  @override
  Future<void> switchCamera() async {
    if (_cameras.length < 2) {
      return;
    }
    final nextIndex = (_cameraIndex + 1) % _cameras.length;
    await dispose();
    _cameraIndex = nextIndex;
    await _createController(_cameras[nextIndex]);
  }

  @override
  Future<void> dispose() async {
    final controller = _controller;
    _controller = null;
    if (controller != null) {
      await controller.dispose();
    }
  }
}

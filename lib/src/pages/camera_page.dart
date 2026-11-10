import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../camera/camera_service.dart';
import 'photo_preview_page.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key, this.cameraService});

  final CameraService? cameraService;

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  late final CameraService _camera =
      widget.cameraService ?? PluginCameraService();

  bool _initializing = true;
  bool _takingPicture = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _camera.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _camera.dispose();
      if (mounted) {
        setState(() {
          _initializing = true;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initialize();
    }
  }

  Future<void> _initialize({bool preferFront = false}) async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _error = null;
      });
    }
    try {
      await _camera.initialize(preferFront: preferFront);
    } on CameraException catch (error) {
      _error = _messageForCameraError(error);
    } catch (error) {
      _error = '相机启动失败：$error';
    } finally {
      if (mounted) {
        setState(() {
          _initializing = false;
        });
      }
    }
  }

  String _messageForCameraError(CameraException error) {
    if (error.code == 'CameraAccessDenied' ||
        error.code == 'CameraAccessDeniedWithoutPrompt' ||
        error.code == 'CameraAccessRestricted') {
      return '相机权限被拒绝。请在系统设置中允许 Comira 使用相机。';
    }
    if (error.code == 'no_cameras') {
      return '没有找到可用的摄像头。';
    }
    return '相机启动失败：${error.description ?? error.code}';
  }

  Future<void> _takePicture() async {
    if (_takingPicture || !_camera.isReady) {
      return;
    }
    setState(() => _takingPicture = true);
    try {
      final file = await _camera.takePicture();
      if (!mounted) {
        return;
      }
      final saved = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PhotoPreviewPage(imagePath: file.path),
        ),
      );
      if (!mounted) {
        return;
      }
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已保存到相册')),
        );
      }
    } on CameraException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('拍照失败：${error.description ?? error.code}'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('拍照失败：$error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _takingPicture = false);
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_takingPicture || !_camera.canSwitch) {
      return;
    }
    setState(() {
      _initializing = true;
      _error = null;
    });
    try {
      await _camera.switchCamera();
    } on CameraException catch (error) {
      _error = _messageForCameraError(error);
    } catch (error) {
      _error = '切换摄像头失败：$error';
    } finally {
      if (mounted) {
        setState(() => _initializing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canShoot =
        !_initializing && _error == null && _camera.isReady && !_takingPicture;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('拍照'),
        actions: <Widget>[
          if (_camera.canSwitch)
            IconButton(
              onPressed: _takingPicture ? null : _switchCamera,
              tooltip: '切换摄像头',
              icon: const Icon(Icons.cameraswitch_outlined),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Positioned.fill(child: _buildPreview()),
            Positioned(
              left: 0,
              right: 0,
              bottom: 32,
              child: Center(
                child: Opacity(
                  opacity: canShoot ? 1 : 0.4,
                  child: _buildShutter(canShoot),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    if (_initializing) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(
                Icons.no_photography_outlined,
                color: Colors.white70,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _initialize(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: _camera.aspectRatio == 0 ? 1 : _camera.aspectRatio,
        child: _camera.buildPreview(),
      ),
    );
  }

  Widget _buildShutter(bool canShoot) {
    return GestureDetector(
      onTap: canShoot ? _takePicture : null,
      child: Container(
        width: 76,
        height: 76,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: _takingPicture
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(strokeWidth: 3),
                )
              : null,
        ),
      ),
    );
  }
}

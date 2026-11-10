import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

class PhotoPreviewPage extends StatefulWidget {
  const PhotoPreviewPage({super.key, required this.imagePath});

  final String imagePath;

  @override
  State<PhotoPreviewPage> createState() => _PhotoPreviewPageState();
}

class _PhotoPreviewPageState extends State<PhotoPreviewPage> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      var hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        hasAccess = await Gal.requestAccess();
      }
      if (!hasAccess) {
        if (!mounted) {
          return;
        }
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('相册权限被拒绝。请在系统设置中允许 Comira 访问相册。'),
          ),
        );
        return;
      }

      await Gal.putImage(widget.imagePath);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on GalException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_messageForGalError(error))),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败：$error')),
      );
    }
  }

  String _messageForGalError(GalException error) {
    return switch (error.type) {
      GalExceptionType.accessDenied =>
        '相册权限被拒绝。请在系统设置中允许 Comira 访问相册。',
      GalExceptionType.notEnoughSpace => '设备存储空间不足，无法保存照片。',
      GalExceptionType.notSupportedFormat => '当前照片格式不支持保存。',
      GalExceptionType.unexpected => '保存失败，请重试。',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('照片预览')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Text('照片读取失败'));
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('重拍'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存到相册'),
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

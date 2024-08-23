// ignore_for_file: avoid_print

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MaterialApp(
    home: CameraApp(camera: firstCamera),
  ));
}

class CameraApp extends StatefulWidget {
  final CameraDescription camera;

  const CameraApp({super.key, required this.camera});

  @override
  createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.high,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Video')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton.large(
        child: Icon(
            _controller.value.isRecordingVideo ? Icons.stop : Icons.circle,
            color: Colors.red,
            size: kMinInteractiveDimension),
        onPressed: () async {
          if (_controller.value.isRecordingVideo) {
            stopVideoRecording(context);
          } else {
            startVideoRecording(context);
          }
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  startVideoRecording(BuildContext c) async {
    try {
      await _initializeControllerFuture;

      await _controller.startVideoRecording();
      // Trigger recording button rebuild.
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  stopVideoRecording(BuildContext c) async {
    try {
      final video = await _controller.stopVideoRecording();
      print('recorded video: ${video.path}');
      // Trigger recording button rebuild.
      setState(() {});

      final src = File(video.path);
      final folder = (await getTemporaryDirectory()).path;
      // if (folder == null) {
      //   if (c.mounted) {
      //     dialog(c, title: '存檔錯誤', msg: '找不到 Download 路徑');
      //   }
      //   return;
      // }
      // final fileName = DateTime.now().toIso8601String().split('.').first;
      final dest = File('$folder/video.mp4');
      print('saved video: ${dest.path}');
      await src.copy(dest.path);

      if (c.mounted) {
        dialog(c, title: '錄影完成', msg: '檔案：${dest.path}');
      }
    } catch (err) {
      if (c.mounted) {
        dialog(c, title: '錄影失敗', msg: '錯誤：$err');
      }
    }
  }

  dialog(BuildContext c, {required String title, required String msg}) {
    showDialog(
      context: c,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(msg),
          actions: [
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

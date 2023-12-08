import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;

///
/// This is an example project to test the performance working with
/// big images. In Safari on mobile phone it has the biggest impact which
/// can be tested easily (how to test this one on browser, more on README.md)
///
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _assetPath = 'assets/large_image_4_mb.jpg';
  final _assetPath2 = 'assets/funny alpaca.jpg';

  final int _sampledPixelSize = 300;
  final int _imageQuality = 90;

  bool _isLoading = false;
  bool _enableSampleDownFast = true;
  bool _showImages = false;
  bool _sampleBigImage = false;

  String? _errorText;

  Uint8List? _bytes;

  Future<void> _readBytes() async {
    // Load the image bytes from the asset
    final ByteData data = await rootBundle.load(
      _sampleBigImage ? _assetPath : _assetPath2,
    );

    // Convert the ByteData to Uint8List
    final Uint8List bytes = data.buffer.asUint8List();
    try {
      late final Uint8List sampledBytes;

      if (_enableSampleDownFast) {
        sampledBytes = await _sampleDownFast(
          bytes: bytes,
          minSizePixel: _sampledPixelSize,
        );
      } else {
        sampledBytes = _sampleDownSlow(
          bytes: bytes,
          maxPixelSize: _sampledPixelSize,
        );
      }

      setState(() {
        _bytes = sampledBytes;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorText = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<Uint8List> _sampleDownFast({
    required Uint8List bytes,
    required int minSizePixel,
  }) async {
    final result = await FlutterImageCompress.compressWithList(
      bytes,
      quality: _imageQuality,
      minWidth: minSizePixel,
      minHeight: minSizePixel,
      keepExif: true,
    );
    return result;
  }

  Uint8List _sampleDownSlow({
    required Uint8List bytes,
    required int maxPixelSize,
  }) {
    final image = img.decodeImage(bytes)!;
    late img.Image sampledImage;

    if (image.width > image.height && image.width > maxPixelSize) {
      sampledImage = img.copyResize(
        image,
        width: maxPixelSize,
      );
    } else if (image.height > maxPixelSize) {
      sampledImage = img.copyResize(
        image,
        height: maxPixelSize,
      );
    } else {
      sampledImage = image;
    }

    return Uint8List.fromList(img.encodeJpg(
      sampledImage,
      quality: _imageQuality,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          actions: [],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Column(
                    children: [
                      const Text('Sample down fast'),
                      Switch(
                        value: _enableSampleDownFast,
                        onChanged: (_) {
                          setState(() {
                            _enableSampleDownFast = !_enableSampleDownFast;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 20.0),
                  Column(
                    children: [
                      const Text('Show images'),
                      Switch(
                        value: _showImages,
                        onChanged: (_) {
                          setState(() {
                            _showImages = !_showImages;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(width: 20.0),
                  Column(
                    children: [
                      const Text('Sample big image'),
                      Switch(
                        value: _sampleBigImage,
                        onChanged: (_) {
                          setState(() {
                            _sampleBigImage = !_sampleBigImage;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _bytes = null;
                      _isLoading = true;
                    });
                    _readBytes();
                  },
                  child: const Text('Sample Image down'),
                ),
              ),
              if (_errorText != null)
                Center(
                  child: Text(_errorText!),
                ),
              if (_isLoading)
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      Text('Loading ... '),
                    ],
                  ),
                ),
              if (_bytes != null)
                ...List.generate(
                  1,
                  (index) => SizedBox.square(
                    dimension: 100.0,
                    child: _showImages
                        ? Image(
                            fit: BoxFit.contain,
                            image: MemoryImage(_bytes!),
                          )
                        : ColoredBox(
                            color: Theme.of(context).primaryColor,
                            child: const Placeholder(),
                          ),
                  ),
                ),
            ],
          ),
        ));
  }
}

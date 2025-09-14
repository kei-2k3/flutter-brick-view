import 'package:flutter/material.dart';
import 'package:flutter_brick_view/flutter_brick_view.dart';

void main() {
  runApp(const MyApp());
}

/// Main App widget
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// Sample image URLs to display
  final List<String> imageUrls = const [
    'https://picsum.photos/seed/picsum/800/600', // 4:3
    'https://picsum.photos/seed/picsum/600/900', // 2:3
    'https://picsum.photos/seed/picsum/1200/600', // 2:1
    'https://picsum.photos/seed/picsum/500/500', // 1:1
    'https://picsum.photos/seed/picsum/900/1200', // 3:4
    'https://picsum.photos/seed/picsum/1600/900', // 16:9
    'https://picsum.photos/seed/picsum/600/900', // 2:3
    'https://picsum.photos/seed/picsum/1200/600', // 2:1
    'https://picsum.photos/seed/picsum/600/900', // 2:3
    'https://picsum.photos/seed/picsum/1200/600', // 2:1
    'https://picsum.photos/seed/picsum/500/500', // 1:1
    'https://picsum.photos/seed/picsum/900/1200', // 3:4
    'https://picsum.photos/seed/picsum/800/600', // 4:3
    'https://picsum.photos/seed/picsum/600/900', // 2:3
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Sample BrickView'),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: BrickView(
              data: images,
              imageProvider: (image) => NetworkImage(image.url),
              maxHeight: 200,
              horizontalGap: 10,
              verticalGap: 10,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              borderRadius: 12,
              loadingWidget: const Center(
                child: CircularProgressIndicator(color: Colors.orangeAccent),
              ),
              errorWidget: Container(
                color: Colors.grey[700],
                child: const Icon(Icons.broken_image, color: Colors.red),
              ),
              onImageTap: (index) {
                debugPrint('Tapped image at index: $index');
              },
              enableShimmerEffect: true,
              imageLoadingDuration: const Duration(milliseconds: 300),
            ),
          ),
        ),
      ),
    );
  }
}

class SampleImage {
  final String id;
  final String url;
  SampleImage(this.id, this.url);
}

final images = [
  SampleImage('1', 'https://picsum.photos/seed/picsum/800/600'),
  SampleImage('2', 'https://picsum.photos/seed/picsum/600/900'),
  SampleImage('3', 'https://picsum.photos/seed/picsum/1200/600'),
  SampleImage('4', 'https://picsum.photos/seed/picsum/500/500'),
  SampleImage('5', 'https://picsum.photos/seed/picsum/900/1200'),
  SampleImage('6', 'https://picsum.photos/seed/picsum/1600/900'),
  SampleImage('7', 'https://picsum.photos/seed/picsum/600/900'),
  SampleImage('8', 'https://picsum.photos/seed/picsum/1200/600'),
  SampleImage('9', 'https://picsum.photos/seed/picsum/500/500'),
  SampleImage('10', 'https://picsum.photos/seed/picsum/900/1200'),
];

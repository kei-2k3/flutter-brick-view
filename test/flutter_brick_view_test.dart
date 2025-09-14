import 'package:flutter/material.dart';
import 'package:flutter_brick_view/flutter_brick_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

class SampleImage {
  final String id;
  final String url;
  SampleImage(this.id, this.url);
}

void main() {
  group('RowItem Tests', () {
    test('should create RowItem with correct properties', () {
      const rowItem = RowItem(index: 5, width: 120.0);
      expect(rowItem.index, 5);
      expect(rowItem.width, 120.0);
    });
  });

  group('BrickView Widget Tests', () {
    late List<SampleImage> mockImages;

    setUp(() {
      mockImages = [
        SampleImage('1', 'https://picsum.photos/seed/picsum/800/600'),
        SampleImage('2', 'https://picsum.photos/seed/picsum/600/900'),
        SampleImage('3', 'https://picsum.photos/seed/picsum/1200/600'),
      ];
    });

    testWidgets('should display empty state when data is empty', (
      tester,
    ) async {
      final widget = BrickView<SampleImage>(
        data: const [],
        imageProvider: (image) => NetworkImage(image.url),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.text('No image to display'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (tester) async {
      final widget = BrickView<SampleImage>(
        data: mockImages,
        imageProvider: (image) => NetworkImage(image.url),
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should use custom loading widget', (tester) async {
      const customLoadingWidget = Text('Loading...');
      final widget = BrickView<SampleImage>(
        data: mockImages,
        imageProvider: (image) => NetworkImage(image.url),
        loadingWidget: customLoadingWidget,
      );

      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.text('Loading...'), findsOneWidget);
    });

    testWidgets('should handle tap callbacks', (tester) async {
      int? tappedIndex;
      final widget = BrickView<SampleImage>(
        data: mockImages,
        imageProvider: (image) => NetworkImage(image.url),
        onImageTap: (index) => tappedIndex = index,
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        expect(tappedIndex, isNotNull);
        expect(tappedIndex, greaterThanOrEqualTo(0));
      });
    });

    testWidgets('should apply custom configurations', (tester) async {
      final widget = BrickView<SampleImage>(
        data: mockImages,
        imageProvider: (image) => NetworkImage(image.url),
        maxHeight: 200,
        horizontalGap: 10,
        verticalGap: 10,
        borderRadius: 12,
        padding: const EdgeInsets.all(16),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        expect(find.byType(BrickView<SampleImage>), findsOneWidget);
        expect(find.byType(ListView), findsOneWidget);
      });
    });

    testWidgets('should handle large datasets', (tester) async {
      final largeDataset = List.generate(
        50,
        (i) => SampleImage(
          '$i',
          'https://picsum.photos/seed/picsum/800/${i * 100}',
        ),
      );

      final widget = BrickView<SampleImage>(
        data: largeDataset,
        imageProvider: (image) => NetworkImage(image.url),
      );

      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(BrickView<SampleImage>), findsOneWidget);
      });
    });
  });
}

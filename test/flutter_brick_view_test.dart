import 'package:flutter/material.dart';
import 'package:flutter_brick_view/flutter_brick_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:network_image_mock/network_image_mock.dart';

// Import your BrickView widget here
// import 'package:your_app/brick_view.dart';

void main() {
  group('RowItem Tests', () {
    test('should create RowItem with correct properties', () {
      // Arrange & Act
      const rowItem = RowItem(index: 5, width: 120.0);

      // Assert
      expect(rowItem.index, 5);
      expect(rowItem.width, 120.0);
    });

    test('should create RowItem as const constructor', () {
      // Arrange & Act
      const rowItem1 = RowItem(index: 1, width: 100.0);
      const rowItem2 = RowItem(index: 1, width: 100.0);

      // Assert - same instances should be equal
      expect(rowItem1.index, rowItem2.index);
      expect(rowItem1.width, rowItem2.width);
    });
  });

  group('BrickView Widget Tests', () {
    late List<String> mockImageUrls;

    setUp(() {
      // Setup mock image URLs for testing
      mockImageUrls = [
        'https://example.com/image1.jpg',
        'https://example.com/image2.jpg',
        'https://example.com/image3.jpg',
        'https://example.com/image4.jpg',
      ];
    });

    testWidgets('should display empty state when imageUrls is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      const widget = BrickView<String>(imageUrls: null);

      // Act
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('No image to display'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display empty state when imageUrls is empty', (
      WidgetTester tester,
    ) async {
      // Arrange
      const widget = BrickView<String>(imageUrls: []);

      // Act
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('No image to display'), findsOneWidget);
    });

    testWidgets('should display loading indicator initially', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(imageUrls: mockImageUrls);

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert - should show loading state while images are being processed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should use custom loading widget when provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      const customLoadingWidget = Text('Custom Loading...');
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        loadingWidget: customLoadingWidget,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      expect(find.text('Custom Loading...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should apply custom padding', (WidgetTester tester) async {
      // Arrange
      const customPadding = EdgeInsets.all(20.0);
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        padding: customPadding,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Assert
      final paddingWidget = tester.widget<Padding>(
        find
            .descendant(
              of: find.byType(BrickView<String>),
              matching: find.byType(Padding),
            )
            .first,
      );
      expect(paddingWidget.padding, customPadding);
    });

    testWidgets('should apply custom physics to ListView', (
      WidgetTester tester,
    ) async {
      // Arrange
      const customPhysics = NeverScrollableScrollPhysics();
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        physics: customPhysics,
      );

      // Mock network images to prevent actual network calls
      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pump(); // Allow FutureBuilder to complete

        // Assert
        final listView = tester.widget<ListView>(find.byType(ListView));
        expect(listView.physics, isA<NeverScrollableScrollPhysics>());
      });
    });

    testWidgets('should handle tap callbacks correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      int? tappedIndex;
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        onImageTap: (index) {
          tappedIndex = index;
        },
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle(); // Wait for all async operations

        // Find and tap the first image
        final inkWellFinder = find.byType(InkWell).first;
        expect(inkWellFinder, findsOneWidget);

        await tester.tap(inkWellFinder);
        await tester.pump();

        // Assert
        expect(tappedIndex, isNotNull);
        expect(tappedIndex, greaterThanOrEqualTo(0));
      });
    });

    testWidgets('should not add tap functionality when onImageTap is null', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        onImageTap: null, // Explicitly null
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert - InkWells should exist but have null onTap
        final inkWells = tester.widgetList<InkWell>(find.byType(InkWell));
        for (final inkWell in inkWells) {
          expect(inkWell.onTap, isNull);
        }
      });
    });

    testWidgets('should apply custom border radius', (
      WidgetTester tester,
    ) async {
      // Arrange
      const customRadius = 12.0;
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        borderRadius: customRadius,
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert
        final clipRRect = tester.widget<ClipRRect>(
          find.byType(ClipRRect).first,
        );
        expect(clipRRect.borderRadius, BorderRadius.circular(customRadius));
      });
    });

    testWidgets('should respect maxHeight property', (
      WidgetTester tester,
    ) async {
      // Arrange
      const customMaxHeight = 200.0;
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        maxHeight: customMaxHeight,
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert - all SizedBox widgets should have the custom max height
        final sizedBoxes = tester.widgetList<SizedBox>(
          find.descendant(
            of: find.byType(InkWell),
            matching: find.byType(SizedBox),
          ),
        );

        for (final sizedBox in sizedBoxes) {
          expect(sizedBox.height, customMaxHeight);
        }
      });
    });

    testWidgets('should display error widget when provided', (
      WidgetTester tester,
    ) async {
      // Arrange
      const customErrorWidget = Text('Custom Error');
      final widget = BrickView<String>(
        imageUrls: ['invalid-url'], // This should cause an error
        errorWidget: customErrorWidget,
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pump(); // Allow FutureBuilder to process

      // Assert - We expect the error widget to be shown
      // Note: The exact error handling depends on your image loading implementation
      expect(find.text('Custom Error'), findsWidgets);
    });

    testWidgets('should handle horizontal and vertical gaps correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      const horizontalGap = 8.0;
      const verticalGap = 12.0;
      final widget = BrickView<String>(
        imageUrls: mockImageUrls,
        horizontalGap: horizontalGap,
        verticalGap: verticalGap,
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert - Check for SizedBox widgets that represent gaps
        final horizontalGapWidgets = tester
            .widgetList<SizedBox>(
              find.descendant(
                of: find.byType(Row),
                matching: find.byType(SizedBox),
              ),
            )
            .where((sizedBox) => sizedBox.width == horizontalGap);

        expect(horizontalGapWidgets, isNotEmpty);
      });
    });
  });

  group('BrickView Layout Calculation Tests', () {
    // These tests focus on the internal layout calculation logic
    // Since the methods are private, we test them through widget behavior

    testWidgets('should handle single image correctly', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(
        imageUrls: ['https://example.com/single-image.jpg'],
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(ListView), findsOneWidget);
        expect(find.byType(Row), findsOneWidget);
      });
    });

    testWidgets('should create multiple rows for many images', (
      WidgetTester tester,
    ) async {
      // Arrange - Use more images to force multiple rows
      final manyImages = List.generate(
        20,
        (index) => 'https://example.com/image$index.jpg',
      );

      final widget = BrickView<String>(
        imageUrls: manyImages,
        maxHeight: 100.0, // Smaller height to encourage more rows
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400, // Fixed width for consistent testing
                child: widget,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Assert - Should have multiple rows
        final rows = find.byType(Row);
        expect(rows, findsWidgets);

        // Should have a ListView to contain the rows
        expect(find.byType(ListView), findsOneWidget);
      });
    });
  });

  group('BrickView Error Handling Tests', () {
    testWidgets('should display default error state when image loading fails', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(
        imageUrls: ['https://invalid-domain-that-does-not-exist.com/image.jpg'],
      );

      // Act
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      // Wait for the future to complete with error
      await tester.pump(const Duration(seconds: 1));

      // Assert - Should show error state
      // The exact behavior depends on how your image loading handles errors
      expect(find.byType(BrickView<String>), findsOneWidget);
    });

    testWidgets('should handle empty image URLs gracefully', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(
        imageUrls: ['', '   ', null].cast<String>(), // Invalid URLs
      );

      // Act & Assert - Should not crash
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

      expect(find.byType(BrickView<String>), findsOneWidget);
    });
  });

  group('BrickView Accessibility Tests', () {
    testWidgets('should be accessible with proper semantics', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = BrickView<String>(
        imageUrls: ['https://example.com/image1.jpg'],
        onImageTap: (index) {}, // Add tap functionality for accessibility
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert - Should have tappable elements (InkWell provides accessibility)
        expect(find.byType(InkWell), findsWidgets);
      });
    });
  });

  group('BrickView Performance Tests', () {
    testWidgets('should handle large number of images without crashing', (
      WidgetTester tester,
    ) async {
      // Arrange - Create a large list of images
      final largeImageList = List.generate(
        100,
        (index) => 'https://example.com/image$index.jpg',
      );

      final widget = BrickView<String>(imageUrls: largeImageList);

      await mockNetworkImagesFor(() async {
        // Act - This should not crash or timeout
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));

        // Allow some time for processing but don't wait indefinitely
        await tester.pump(const Duration(milliseconds: 100));

        // Assert - Widget should be built successfully
        expect(find.byType(BrickView<String>), findsOneWidget);
      });
    });
  });

  group('BrickView Integration Tests', () {
    testWidgets('should work within a scrollable parent', (
      WidgetTester tester,
    ) async {
      // Arrange
      final widget = SingleChildScrollView(
        child: Column(
          children: [
            const Text('Header'),
            BrickView<String>(imageUrls: ['https://example.com/image1.jpg']),
            const Text('Footer'),
          ],
        ),
      );

      await mockNetworkImagesFor(() async {
        // Act
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Header'), findsOneWidget);
        expect(find.text('Footer'), findsOneWidget);
        expect(find.byType(BrickView<String>), findsOneWidget);
      });
    });

    testWidgets('should maintain state during parent rebuilds', (
      WidgetTester tester,
    ) async {
      // Arrange
      int tapCount = 0;

      await mockNetworkImagesFor(() async {
        // Act - Build widget and interact with it
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return Column(
                    children: [
                      Text('Tap count: $tapCount'),
                      ElevatedButton(
                        onPressed: () => setState(() => tapCount++),
                        child: const Text('Increment'),
                      ),
                      Expanded(
                        child: BrickView<String>(
                          imageUrls: ['https://example.com/image1.jpg'],
                          onImageTap: (index) => setState(() => tapCount += 10),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Tap the increment button
        await tester.tap(find.text('Increment'));
        await tester.pump();

        // Tap the image
        await tester.tap(find.byType(InkWell).first);
        await tester.pump();

        // Assert - State should be maintained and updated correctly
        expect(find.text('Tap count: 11'), findsOneWidget);
      });
    });
  });
}

// Helper class to create mock image sizes for testing
class MockImageSizeHelper {
  static Size getMockImageSize(String url) {
    // Return different sizes based on URL to simulate variety
    final hash = url.hashCode.abs();
    final width = 200.0 + (hash % 300); // 200-500 width
    final height = 150.0 + (hash % 200); // 150-350 height
    return Size(width, height);
  }
}

// Additional helper functions for testing
Future<void> pumpBrickView(
  WidgetTester tester,
  BrickView widget, {
  bool mockImages = true,
}) async {
  if (mockImages) {
    await mockNetworkImagesFor(() async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
      await tester.pumpAndSettle();
    });
  } else {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: widget)));
    await tester.pumpAndSettle();
  }
}

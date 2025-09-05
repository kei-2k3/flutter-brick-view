import 'package:examples/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_brick_view/flutter_brick_view.dart';

void main() {
  testWidgets('BrickView displays images and responds to taps', (
    WidgetTester tester,
  ) async {
    // Build the app
    await tester.pumpWidget(const MyApp());

    // Allow images to load (simulate a short delay)
    await tester.pump(const Duration(seconds: 1));

    // Check if BrickView exists
    expect(find.byType(BrickView), findsOneWidget);

    // Check if CircularProgressIndicator exists initially
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Find all Image widgets inside BrickView
    final imageFinder = find.byType(Image);
    expect(imageFinder, findsWidgets);

    // Tap the first image and verify debug print
    // Note: debugPrint output is not captured by default in tests
    await tester.tap(imageFinder.first);
    await tester.pump();
  });

  testWidgets('Error widget is shown when image fails to load', (
    WidgetTester tester,
  ) async {
    // Create a MyApp with invalid URLs
    final invalidUrls = ['https://invalid-url.com/image.png'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BrickView(
            imageUrls: invalidUrls,
            maxHeight: 100,
            horizontalGap: 4,
            verticalGap: 4,
            loadingWidget: const CircularProgressIndicator(),
            errorWidget: Container(
              color: Colors.grey[700],
              child: const Icon(Icons.broken_image, color: Colors.red),
            ),
          ),
        ),
      ),
    );

    // Simulate delay for image loading
    await tester.pumpAndSettle();

    // Check if error widget is displayed
    expect(find.byIcon(Icons.broken_image), findsOneWidget);
  });
}

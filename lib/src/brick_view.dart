import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_brick_view/src/widget/enhanced_image.dart';

/// Class representing a single item in a row of images.
/// Contains the index of the image and its calculated width in the row.
class RowItem {
  final int index;
  final double width;

  const RowItem({required this.index, required this.width});
}

/// A responsive brick-style image grid widget.
/// Displays images in layout similar to Google Images
/// Supports custom gaps, padding, max height, and tap callbacks
class BrickView<T> extends StatelessWidget {
  BrickView({
    super.key,
    required this.data,
    required this.imageProvider,
    this.horizontalGap = 4.0,
    this.verticalGap = 4.0,
    this.padding = const EdgeInsets.all(10.0),
    this.maxHeight = 150.0,
    this.onImageTap,
    this.borderRadius = 6.0,
    this.loadingWidget,
    this.errorWidget,
    this.physics,
    this.imageLoadingDuration = const Duration(milliseconds: 300),
    this.enableShimmerEffect = true,
  }) : assert(data.isNotEmpty, 'Data list cannot be empty');

  /// List of image data objects.
  final List<T> data;

  /// Function that extracts an ImageProvider from image.
  final ImageProvider Function(T image) imageProvider;

  /// Horizontal space between images in a same row.
  final double horizontalGap;

  /// Vertical space between rows of images.
  final double verticalGap;

  /// Outer padding for  the whole grid.
  final EdgeInsets padding;

  /// Maximum height for each iamge
  final double maxHeight;

  /// Callback when an image is tapped.
  final void Function(int index)? onImageTap;

  /// Corner radius for each image.
  final double borderRadius;

  /// Widget displayed while an image is loading.
  final Widget? loadingWidget;

  /// Widget displayed if an image fails to load.
  final Widget? errorWidget;

  /// Scroll physics for the outer ListView
  final ScrollPhysics? physics;

  /// Duration for fade-in animation when image loads
  final Duration imageLoadingDuration;

  /// Whether to show shimmer effect during loading
  final bool enableShimmerEffect;

  @override
  Widget build(BuildContext context) {
    return _buildImageBrickView();
  }

  /// Main builder for the brick-style image grid.
  Widget _buildImageBrickView() {
    if (data.isEmpty) {
      // Show empty state if no images are provided
      return _buildEmptyState('No image to display');
    }

    // Load image sizes asynchronously
    return FutureBuilder(
      future: _loadAllImageSizes(data),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }

        if (snapshot.hasError) {
          return _buildErrorState('Failed to load images: ${snapshot.error}');
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState('No image data available.');
        }

        final sizes = snapshot.data!;
        return _buildBrickLayout(
          itemCount: data.length,
          sizes: sizes,
          itemBuilder: (context, index, width) =>
              _buildImageItem(data[index], index, width),
        );
      },
    );
  }

  /// Builds the ListView of image rows.
  Widget _buildBrickLayout({
    required int itemCount,
    required List<Size>? sizes,

    required Widget Function(BuildContext, int, double) itemBuilder,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - (2 * padding.left);
        final rows = _calculateImageRows(sizes!, availableWidth);

        return Padding(
          padding: padding,
          child: ListView.builder(
            physics: physics,
            itemCount: rows.length,
            itemBuilder: (context, rowIndex) {
              final row = rows[rowIndex];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex == rows.length - 1 ? 0 : verticalGap,
                ),
                child: _buildRow(row, itemBuilder, context),
              );
            },
          ),
        );
      },
    );
  }

  /// Builds a single row of images.
  Widget _buildRow(
    List<RowItem> row,
    Widget Function(BuildContext, int, double) itemBuilder,
    BuildContext context,
  ) {
    return Row(
      children: [
        for (int i = 0; i < row.length; i++) ...[
          itemBuilder(context, row[i].index, row[i].width),
          if (i < row.length - 1) SizedBox(width: horizontalGap),
        ],
      ],
    );
  }

  /// Builds a single image widget with tap, loading, and error handling.
  Widget _buildImageItem(T image, int index, double width) {
    final provider = imageProvider(image);
    return InkWell(
      onTap: onImageTap != null ? () => onImageTap!(index) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: maxHeight,
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: EnhancedImage(
            imageProvider: provider,
            loadingWidget: loadingWidget,
            errorWidget: errorWidget,
            borderRadius: borderRadius,
            imageLoadingDuration: imageLoadingDuration,
            enableShimmerEffect: enableShimmerEffect,
          ),
        ),
      ),
    );
  }

  /// Widget displayed when there are no images.
  Widget _buildEmptyState(String message) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: Colors.grey),
        textAlign: TextAlign.center,
      ),
    );
  }

  /// Widget displayed while images are loading.
  Widget _buildLoadingState() {
    return Center(child: loadingWidget ?? const CircularProgressIndicator());
  }

  /// Widget displayed if loading images fails.
  Widget _buildErrorState(String message) {
    return Center(
      child:
          errorWidget ??
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
    );
  }

  /// Loads the sizes of all images asynchronously.
  Future<List<Size>> _loadAllImageSizes(List<T> images) async {
    try {
      final futures = images.map((image) => _loadImageSize(image));
      return Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to load iamge sizes: $e');
    }
  }

  /// Loads the size of a single image.
  Future<Size> _loadImageSize(T image) async {
    final provider = imageProvider(image);
    final completer = Completer<Size>();
    ImageStreamListener? listener;

    try {
      final imageStream = provider.resolve(const ImageConfiguration());

      listener = ImageStreamListener(
        (ImageInfo info, bool synchronousCall) {
          // Check if completer is already completed before completing
          if (!completer.isCompleted) {
            completer.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
          }
        },
        onError: (exception, stackTrace) {
          // Check if completer is already completed before completing with error
          if (!completer.isCompleted) {
            completer.completeError(exception, stackTrace);
          }
        },
      );

      imageStream.addListener(listener);

      // Set up a timeout to prevent hanging indefinitely
      final result = await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException(
            'Image loading timed out',
            const Duration(seconds: 10),
          );
        },
      );

      return result;
    } catch (e) {
      if (!completer.isCompleted) {
        completer.completeError(e);
      }
      rethrow;
    } finally {
      // Clean up listener if it was created
      if (listener != null) {
        try {
          final stream = provider.resolve(const ImageConfiguration());
          stream.removeListener(listener);
        } catch (e) {
          // Ignore cleanup errors
        }
      }
    }
  }

  /// Calculates how to group images into rows based on their aspect ratios.
  List<List<RowItem>> _calculateImageRows(List<Size> sizes, double maxWidth) {
    if (sizes.isEmpty) return [];

    List<List<RowItem>> rows = [];
    List<RowItem> currentRow = [];
    double rowAspectSum = 0.0;

    for (int i = 0; i < sizes.length; i++) {
      final aspectRatio = sizes[i].width / sizes[i].height;
      rowAspectSum += aspectRatio;
      currentRow.add(RowItem(index: i, width: aspectRatio));

      final gapWidth = (currentRow.length - 1) * horizontalGap;
      final availableForItems = maxWidth - gapWidth;

      // Check if row is full based on max height and available width
      if (rowAspectSum >= availableForItems / maxHeight) {
        final scale = availableForItems / (rowAspectSum * maxHeight);
        rows.add([
          for (final img in currentRow)
            RowItem(index: img.index, width: img.width * maxHeight * scale),
        ]);
        currentRow = [];
        rowAspectSum = 0;
      }
    }

    // Add leftover images as the last row
    if (currentRow.isNotEmpty) {
      rows.add([
        for (final img in currentRow)
          RowItem(index: img.index, width: img.width * maxHeight),
      ]);
    }

    return rows;
  }
}

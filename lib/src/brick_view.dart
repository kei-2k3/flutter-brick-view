import 'dart:async';

import 'package:flutter/material.dart';

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
  const BrickView({
    super.key,
    required this.imageUrls,
    this.horizontalGap = 4.0,
    this.verticalGap = 4.0,
    this.padding = const EdgeInsets.all(10.0),
    this.maxHeight = 150.0,
    this.onImageTap,
    this.borderRadius = 6.0,
    this.loadingWidget,
    this.errorWidget,
    this.physics,
  });

  /// List of image urls to display.
  final List<String>? imageUrls;

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

  @override
  Widget build(BuildContext context) {
    return _buildImageBrickView();
  }

  /// Main builder for the brick-style image grid.
  Widget _buildImageBrickView() {
    if (imageUrls == null || imageUrls!.isEmpty) {
      // Show empty state if no images are provided
      return _buildEmptyState('No image to display');
    }

    // Load image sizes asynchronously
    return FutureBuilder(
      future: _loadAllImageSizes(imageUrls!),
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
          itemCount: imageUrls!.length,
          sizes: sizes,
          itemBuilder: (context, index, width) =>
              _buildImageItem(imageUrls![index], index, width),
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
          _buildImageItem(imageUrls![row[i].index], row[i].index, row[i].width),
          if (i < row.length - 1) SizedBox(width: horizontalGap),
        ],
      ],
    );
  }

  /// Builds a single image widget with tap, loading, and error handling.
  Widget _buildImageItem(String imageUrl, int index, double width) {
    return InkWell(
      onTap: onImageTap != null ? () => onImageTap!(index) : null,
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: maxHeight,
        width: width,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return loadingWidget ??
                  const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (context, error, stackTrace) {
              return errorWidget ??
                  Container(
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
            },
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
  Future<List<Size>> _loadAllImageSizes(List<String> urls) async {
    try {
      final futures = urls.map((url) => _loadImageSize(url));
      return Future.wait(futures);
    } catch (e) {
      throw Exception('Failed to load iamge sizes: $e');
    }
  }

  /// Loads the size of a single image.
  Future<Size> _loadImageSize(String url) {
    final completer = Completer<Size>();
    final image = Image.network(url);
    image.image
        .resolve(const ImageConfiguration())
        .addListener(
          ImageStreamListener((info, _) {
            completer.complete(
              Size(info.image.width.toDouble(), info.image.height.toDouble()),
            );
          }),
        );
    return completer.future;
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

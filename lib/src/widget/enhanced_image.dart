import 'package:flutter/material.dart';

/// Enhanced image widget that handles individual loading states with animations
class EnhancedImage extends StatefulWidget {
  const EnhancedImage({
    required this.imageProvider,
    this.loadingWidget,
    this.errorWidget,
    required this.borderRadius,
    required this.imageLoadingDuration,
    required this.enableShimmerEffect,
  });

  final ImageProvider imageProvider;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final double borderRadius;
  final Duration imageLoadingDuration;
  final bool enableShimmerEffect;

  @override
  State<EnhancedImage> createState() => EnhancedImageState();
}

class EnhancedImageState extends State<EnhancedImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  ImageStream? _imageStream;
  ImageStreamListener? _imageStreamListener;

  // ignore: unused_field
  ImageInfo? _imageInfo;
  bool _isLoading = true;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.imageLoadingDuration,
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _loadImage();
  }

  @override
  void didUpdateWidget(EnhancedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageProvider != widget.imageProvider) {
      _loadImage();
    }
  }

  void _loadImage() {
    _cleanupImageStream();

    setState(() {
      _isLoading = true;
      _error = null;
      _imageInfo = null;
    });

    _animationController.reset();

    _imageStream = widget.imageProvider.resolve(const ImageConfiguration());
    _imageStreamListener = ImageStreamListener(
      _onImageLoaded,
      onError: _onImageError,
    );
    _imageStream!.addListener(_imageStreamListener!);
  }

  void _onImageLoaded(ImageInfo info, bool synchronousCall) {
    if (!mounted) return;

    setState(() {
      _imageInfo = info;
      _isLoading = false;
    });

    _animationController.forward();
  }

  void _onImageError(Object error, StackTrace? stackTrace) {
    if (!mounted) return;

    setState(() {
      _error = error;
      _isLoading = false;
    });
  }

  void _cleanupImageStream() {
    if (_imageStreamListener != null && _imageStream != null) {
      _imageStream!.removeListener(_imageStreamListener!);
    }
    _imageStreamListener = null;
    _imageStream = null;
  }

  @override
  void dispose() {
    _cleanupImageStream();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget();
    }

    if (_isLoading) {
      return _buildLoadingWidget();
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Image(
        image: widget.imageProvider,
        fit: BoxFit.cover,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          // Handle cases where the image loads synchronously
          if (wasSynchronouslyLoaded) {
            return child;
          }

          // For asynchronous loading, use the fade animation
          return frame != null ? child : _buildLoadingWidget();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    if (widget.loadingWidget != null) {
      return widget.loadingWidget!;
    }

    if (widget.enableShimmerEffect) {
      return _ShimmerPlaceholder(borderRadius: widget.borderRadius);
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return widget.errorWidget ??
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(widget.borderRadius),
          ),
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 32),
          ),
        );
  }
}

/// Shimmer effect placeholder for loading state
class _ShimmerPlaceholder extends StatefulWidget {
  const _ShimmerPlaceholder({required this.borderRadius});

  final double borderRadius;

  @override
  State<_ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<_ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _shimmerController.repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _shimmerAnimation.value - 0.3,
                _shimmerAnimation.value,
                _shimmerAnimation.value + 0.3,
              ].map((stop) => stop.clamp(0.0, 1.0)).toList(),
              colors: const [
                Color(0xFFE0E0E0),
                Color(0xFFEEEEEE),
                Color(0xFFE0E0E0),
              ],
            ),
          ),
        );
      },
    );
  }
}

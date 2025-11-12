import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';

class InteractiveCardImage extends StatelessWidget {
  final String? imageUrl;
  final double? height;
  final BoxFit? fit;

  const InteractiveCardImage({
    super.key,
    required this.imageUrl,
    this.height,
    this.fit,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(context);
    }

    return Container(
      height: height,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
        child: PhotoView(
          imageProvider: CachedNetworkImageProvider(imageUrl!),
          initialScale: PhotoViewComputedScale.contained,
          minScale: PhotoViewComputedScale.contained * 0.8,
          maxScale: PhotoViewComputedScale.covered * 3.0,
          enableRotation: false,
          backgroundDecoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
          loadingBuilder: (context, event) => _buildLoading(context),
          errorBuilder: (context, error, stackTrace) => _buildError(context),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      height: height ?? 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'No Image Available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return Container(
      height: height ?? 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Container(
      height: height ?? 300,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 64,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to Load Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class FullScreenImageViewer extends StatelessWidget {
  final List<String> imageUrls;
  final int initialIndex;
  final String? heroTag;

  const FullScreenImageViewer({
    super.key,
    required this.imageUrls,
    this.initialIndex = 0,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: PhotoViewGallery.builder(
        scrollPhysics: const BouncingScrollPhysics(),
        pageController: PageController(initialPage: initialIndex),
        itemCount: imageUrls.length,
        builder: (context, index) {
          return PhotoViewGalleryPageOptions(
            imageProvider: CachedNetworkImageProvider(imageUrls[index]),
            initialScale: PhotoViewComputedScale.contained,
            minScale: PhotoViewComputedScale.contained * 0.8,
            maxScale: PhotoViewComputedScale.covered * 4.0,
            heroAttributes: heroTag != null ? PhotoViewHeroAttributes(tag: '$heroTag-$index') : null,
          );
        },
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        onPageChanged: (index) {
        },
      ),
    );
  }
}

class CardImageWithTapToZoom extends StatefulWidget {
  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final String? heroTag;

  const CardImageWithTapToZoom({
    super.key,
    required this.imageUrl,
    this.height,
    this.width,
    this.fit,
    this.borderRadius,
    this.heroTag,
  });

  @override
  State<CardImageWithTapToZoom> createState() => _CardImageWithTapToZoomState();
}

class _CardImageWithTapToZoomState extends State<CardImageWithTapToZoom> {
  bool _isImageLoaded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      return _buildPlaceholder();
    }

    Widget imageWidget = Hero(
      tag: widget.heroTag ?? 'card-image-${widget.imageUrl}',
      child: CachedNetworkImage(
        imageUrl: widget.imageUrl!,
        height: widget.height,
        width: widget.width,
        fit: widget.fit ?? BoxFit.cover,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        fadeInDuration: const Duration(milliseconds: 300),
        imageBuilder: (context, imageProvider) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              setState(() {
                _isImageLoaded = true;
              });
            }
          });
          return Container(
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              image: DecorationImage(
                image: imageProvider,
                fit: widget.fit ?? BoxFit.cover,
              ),
            ),
          );
        },
      ),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: widget.borderRadius,
        onTap: _isImageLoaded ? () => _openFullScreenImage() : null,
        child: Stack(
          children: [
            imageWidget,
            if (_isImageLoaded)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'No Image',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      height: widget.height,
      width: widget.width,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: widget.borderRadius,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image,
            size: 48,
            color: Colors.grey[600],
          ),
          const SizedBox(height: 8),
          Text(
            'Failed to Load',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _openFullScreenImage() {
    if (widget.imageUrl != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              FullScreenImageViewer(
            imageUrls: [widget.imageUrl!],
            heroTag: widget.heroTag ?? 'card-image-${widget.imageUrl}',
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
    }
  }
}
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:news/utils/ui_utils.dart';

/// Network image with on-disk caching.
///
/// Backed by [CachedNetworkImage] so a URL is downloaded once and re-read from
/// disk on every later build (the old [FadeInImage.assetNetwork] only kept a
/// memory cache, so images re-downloaded after every app restart). SVG URLs
/// still go through [SvgPicture.network], which cannot share that cache.
class CustomNetworkImage extends StatelessWidget {
  final String networkImageUrl;
  final double? width, height;
  final BoxFit? fit;
  final bool? isVideo;

  /// Shown instead of the placeholder asset when the image fails to load.
  final Widget? errorBuilder;

  /// Replaces the placeholder asset shown while the image downloads (and, by
  /// extension, the fallback for [errorBuilder]). Pass an empty box where the
  /// caller already paints something behind the image and a logo flashing over
  /// it would read as content of its own.
  final Widget? placeholderBuilder;

  /// Tints the image (used for monochrome icons that follow the theme).
  final Color? color;
  final FilterQuality filterQuality;

  const CustomNetworkImage(
      {super.key,
      required this.networkImageUrl,
      this.width,
      this.height,
      this.fit,
      this.isVideo,
      this.errorBuilder,
      this.placeholderBuilder,
      this.color,
      this.filterQuality = FilterQuality.low});

  double get _width => width ?? 100;

  double get _height => height ?? 100;

  BoxFit get _fit => fit ?? BoxFit.cover;

  Widget _placeholder() =>
      placeholderBuilder ??
      Image.asset(UiUtils.getPlaceholderPngPath(),
          width: _width, height: _height, fit: _fit);

  Widget _error() => errorBuilder ?? _placeholder();

  @override
  Widget build(BuildContext context) {
    return (networkImageUrl.contains("svg"))
        ? SvgPicture.network(networkImageUrl,
            width: _width,
            height: _height,
            fit: _fit,
            colorFilter: color == null
                ? null
                : ColorFilter.mode(color!, BlendMode.srcIn),
            placeholderBuilder: (context) => _placeholder())
        : CachedNetworkImage(
            imageUrl: networkImageUrl,
            width: _width,
            height: _height,
            fit: _fit,
            color: color,
            filterQuality: filterQuality,
            fadeInDuration: const Duration(milliseconds: 150),
            placeholder: (context, url) => _placeholder(),
            errorWidget: (context, url, error) => _error());
  }
}

import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';


import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:field_crm/common/widgets/loading.dart';

class CustomImage {
  // static Future<Uint8List?> readAsByte(final String url) async {
  //   try {
  //     final NupiClient client = NupiClient.instance;
  //     var response = await client.request(
  //       requestType: RequestType.getImage,
  //       url: url,
  //     );
  //     return response.data;
  //   } catch (ex) {
  //     return null;
  //   }
  // }

  static int? _memCacheDimension(double? logicalSize, BuildContext? context) {
    if (logicalSize == null || logicalSize.isInfinite || logicalSize <= 0) {
      return null;
    }
    final ratio = context != null
        ? MediaQuery.devicePixelRatioOf(context)
        : 2.0;
    return (logicalSize * ratio).round();
  }

  static CachedNetworkImage network(
    String assetName, {
    double? width,
    double? height,
    BuildContext? context,
    Color? color,
    BoxFit fit = BoxFit.contain,
    Alignment alignment = Alignment.center,
    Clip clipBehavior = Clip.hardEdge,
    Widget Function(BuildContext, ImageProvider<Object>)? imageBuilder,
    Widget Function(BuildContext, String, Object)? errorBuilder,
    Widget Function(BuildContext, String)? placeholder,
    Duration fadeInDuration = const Duration(milliseconds: 500),
    Duration fadeOutDuration = const Duration(milliseconds: 1000),
    Duration? placeholderFadeInDuration,
    FilterQuality filterQuality = FilterQuality.low,
  }) {
    return CachedNetworkImage(
      // httpHeaders: {
      //   "Authorization": "Basic ${ApiClient.instance.dioToken}",
      // },
      imageBuilder: imageBuilder,
      errorListener: (value) => log('$value', name: 'Cached Network Image:'),
      placeholder: placeholder,
      filterQuality: filterQuality,
      fadeInDuration: fadeInDuration,
      alignment: alignment,
      fadeOutDuration: fadeOutDuration,
      placeholderFadeInDuration: placeholderFadeInDuration,
      progressIndicatorBuilder: placeholder != null
          ? null
          : (context, url, progress) {
              return SizedBox(
                height: height,
                width: width,
                child: Container(
                  height: height,
                  width: width,
                  decoration: BoxDecoration(color: color),
                  child: const Center(
                    child: CustomLoadingIndicator(),
                  ),
                ),
              );
            },
      errorWidget: errorBuilder,
      imageUrl: assetName,
      height: height,
      width: width,
      memCacheWidth: _memCacheDimension(width, context),
      memCacheHeight: _memCacheDimension(height, context),
      color: color,
      fit: fit,
    );
  }

  static Image memory(Uint8List bytes,
      {double? width,
      double? height,
      Color? color,
      BoxFit fit = BoxFit.contain,
      Clip clipBehavior = Clip.hardEdge,
      AlignmentGeometry alignment = Alignment.center,
      Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}) {
    return Image.memory(bytes,
        height: height,
        width: width,
        color: color,
        fit: fit,
        alignment: alignment,
        errorBuilder: errorBuilder,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) {
        return child;
      }
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        child: frame == null
            ? const Center(child: CustomLoadingIndicator())
            : child,
      );
    });
  }

  static Image asset(String assetName,
      {double? width,
      double? height,
      Color? color,
      BoxFit fit = BoxFit.contain,
      Clip clipBehavior = Clip.hardEdge,
      AlignmentGeometry alignment = Alignment.center,
      Widget Function(BuildContext, Object, StackTrace?)? errorBuilder}) {
    assert(
        (assetName.contains('png') ||
            assetName.contains('jpg') ||
            assetName.contains('jpeg') ||
            assetName.contains('gif') ||
            assetName.contains('webp')),
        'Image extension not found');
    return Image.asset(assetName,
        height: height,
        width: width,
        cacheWidth: width != null ? (width * 2.0).round() : null,
        cacheHeight: height != null ? (height * 2.0).round() : null,
        alignment: alignment,
        color: color,
        fit: fit,
        errorBuilder: errorBuilder,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) {
        return child;
      }
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        child: frame == null
            ? const Center(child: CustomLoadingIndicator())
            : child,
      );
    });
  }

  static Image file(String assetName,
      {double? width,
      double? height,
      Widget Function(BuildContext, Object, StackTrace?)? errorBuilder,
      Color? color,
      BoxFit fit = BoxFit.contain,
      AlignmentGeometry alignment = Alignment.center,
      Clip clipBehavior = Clip.hardEdge,
      Widget Function(BuildContext, ImageProvider<Object>)? imageBuilder}) {
    if (assetName.isNotEmpty) {
      assert(
          (assetName.contains('png') ||
              assetName.contains('jpg') ||
              assetName.contains('jpeg') ||
              assetName.contains('gif') ||
              assetName.contains('webp')),
          'Image extension not found');
    }
    return Image.file(File(assetName),
        height: height,
        width: width,
        color: color,
        fit: fit,
        alignment: alignment,
        errorBuilder: errorBuilder,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
      if (wasSynchronouslyLoaded) {
        return imageBuilder?.call(context, FileImage(File(assetName))) ?? child;
      }
      return AnimatedOpacity(
        opacity: frame == null ? 0 : 1,
        duration: const Duration(milliseconds: 60),
        curve: Curves.easeOut,
        child: frame == null
            ? const Center(child: CustomLoadingIndicator())
            : imageBuilder?.call(context, FileImage(File(assetName))) ?? child,
      );
    });
  }

  static SvgPicture svg(
    String assetName, {
    double? width,
    double? height,
    Color? color,
    AlignmentGeometry alignment = Alignment.center,
    BoxFit fit = BoxFit.contain,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    assert((assetName.contains('svg')), 'Svg extension not found');
    return SvgPicture.asset(
      assetName,
      height: height,
      width: width,
      alignment: alignment,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      clipBehavior: clipBehavior,
      fit: fit,
    );
  }

  static SvgPicture networkSvgImage(
    String assetName, {
    double? width,
    double? height,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BoxFit fit = BoxFit.contain,
    Clip clipBehavior = Clip.hardEdge,
  }) {
    assert((assetName.contains('svg')), 'Svg extension not found');
    return SvgPicture.network(
      assetName,
      placeholderBuilder: (context) => const Center(
          child: CustomLoadingIndicator(
        scale: .4,
      )),
      height: height,
      alignment: alignment,
      width: width,
      colorFilter:
          color != null ? ColorFilter.mode(color, BlendMode.srcIn) : null,
      clipBehavior: clipBehavior,
      fit: fit,
    );
  }
}

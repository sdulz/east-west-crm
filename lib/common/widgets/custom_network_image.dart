import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/image_constant.dart';
import 'package:field_crm/common/widgets/custom_image.dart';
import 'package:shimmer/shimmer.dart';

class CustomNetworkImage extends ConsumerStatefulWidget {
  final String? url;
  final BorderRadius? borderRadius;
  const CustomNetworkImage(
    this.url, {
    super.key,
    this.width,
    this.fit = BoxFit.contain,
    this.showError = true,
    this.height,
    this.borderRadius,
    this.onErrorEmpty,
    this.heroTag,
  });
  final double? width;
  final double? height;
  final BoxFit fit;
  final bool showError;
  final Widget? onErrorEmpty;
  final Object? heroTag;
  @override
  ConsumerState<CustomNetworkImage> createState() => _CustomNetworkImageState();
}

class _CustomNetworkImageState extends ConsumerState<CustomNetworkImage> {
  late final ValueNotifier<Object?> _heroController = ValueNotifier(
    widget.heroTag,
  );
  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final url = widget.url;
    return _MayAddHero(
      heroController: _heroController,
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? BorderRadius.circular(0),
        child: Builder(
          builder: (context) {
            if (url == null || url.isEmpty == true) {
              return _mayUseOnErrorEmpty(ImageConstants.noInternetSVG);
            }
            return CustomImage.network(
              url,
              context: context,
              placeholder:
                  (context, string) => Shimmer.fromColors(
                    baseColor: ColorConstant.shimmerBaseColor,
                    highlightColor: ColorConstant.shimmerHighlightColor,
                    child: Container(
                      height: widget.height,
                      width: widget.width,
                      decoration: BoxDecoration(
                        borderRadius: widget.borderRadius,
                        color: ColorConstant.black,
                      ),
                    ),
                  ),
              errorBuilder:
                  widget.showError
                      ? (_, __, ___) {
                        Future.delayed(Duration.zero, () {
                          _heroController.value = null;
                        });
                        return _mayUseOnErrorEmpty(
                          ImageConstants.noInternetSVG,
                        ); //Todo: Refactor
                      }
                      : (_, __, ___) => const SizedBox(),
              fit: widget.fit,
              width: widget.width,
              height: widget.height,
            );
          },
        ),
      ),
    );
  }

  Widget _mayUseOnErrorEmpty(String image) {
    return widget.onErrorEmpty != null
        ? widget.onErrorEmpty ?? const SizedBox()
        : Container(
          color: ColorConstant.borderColor.withCustomOpacity(.2),
          child: CustomImage.svg(
            image,
            fit: BoxFit.contain,
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
          ),
        );
  }
}

class _MayAddHero extends StatelessWidget {
  final ValueNotifier<Object?> heroController;
  final Widget child;

  const _MayAddHero({required this.heroController, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: heroController,
      builder: (context, heroTag, _) {
        if (heroTag != null) {
          return Hero(tag: heroTag, child: child);
        } else {
          return child;
        }
      },
    );
  }
}

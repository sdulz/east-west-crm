
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/widgets/degree_to_radian.dart';



class NoResultWidget extends StatefulWidget {
  const NoResultWidget({super.key});

  @override
  State<NoResultWidget> createState() => _NoResultWidgetState();
}

class _NoResultWidgetState extends State<NoResultWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _particleRotateAnimation;
  late final Animation<double> _particleScaleAnimation;
  late final Animation<Offset> _searchOffsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 12000),
    );
    _particleRotateAnimation =
        Tween<double>(begin: degreeToRadian(0), end: degreeToRadian(60))
            .animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0,
          0.75,
        ),
      ),
    );
    _particleScaleAnimation = Tween<double>(begin: 1, end: 0.75).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1),
      ),
    );
    _setSearchAnimation();
    _controller.repeat(reverse: true);
  }

  void _setSearchAnimation() {
    final moveX = 75.w;
    final moveY = 75.h;

    final extraX = 15.w;
    final extraY = 5.h;

    final initialMove = Offset(extraX, extraY);
    final firstMove = Offset(-moveX, extraY);
    final secondMove = Offset(-moveX, -moveY);
    final thirdMove = Offset(extraX, -moveY);

    _searchOffsetAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: initialMove,
          end: firstMove,
        ),
        weight: 0.25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: firstMove,
          end: secondMove,
        ),
        weight: 0.25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: secondMove,
          end: thirdMove,
        ),
        weight: 0.25,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
          begin: thirdMove,
          end: initialMove,
        ),
        weight: 0.25,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.only(top: 50.h),
          height: 165.h,
          width: 165.w,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                children: [
                  child ?? const SizedBox(),
                  Positioned.fill(
                    child: Transform.rotate(
                      angle: _particleRotateAnimation.value,
                      child: Transform.scale(
                        scale: _particleScaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.15),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Transform.translate(
                      offset: _searchOffsetAnimation.value,
                      child: Icon(
                        Icons.search,
                        size: 32.r,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              );
            },
            child: Positioned.fill(
              child: Icon(
                Icons.manage_search_rounded,
                size: 56.r,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ),
        ),
        SizedBox(
          height: 10.h,
        ),
        Text(
          "Result Not Found",
          textAlign: TextAlign.center,
          style: StylesConstants.normal16w700,
        ),
        SizedBox(
          height: 10.h,
        ),
        Text(
          "Please try again with another keywords or maybe use generic term",
          textAlign: TextAlign.center,
          style: StylesConstants.normal12w500,
        ),
        SizedBox(
          height: 36.h,
        ),
      ],
    );
  }
}

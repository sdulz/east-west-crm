import 'package:flutter/material.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/constant/image_constant.dart';
import 'package:field_crm/common/constant/style_constant.dart';
import 'package:field_crm/common/widgets/empty_data_widget.dart';
import 'package:field_crm/common/widgets/loading.dart';

typedef WidgetReturnFunction = Widget Function();
typedef WidgetReturnCallBackInputFunction =
    Widget Function(VoidCallback onErrorReload);
typedef WidgetReturnStringInputFunction = Widget Function(Object value);

class GenericStateSetup {
  static WidgetReturnFunction _onEmpty = () => const EmptyDataWidget();

  static WidgetReturnFunction _onLoading = () => const CustomLoadingIndicator();
  static WidgetReturnCallBackInputFunction _onErrorReloadButton =
      (onErrorReload) => Center(
        child: ElevatedButton(
          onPressed: onErrorReload,
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorConstant.primaryColor,
          ),

          child: Text("Reload", style: StylesConstants.normal13w400),
        ),
      );

  static WidgetReturnStringInputFunction _errorMessage =
      (error) => Text(
        error.toString(),
        textAlign: TextAlign.center,
        style: StylesConstants.grey18w500,
      );

  static WidgetReturnStringInputFunction get errorMessage => _errorMessage;

  static WidgetReturnFunction get onEmpty => _onEmpty;

  static WidgetReturnCallBackInputFunction get onErrorReloadButton =>
      _onErrorReloadButton;

  static WidgetReturnFunction get onLoading => _onLoading;

  static WidgetReturnFunction _onErrorIcon =
      () => const Center(child: Icon(Icons.error));

  static Widget _defaultOnErrorImage() => Builder(
        builder: (context) {
          bool isLight = Theme.of(context).brightness == Brightness.light;
          return Center(
            child: Image.asset(
              isLight
                  ? ImageConstants.exceptionImageWhite
                  : ImageConstants.exceptionImage,
            ),
          );
        },
      );

  static final WidgetReturnFunction _onErrorImage = _defaultOnErrorImage;

  static WidgetReturnFunction get onErrorIcon => _onErrorIcon;

  static WidgetReturnFunction get onErrorImage => _onErrorImage;

  static void init({
    required WidgetReturnFunction? onEmpty,
    required WidgetReturnFunction? onError,
    required WidgetReturnFunction? onLoading,
    required WidgetReturnCallBackInputFunction? onErrorReloadButton,
    required WidgetReturnStringInputFunction? errorMessage,
  }) {
    _onErrorIcon = onError ?? _onEmpty;
    _onEmpty = onEmpty ?? _onEmpty;
    _onLoading = onLoading ?? _onLoading;
    _onErrorReloadButton = onErrorReloadButton ?? _onErrorReloadButton;
    _errorMessage = errorMessage ?? _errorMessage;
  }
}

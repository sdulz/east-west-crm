
import 'package:flutter/material.dart';
import 'package:field_crm/common/widgets/custom_error.dart';
import 'package:field_crm/common/widgets/loading.dart';



import 'generic_state.dart';

class UiStateHandler<T> extends StatelessWidget {
  final GenericState<T> state;
  final Widget Function(T data) onSuccess;
  final Widget? loadingWidget;
  final Widget? Function(Error error)? errorWidget;
  final Widget? emptyWidget;

  const UiStateHandler({
    super.key,
    required this.state,
    required this.onSuccess,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (state is Loading<T> || state is Empty) {
      if (state is Empty && emptyWidget != null) {
        return emptyWidget!;
      }
      return loadingWidget ?? const CustomLoadingIndicator();
    } else if (state is Success<T>) {
      return onSuccess((state as Success<T>).data);
    } else if (state is Error<T>) {
      return errorWidget?.call((state as Error<T>)) ??
          CustomError(message: (state as Error<T>).message);
    } else {
      return emptyWidget ?? const CustomError();
    }
  }
}

class SliverUIStateHandler<T> extends StatelessWidget {
  final GenericState<T> state;
  final Widget Function(T data) onSuccessSliver;
  final Widget? loadingWidget;
  final Widget? Function(Error message)? errorWidget;
  final Widget? emptyWidget;

  const SliverUIStateHandler({
    super.key,
    required this.state,
    required this.onSuccessSliver,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    if (state is Loading<T> || state is Empty) {
      return SliverToBoxAdapter(
          child: loadingWidget ?? const CustomLoadingIndicator());
    } else if (state is Success<T>) {
      return onSuccessSliver((state as Success<T>).data);
    } else if (state is Error<T>) {
      return SliverToBoxAdapter(
          child: errorWidget?.call((state as Error<T>)) ??
              CustomError(message: (state as Error<T>).message));
    } else {
      return SliverToBoxAdapter(child: emptyWidget ?? const CustomError());
    }
  }
}

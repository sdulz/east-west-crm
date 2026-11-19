import 'package:flutter/material.dart';
import 'package:field_crm/common/utils/generic_state.dart';

import 'generic_state_setup.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';

class GenericStateWidget<T> extends StatelessWidget {
  final Widget Function(T data) onSuccess;
  final Widget Function(Error<T>)? onError;
  final Widget Function()? loadingShimmer;
  final void Function() onErrorReload;

  final Future<void> Function()? onRefresh;

  final GenericState<T> state;
  final bool Function(T data) isEmptyCheck;
  final Widget Function(Success<T>)? onEmpty;
  final bool isSliver;
  final bool useSliverFillRemaining;

  const GenericStateWidget({
    super.key,
    required this.state,
    required this.onSuccess,
    required this.onErrorReload,
    required this.isEmptyCheck,
    this.loadingShimmer,
    this.onRefresh,
    this.onError,
    this.onEmpty,
    this.isSliver = false,
    this.useSliverFillRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    final s = state;

    Widget child;

    if (s is Success<T>) {
      child = _buildSuccess(s);
    } else if (s is Error<T>) {
      child = _buildError(s);
    } else if (s is Loading<T>) {
      child = _buildLoading();
    } else {
      child = _buildEmptyDefault();
    }

    if (onRefresh != null && !isSliver && s is! Loading<T>) {
      return RefreshIndicator(
        onRefresh: () async => await onRefresh?.call(),
        color: ColorConstant.red,
        child: child,
      );
    }

    return child;
  }

  Widget _buildSuccess(Success<T> success) {
    if (isEmptyCheck(success.data)) {
      final emptyWidget = onEmpty?.call(success) ?? GenericStateSetup.onEmpty();

      return isSliver
          ? SliverToBoxAdapter(child: Center(child: emptyWidget))
          : Center(child: emptyWidget);
    }

    final widget = onSuccess(success.data);

    return isSliver ? widget : widget;
  }

  Widget _buildError(Error<T> errorState) {
    if (onError != null) {
      final widget = onError!.call(errorState);
      return isSliver ? SliverToBoxAdapter(child: widget) : widget;
    }

    final widget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Transform.scale(scale: 0.7, child: GenericStateSetup.onErrorImage()),
          const SizedBox(height: 8),
          GenericStateSetup.errorMessage(errorState.message),
          const SizedBox(height: 12),
          Transform.scale(
            scale: 0.85,
            child: GenericStateSetup.onErrorReloadButton(onErrorReload),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );

    return isSliver ? SliverToBoxAdapter(child: widget) : widget;
  }

  Widget _buildLoading() {
    final widget =
        loadingShimmer?.call() ?? Center(child: GenericStateSetup.onLoading());

    if (isSliver) {
      return useSliverFillRemaining
          ? SliverFillRemaining(child: widget)
          : SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: widget,
            ),
          );
    }
    return widget;
  }

  Widget _buildEmptyDefault() {
    final widget = Center(child: GenericStateSetup.onEmpty());

    return isSliver ? SliverToBoxAdapter(child: widget) : widget;
  }
}

///Pagination loading does not work for sliver
class GenericStatePaginationWidget<T> extends StatefulWidget {
  //Below are for GenericStateWidget
  //Must now be sliver
  final Widget Function(T) onSuccess;
  final Widget Function(Error<T>)? onError;
  final Widget Function()? loadingShimmer;
  final void Function() onErrorReload;

  ///Does not work for slivers
  final Future<void> Function()? onRefresh;
  final GenericState<T> state;
  final bool Function(T) isEmptyCheck;

  ///[isEmptyCheck] value must be true to display this widget.
  ///If widget not passed "No result" text will be shown.
  final Widget Function(Success<T>)? onEmpty;
  final bool isSliver;
  final bool useSliverFillRemaining;

  //Below are for Pagination
  final ScrollController scrollController;
  final VoidCallback toFetchNextPage;
  final Axis axis;

  ///Set false if you have having issue on infinite size error
  final bool wrapExpanded;
  final MainAxisSize mainAxisSize;

  const GenericStatePaginationWidget({
    super.key,
    required this.state,
    required this.onSuccess,
    required this.onErrorReload,
    required this.scrollController,
    required this.toFetchNextPage,
    this.loadingShimmer,
    this.onRefresh,
    this.onError,
    required this.isEmptyCheck,
    this.onEmpty,
    this.axis = Axis.vertical,
    this.wrapExpanded = true,
    this.mainAxisSize = MainAxisSize.max,
    this.isSliver = false,
    this.useSliverFillRemaining = true,
  });

  @override
  State<GenericStatePaginationWidget<T>> createState() =>
      _GenericStatePaginationWidgetState<T>();
}

class _GenericStatePaginationWidgetState<T>
    extends State<GenericStatePaginationWidget<T>> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollListener();
    });
  }

  @override
  void didUpdateWidget(GenericStatePaginationWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-check pagination whenever state changes (e.g., after first page loads).
    // This handles the case where the first page fits on screen — no scrolling
    // occurs, so the scroll listener never fires, but we still need to load more.
    if (oldWidget.state != widget.state) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollListener();
      });
    }
  }

  void scrollListener() {
    if (!context.mounted) return;
    if (widget.state.canDoPagination(widget.scrollController)) {
      widget.toFetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GenericStateWidget(
      state: widget.state,
      onSuccess: (data) {
        if (widget.isSliver) {
          final sliverWidget = widget.onSuccess(data);
          if (widget.state.isPaginationLoading) {
            return SliverMainAxisGroup(
              slivers: [
                sliverWidget,
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: GenericStateSetup.onLoading()),
                  ),
                ),
              ],
            );
          }
          return sliverWidget;
        }
        final onSuccess = widget.onSuccess(data);
        final outputValue = Flex(
          direction: widget.axis,
          mainAxisSize: widget.mainAxisSize,
          children: [
            Builder(
              builder: (context) {
                if (widget.wrapExpanded) {
                  return Expanded(child: onSuccess);
                } else {
                  return onSuccess;
                }
              },
            ),
            if (widget.state.isPaginationLoading)
              Center(child: GenericStateSetup.onLoading()),
          ],
        );
        return outputValue;
      },
      onErrorReload: widget.onErrorReload,
      loadingShimmer: widget.loadingShimmer,
      onRefresh: widget.onRefresh,
      onError: widget.onError,
      isEmptyCheck: widget.isEmptyCheck,
      onEmpty: widget.onEmpty,
      isSliver: widget.isSliver,
      useSliverFillRemaining: widget.useSliverFillRemaining,
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(scrollListener);
    //Warning: Never dispose controller here, because it was not created here
    super.dispose();
  }
}

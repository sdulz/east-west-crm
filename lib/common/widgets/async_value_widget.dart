import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:field_crm/common/constant/color_constant_dark_mode.dart';
import 'package:field_crm/common/widgets/generic_state_setup.dart';

class AsyncValueWidget<T> extends StatelessWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) onSuccess;
  final Widget Function()? loadingShimmer;
  final void Function() onErrorReload;
  final Future<void> Function()? onRefresh;
  final bool Function(T data)? isEmptyCheck;
  final Widget Function()? onEmpty;
  final bool isSliver;
  final bool useSliverFillRemaining;

  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.onSuccess,
    required this.onErrorReload,
    this.loadingShimmer,
    this.onRefresh,
    this.isEmptyCheck,
    this.onEmpty,
    this.isSliver = false,
    this.useSliverFillRemaining = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget child = value.when(
      data: _buildSuccess,
      loading: _buildLoading,
      error: _buildError,
    );

    if (onRefresh != null && !isSliver && !value.isLoading) {
      return RefreshIndicator(
        onRefresh: () async => await onRefresh?.call(),
        color: ColorConstant.red,
        child: child,
      );
    }

    return child;
  }

  Widget _buildSuccess(T data) {
    if (isEmptyCheck != null && isEmptyCheck!(data)) {
      final emptyWidget = onEmpty?.call() ?? GenericStateSetup.onEmpty();
      return isSliver
          ? SliverToBoxAdapter(child: Center(child: emptyWidget))
          : Center(child: emptyWidget);
    }

    return onSuccess(data);
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

  Widget _buildError(Object error, StackTrace stackTrace) {
    final widget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 16),
          Transform.scale(scale: 0.7, child: GenericStateSetup.onErrorImage()),
          const SizedBox(height: 8),
          GenericStateSetup.errorMessage(error.toString()),
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
}

class AsyncValuePaginationWidget<T> extends StatefulWidget {
  final AsyncValue<T> value;
  final Widget Function(T data) onSuccess;
  final Widget Function()? loadingShimmer;
  final void Function() onErrorReload;
  final Future<void> Function()? onRefresh;
  final bool Function(T data)? isEmptyCheck;
  final Widget Function()? onEmpty;
  final bool isSliver;
  final bool useSliverFillRemaining;

  final ScrollController scrollController;
  final VoidCallback toFetchNextPage;
  final bool Function() canLoadMore;
  final bool isPaginationLoading;
  final Axis axis;
  final bool wrapExpanded;
  final MainAxisSize mainAxisSize;

  const AsyncValuePaginationWidget({
    super.key,
    required this.value,
    required this.onSuccess,
    required this.onErrorReload,
    required this.scrollController,
    required this.toFetchNextPage,
    required this.canLoadMore,
    this.isPaginationLoading = false,
    this.loadingShimmer,
    this.onRefresh,
    this.isEmptyCheck,
    this.onEmpty,
    this.axis = Axis.vertical,
    this.wrapExpanded = true,
    this.mainAxisSize = MainAxisSize.max,
    this.isSliver = false,
    this.useSliverFillRemaining = true,
  });

  @override
  State<AsyncValuePaginationWidget<T>> createState() =>
      _AsyncValuePaginationWidgetState<T>();
}

class _AsyncValuePaginationWidgetState<T>
    extends State<AsyncValuePaginationWidget<T>> {
  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollListener();
    });
  }

  @override
  void didUpdateWidget(AsyncValuePaginationWidget<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollListener();
      });
    }
  }

  void _scrollListener() {
    if (!context.mounted) return;
    if (!widget.canLoadMore()) return;
    if (widget.isPaginationLoading) return;
    if (!widget.scrollController.hasClients) return;

    final position = widget.scrollController.position;
    if (position.maxScrollExtent == position.pixels ||
        position.extentAfter < 500) {
      widget.toFetchNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AsyncValueWidget<T>(
      value: widget.value,
      onSuccess: (data) {
        if (widget.isSliver) {
          final sliverWidget = widget.onSuccess(data);
          if (widget.isPaginationLoading) {
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
        return Flex(
          direction: widget.axis,
          mainAxisSize: widget.mainAxisSize,
          children: [
            widget.wrapExpanded ? Expanded(child: onSuccess) : onSuccess,
            if (widget.isPaginationLoading)
              Center(child: GenericStateSetup.onLoading()),
          ],
        );
      },
      onErrorReload: widget.onErrorReload,
      loadingShimmer: widget.loadingShimmer,
      onRefresh: widget.onRefresh,
      isEmptyCheck: widget.isEmptyCheck,
      onEmpty: widget.onEmpty,
      isSliver: widget.isSliver,
      useSliverFillRemaining: widget.useSliverFillRemaining,
    );
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_scrollListener);
    super.dispose();
  }
}

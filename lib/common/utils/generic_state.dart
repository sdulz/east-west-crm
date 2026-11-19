import 'package:flutter/widgets.dart';
import 'package:field_crm/common/model/paginated_data.dart';

abstract class GenericState<T> {
  T? dataOrNull() {
    if (this is Success<T>) {
      return (this as Success<T>).data;
    }
    return null;
  }

  R when<R>({
    required R Function() empty,
    required R Function() loading,
    required R Function(T data) success,
    required R Function(String message, int? statusCode) error,
  }) {
    if (this is Empty<T>) {
      return empty();
    } else if (this is Loading<T>) {
      return loading();
    } else if (this is Success<T>) {
      return success((this as Success<T>).data);
    } else if (this is Error<T>) {
      final err = this as Error<T>;
      return error(err.message, err.statusCode);
    }
    throw StateError('Unhandled state: $this');
  }
  R? whenOrNull<R>({
    R Function()? empty,
    R Function()? loading,
    R Function(T data)? success,
    R Function(String message, int? statusCode)? error,
  }) {
    if (this is Empty<T>) {
      return empty?.call();
    } else if (this is Loading<T>) {
      return loading?.call();
    } else if (this is Success<T>) {
      return success?.call((this as Success<T>).data);
    } else if (this is Error<T>) {
      final err = this as Error<T>;
      return error?.call(err.message, err.statusCode);
    }
    return null;
  }
}

class Empty<T> extends GenericState<T> {}

class Loading<T> extends GenericState<T> {}

class Success<T> extends GenericState<T> {
  final T data;
  final bool isPaginationLoading;

  Success(this.data, {this.isPaginationLoading = false});
}

class Error<T> extends GenericState<T> {
  final String message;
  final int? statusCode;

  Error(this.message, {this.statusCode});
}

extension PaginationStateExt<T> on GenericState<PaginatedData<T>> {
  List<T> get list =>
      this is Success ? (this as Success<PaginatedData<T>>).data.items : [];

  bool get canLoadMore =>
      this is Success && (this as Success<PaginatedData<T>>).data.haveNext;

  int get currentPage =>
      this is Success ? (this as Success<PaginatedData<T>>).data.pageIndex : 1;
}

extension GenericStatePaginationExt<T> on GenericState<T> {
  bool get isPaginationLoading {
    if (this is Success<T>) {
      return (this as Success<T>).isPaginationLoading;
    }
    return false;
  }

  bool canDoPagination(ScrollController controller) {
    if (this is Success<T>) {
      if (isPaginationLoading) return false;
      final s = this as Success<T>;
      try {
        final dynamic data = s.data;
        if (data.haveNext == true) {
          if (!controller.hasClients) return false;
          return controller.position.maxScrollExtent == controller.offset ||
              controller.position.extentAfter < 500;
        }
      } catch (_) {
        return false;
      }
    }
    return false;
  }
}

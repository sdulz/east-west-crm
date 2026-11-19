import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'generic_state.dart';

class BaseProvider<T> extends StateNotifier<GenericState<T>> {
  BaseProvider() : super(Empty<T>());

  void loadingState() {
    state = Loading<T>();
  }

  void successState(T data) {
    state = Success<T>(data);
  }

  void errorState(String message, {int? statusCode}) {
    state = Error<T>(message, statusCode: statusCode);
  }

  void setEmpty() {
    state = Empty<T>();
  }
}

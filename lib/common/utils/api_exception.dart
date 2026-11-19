// ignore_for_file: public_member_api_docs, sort_constructors_first
import "dart:async";
import "dart:convert";
import "dart:io";


import "package:dio/dio.dart";

// import "package:geocoding/geocoding.dart";


class ApiErrorHelper implements Exception {
  late final String message;
  final int? statusCode;
  ApiErrorHelper(this.message, {this.statusCode});
  static ApiErrorHelper handleDioException(dynamic ex) {
    if (ex is DioException) {
      var exceptionMessage = "";
      try {
        if (ex.response != null) {
          if (ex.response!.data.runtimeType == String) {
            var decodedMessage = jsonDecode(ex.response?.data);
            if (decodedMessage["message"] != null &&
                decodedMessage["message"].toString().isNotEmpty) {
              exceptionMessage = decodedMessage["message"];
            } else {
              exceptionMessage = decodedMessage["error"] ??
                  decodedMessage["responseData"]["errors"][0]["errorMessage"];
            }
          } else {
            String? errorMessage;
            try {
              if (ex.response!.data.runtimeType == List) {
                errorMessage = (ex.response!.data[0].toString());
              } else {
                try {
                  if (ex.response?.realUri.path == '/api/otp/verify/') {
                    errorMessage = ex.response?.data['details'];
                  } else {
                    errorMessage =
                        (ex.response!.data["errors"][0] as Map<String, dynamic>)
                            .values
                            .first;
                  }
                } catch (_) {
                  errorMessage = (ex.response!.data["response"]);
                }
              }
            } catch (e) {
              errorMessage = null;
            }

            return ApiErrorHelper(
              errorMessage ??
                  ex.response!.data["message"] ??
                  ex.response!.data["error"] ??
                  ex.response!.data["responseData"]["errors"][0]
                      ["errorMessage"],
              statusCode: ex.response?.statusCode,
            );
          }
        } else if (ex.error.runtimeType == SocketException) {
          return ApiErrorHelper('No internet connection', statusCode: -2);
        } else if (ex.type == DioExceptionType.receiveTimeout ||
            ex.type == DioExceptionType.connectionTimeout) {
          return ApiErrorHelper('Connection time out. Please Try again',
              statusCode: -1);
        } else {
          exceptionMessage = 'Something went wrong';
        }
      } catch (ex) {
        exceptionMessage = 'Something went wrong';
      }
      return ApiErrorHelper(exceptionMessage,
          statusCode: ex.response?.statusCode);
    } else if (ex.runtimeType == String) {
      return ApiErrorHelper(ex, statusCode: ex.response?.statusCode);
    } else if (ex.runtimeType == TimeoutException) {
      return ApiErrorHelper('Connection time out. Please Try again',
          statusCode: -1);
    // } else if (ex.runtimeType == PlatformException) {
    //   if ((ex as PlatformException).code == 'PERMISSION_DENIED_NEVER_ASK') {
    //     return ApiErrorHelper('Location Service is disabled.', statusCode: -2);
    //   }
    // } else if (ex.runtimeType == NoResultFoundException) {
    //   return ApiErrorHelper('Could not find the location, Please Try again',
    //       statusCode: -3);
    }
    try {
      return ApiErrorHelper('Something went wrong',
          statusCode: ex.response?.statusCode ?? -1);
    } catch (ex) {
      return ApiErrorHelper(ex.toString(), statusCode: -1);
    }
  }

  @override
  String toString() =>
      'ApiErrorHelper(message: $message, statusCode: $statusCode)';
}

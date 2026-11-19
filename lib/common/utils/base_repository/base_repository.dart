import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_interceptor.dart';
import 'base_repository_setup.dart';
import 'custom_api_exception.dart';
import 'model/request_input.dart';
import 'repository_details.dart';

final class BaseRepository {
  final Dio _client;

  static Dio get staticDio => Dio();

  Dio get dio => _client;
  final RepositoryDetails _globalRepositoryDetails;

  /// If on a specific request, [RepositoryDetails] are not passed,
  /// then this [globalRepositoryDetails] is used.
  RepositoryDetails get globalRepositoryDetails => _globalRepositoryDetails;

  /// You can pass a mocked Dio for testing purposes.
  /// Logs will only be shown in debug/profile mode to protect sensitive data.
  BaseRepository({required Ref ref,Dio? dio, RepositoryDetails? repositoryDetails})
    : _client = dio ?? Dio(),
      _globalRepositoryDetails = repositoryDetails ?? RepositoryDetails() {
    _client.interceptors.add(AppInterceptor(ref));

    if (!kReleaseMode) {
      // Log interceptor for debugging network requests (disabled in release)
      _client.interceptors.add(
        LogInterceptor(
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          requestBody: true,
        ),
      );
    }
  }

  Future<T> get<T>(RequestInput<T> input) async {
    try {
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;

      final heading = await _getHeading(repositoryDetails.tokenNeeded);

      final response = await _client
          .get(
            input.url,
            data: input.body,
            queryParameters: input.params,
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ), 
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return await _parseAndReturn(repositoryDetails, response, input);
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> post<T>(RequestInput<T> input, {bool isMultipart = false}) async {
    try {
      log(input.body.toString(), name: 'input_data');
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;

      final heading = await _getHeading(
        repositoryDetails.tokenNeeded,
        isMultipart: isMultipart,
      );

      final response = await _client
          .post(
            input.url,
            data: input.body,
            queryParameters: input.params,
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ),
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return await _parseAndReturn(repositoryDetails, response, input);
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> delete<T>(RequestInput<T> input) async {
    try {
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;
      final heading = await _getHeading(repositoryDetails.tokenNeeded);

      final response = await _client
          .delete(
            input.url,
            data: input.body,
            queryParameters: input.params,
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ),
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return await _parseAndReturn(repositoryDetails, response, input);
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> put<T>(RequestInput<T> input) async {
    try {
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;
      final heading = await _getHeading(repositoryDetails.tokenNeeded);

      final response = await _client
          .put(
            input.url,
            data: input.body,
            queryParameters: input.params,
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ),
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return await _parseAndReturn(repositoryDetails, response, input);
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> patch<T>(RequestInput<T> input, {bool isMultipart = false}) async {
    try {
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;
      final heading = await _getHeading(
        repositoryDetails.tokenNeeded,
        isMultipart: isMultipart,
      ); 

      final response = await _client
          .patch(
            input.url,
            data: input.body,
            queryParameters: input.params,
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ),
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return await _parseAndReturn(repositoryDetails, response, input);
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<dynamic> download(RequestInput input, String savePath) async {
    try {
      final repositoryDetails =
          input.repositoryDetails ?? _globalRepositoryDetails;
      final heading = await _getHeading(repositoryDetails.tokenNeeded);

      final response = await _client
          .download(
            input.url,
            savePath,
            data: input.body,
            queryParameters: input.params, 
            cancelToken: input.cancelToken,
            options: Options(
              headers: {...heading, ...?input.header},
              responseType: input.responseType,
            ),
          )
          .timeout(Duration(seconds: repositoryDetails.requestTimeout));

      return response.data;
    } catch (e, s) {
      throw CustomAPIException.onCatch(e, s);
    }
  }

  Future<T> _parseAndReturn<T>(
    RepositoryDetails repositoryDetails,
    Response<dynamic> response,
    RequestInput<T> input,
  ) async {
    try {
      final outputJson = repositoryDetails.responseManipulate(response.data);
      return input.parseJson(outputJson);
    } catch (e, s) {
      throw CustomAPIException.onParsing(e, s);
    }
  }

  Future<Map<String, String>> _getHeading(
    bool needToken, {
    bool isMultipart = false,
  }) async {
    final companyIdStr = BaseRepositorySetup.companyIdMapper();
    final token = needToken ? BaseRepositorySetup.tokenMapper() : '';
    return {
      if (!isMultipart) 'Content-Type': 'application/json',
      'Accept': '*/*',
      if (companyIdStr != null) 'X-Company-Id': companyIdStr,
      ...?BaseRepositorySetup.extraHeader,
      if (needToken && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }
}

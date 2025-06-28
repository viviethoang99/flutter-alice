import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_alice/core/alice_core.dart';
import 'package:flutter_alice/model/alice_form_data_file.dart';
import 'package:flutter_alice/model/alice_from_data_field.dart';
import 'package:flutter_alice/model/alice_http_call.dart';
import 'package:flutter_alice/model/alice_http_error.dart';
import 'package:flutter_alice/model/alice_http_request.dart';
import 'package:flutter_alice/model/alice_http_response.dart';

dynamic _defaultDecode(dynamic data) => data;

class AliceDioInterceptor extends InterceptorsWrapper {
  /// AliceCore instance
  final AliceCore aliceCore;

  /// Function to decode data on request.
  final dynamic Function(dynamic data) decodeDataOnRequest;

  /// Default function to decode data on response.
  final dynamic Function(dynamic data) decodeDataOnResponse;

  /// Function to decode data on error.
  final dynamic Function(dynamic data)? decodeDataOnError;

  /// Creates dio interceptor
  AliceDioInterceptor(
    this.aliceCore, {
    dynamic Function(dynamic data)? decodeDataOnResponse,
    dynamic Function(dynamic data)? decodeDataOnRequest,
    dynamic Function(dynamic data)? decodeDataOnError,
  })  : decodeDataOnResponse = decodeDataOnResponse ?? _defaultDecode,
        decodeDataOnRequest = decodeDataOnRequest ?? _defaultDecode,
        decodeDataOnError = decodeDataOnError ?? _defaultDecode;

  /// Handles dio request and creates alice http call based on it
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    AliceHttpCall call = new AliceHttpCall(options.hashCode);

    Uri uri = options.uri;
    call.method = options.method;
    var path = options.uri.path;
    if (path.length == 0) {
      path = "/";
    }
    call.endpoint = path;
    call.server = uri.host;
    call.client = "Dio";
    call.uri = options.uri.toString();

    if (uri.scheme == "https") {
      call.secure = true;
    }

    AliceHttpRequest request = AliceHttpRequest();

    var data = options.data;
    if (data == null) {
      request.size = 0;
      request.body = "";
    } else {
      if (data is FormData) {
        request.body += "Form data";

        if (data.fields.isNotEmpty == true) {
          List<AliceFormDataField> fields = [];
          data.fields.forEach((entry) {
            fields.add(AliceFormDataField(entry.key, entry.value));
          });
          request.formDataFields = fields;
        }
        if (data.files.isNotEmpty == true) {
          List<AliceFormDataFile> files = [];
          data.files.forEach((entry) {
            files.add(
              AliceFormDataFile(
                entry.value.filename!,
                entry.value.contentType.toString(),
                entry.value.length,
              ),
            );
          });

          request.formDataFiles = files;
        }
      } else {
        final decoded = decodeDataOnRequest(data);
        
        if (decoded != data) {
          request.isEncrypted = true;
        } else {
          request.isEncrypted = false;
        }

        request.size = utf8.encode(decoded.toString()).length;
        request.body = decoded;
      }
    }

    request.time = DateTime.now();
    request.headers = options.headers;
    request.contentType = options.contentType.toString();
    request.queryParameters = options.queryParameters;

    call.request = request;
    call.response = AliceHttpResponse();

    aliceCore.addCall(call);
    handler.next(options);
  }

  /// Handles dio response and adds data to alice http call
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    var httpResponse = AliceHttpResponse();
    httpResponse.status = response.statusCode!;

    if (response.data == null) {
      httpResponse.body = "";
      httpResponse.size = 0;
    } else {
      final decoded = decodeDataOnResponse(response.data);
      if (decoded != response.data) {
        httpResponse.isDataDecoded = true;
      } else {
        httpResponse.isDataDecoded = false;
      }

      httpResponse.body = decoded;
      httpResponse.size = utf8.encode(decoded.toString()).length;
    }

    httpResponse.time = DateTime.now();
    Map<String, String> headers = Map();
    response.headers.forEach((header, values) {
      headers[header] = values.toString();
    });
    httpResponse.headers = headers;

    aliceCore.addResponse(httpResponse, response.requestOptions.hashCode);
    handler.next(response);
  }

  /// Handles error and adds data to alice http call
  @override
  void onError(
    DioException error,
    ErrorInterceptorHandler handler,
  ) {
    var httpError = AliceHttpError();
    httpError.error = error.toString();
    if (error is Error) {
      var basicError = error as Error;
      httpError.stackTrace = basicError.stackTrace;
    }

    aliceCore.addError(httpError, error.requestOptions.hashCode);
    var httpResponse = AliceHttpResponse();
    httpResponse.time = DateTime.now();
    if (error.response == null) {
      httpResponse.status = -1;
      aliceCore.addResponse(httpResponse, error.requestOptions.hashCode);
    } else {
      httpResponse.status = error.response!.statusCode!;

      if (error.response!.data == null) {
        httpResponse.body = "";
        httpResponse.size = 0;
      } else {
        final decoded = decodeDataOnError != null
            ? decodeDataOnError!(error.response!.data)
            : decodeDataOnResponse(error.response!.data);
        if (decoded != error.response!.data) {
          httpResponse.isDataDecoded = true;
        } else {
          httpResponse.isDataDecoded = false;
        }
        httpResponse.body = decoded;
        httpResponse.size = utf8.encode(decoded.toString()).length;
      }
      Map<String, String> headers = Map();
      if (error.response?.headers != null) {
        error.response!.headers.forEach((header, values) {
          headers[header] = values.toString();
        });
      }
      httpResponse.headers = headers;
      aliceCore.addResponse(httpResponse, error.response!.requestOptions.hashCode);
    }
    handler.next(error);
  }
}

library logecom_dio;

import 'package:dio/dio.dart';
import 'package:logecom/logger.dart';
import 'package:logecom/translator/http_log_entry.dart';

class DioLoggerInterceptor extends Interceptor {
  DioLoggerInterceptor(this._logger);

  final Logger _logger;
  final _requestStartTime = Map<RequestOptions, DateTime>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _requestStartTime[options] = DateTime.now();
    handler.next(options);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) {
    final startTime = _requestStartTime[err.requestOptions] ?? DateTime.now();
    _requestStartTime.remove(err.requestOptions);
    _logger.log(
      'HTTP',
      HttpLogContext(
        method: err.requestOptions.method,
        url: err.requestOptions.uri,
        statusCode: err.response?.statusCode ?? -1,
        statusMessage: err.response?.statusMessage ?? err.message,
        duration: DateTime.now().difference(startTime),
        responseData: err.response?.data,
        requestData: err.response?.requestOptions.data,
        headers: _getHeaders(err.requestOptions.headers),
      ),
    );
    handler.next(err);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final startTime = _requestStartTime[response.requestOptions] ?? DateTime.now();
    _requestStartTime.remove(response.requestOptions);
    _logger.log(
      'HTTP',
      HttpLogContext(
        method: response.requestOptions.method,
        url: response.requestOptions.uri,
        statusCode: response.statusCode ?? 0,
        statusMessage: response.statusMessage ?? '',
        duration: DateTime.now().difference(startTime),
        responseData: response.data,
        requestData: response.requestOptions.data,
        headers: _getHeaders(response.requestOptions.headers),
      ),
    );
    handler.next(response);
  }

  Map<String, String> _getHeaders(Map<String, dynamic> headers) {
    return headers.map((key, value) {
      if (value is String) {
        return MapEntry(key, value);
      } else if (value is List) {
        return MapEntry(key, value.join('; '));
      } else {
        return MapEntry(key, value.toString());
      }
    });
  }
}

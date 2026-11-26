import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../core/contracts/http_client.dart';
import '../../core/error/error_taxonomy.dart';

/// [HttpClient] over `package:http`.
///
/// Every request has a timeout and a small retry budget: a network failure or a
/// 5xx answer is tried again up to [retries] more times. A server that answers
/// is a result, even an error status; only the lack of any answer raises a
/// `NetworkError`.
class HttpPackageClient implements HttpClient {
  HttpPackageClient({
    http.Client? client,
    this.userAgent = 'TahorBrowser',
    this.retries = 2,
    this.retryDelay = const Duration(milliseconds: 600),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String userAgent;
  final int retries;
  final Duration retryDelay;

  @override
  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    Duration timeout = const Duration(seconds: 20),
  }) async {
    NetworkError failure = const NetworkError.offline();
    for (int attempt = 0; attempt <= retries; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(retryDelay);
      }
      try {
        final http.Response response = await _client
            .get(
              url,
              headers: <String, String>{'user-agent': userAgent, ...headers},
            )
            .timeout(timeout);
        if (response.statusCode >= 500 && attempt < retries) {
          continue;
        }
        return HttpResult(
          response.statusCode,
          Uint8List.fromList(response.bodyBytes),
        );
      } on TimeoutException {
        failure = const NetworkError.timeout();
      } on SocketException {
        failure = const NetworkError.offline();
      } on http.ClientException {
        failure = const NetworkError.offline();
      }
    }
    throw failure;
  }
}

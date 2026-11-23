import 'dart:typed_data';

/// What a GET returned.
class HttpResult {
  const HttpResult(this.status, this.bytes);

  final int status;
  final Uint8List bytes;

  bool get isOk => status >= 200 && status < 300;
}

/// Fetches a URL. Implementations time out, retry a small fixed number of
/// times, and raise an `AppError` when the network fails; a server that answers
/// with an error status is a result, not an exception.
abstract interface class HttpClient {
  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    Duration timeout = const Duration(seconds: 20),
  });
}

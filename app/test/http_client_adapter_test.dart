import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:tahorbrowser/core/contracts/http_client.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';
import 'package:tahorbrowser/platform/common/http_client_adapter.dart';

void main() {
  final Uri url = Uri.parse('https://example.com/x');

  HttpPackageClient make(
    Future<http.Response> Function(http.Request) handler, {
    int retries = 2,
  }) => HttpPackageClient(
    client: MockClient(handler),
    retries: retries,
    retryDelay: Duration.zero,
  );

  test('a successful answer is returned with its status and bytes', () async {
    final HttpResult r = await make(
      (http.Request _) async => http.Response.bytes(<int>[1, 2, 3], 200),
    ).get(url);
    expect(r.status, 200);
    expect(r.bytes, Uint8List.fromList(<int>[1, 2, 3]));
    expect(r.isOk, isTrue);
  });

  test('the app\'s user agent and the caller\'s headers are sent', () async {
    late Map<String, String> sent;
    await make((http.Request req) async {
      sent = req.headers;
      return http.Response('', 200);
    }).get(url, headers: <String, String>{'x-test': 'yes'});
    expect(sent['user-agent'], 'TahorBrowser');
    expect(sent['x-test'], 'yes');
  });

  test('an error status is a result, not an exception', () async {
    final HttpResult r = await make(
      (http.Request _) async => http.Response('', 404),
    ).get(url);
    expect(r.status, 404);
    expect(r.isOk, isFalse);
  });

  test(
    'a server error is tried again and the later success is returned',
    () async {
      int calls = 0;
      final HttpResult r = await make((http.Request _) async {
        calls++;
        return http.Response('', calls < 3 ? 503 : 200);
      }).get(url);
      expect(r.status, 200);
      expect(calls, 3);
    },
  );

  test(
    'a server that keeps failing returns its last answer after the budget',
    () async {
      int calls = 0;
      final HttpResult r = await make((http.Request _) async {
        calls++;
        return http.Response('', 503);
      }).get(url);
      expect(r.status, 503);
      expect(calls, 3);
    },
  );

  test('a client error is not retried', () async {
    int calls = 0;
    await make((http.Request _) async {
      calls++;
      return http.Response('', 403);
    }).get(url);
    expect(calls, 1);
  });

  test('a dropped connection is tried again', () async {
    int calls = 0;
    final HttpResult r = await make((http.Request _) async {
      calls++;
      if (calls < 3) {
        throw const SocketException('reset');
      }
      return http.Response('', 200);
    }).get(url);
    expect(r.status, 200);
  });

  test('no answer at all raises an offline error after the budget', () async {
    int calls = 0;
    await expectLater(
      make((http.Request _) async {
        calls++;
        throw http.ClientException('no route');
      }).get(url),
      throwsA(isA<NetworkError>()),
    );
    expect(calls, 3);
  });

  test('a request that takes too long raises a timeout error', () async {
    await expectLater(
      make((http.Request _) async {
        await Future<void>.delayed(const Duration(milliseconds: 80));
        return http.Response('', 200);
      }, retries: 0).get(url, timeout: const Duration(milliseconds: 10)),
      throwsA(isA<NetworkError>()),
    );
  });

  test('retries can be switched off', () async {
    int calls = 0;
    await make((http.Request _) async {
      calls++;
      return http.Response('', 500);
    }, retries: 0).get(url);
    expect(calls, 1);
  });
}

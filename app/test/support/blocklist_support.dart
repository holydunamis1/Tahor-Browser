import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:tahorbrowser/core/contracts/http_client.dart';

/// Signs manifests the way tools/blocklist does, with a key only tests know.
class TestSigner {
  TestSigner._(this._pair, this.publicKey);

  final SimpleKeyPair _pair;
  final Uint8List publicKey;

  static Future<TestSigner> create([int seedByte = 1]) async {
    final Ed25519 ed = Ed25519();
    final SimpleKeyPair pair = await ed.newKeyPairFromSeed(
      Uint8List(32)..[0] = seedByte,
    );
    final SimplePublicKey pub = await pair.extractPublicKey();
    return TestSigner._(pair, Uint8List.fromList(pub.bytes));
  }

  Future<String> sha256Of(List<int> bytes) async =>
      (await Sha256().hash(bytes)).bytes
          .map((int b) => b.toRadixString(16).padLeft(2, '0'))
          .join();

  /// A manifest for [list] and the base64 signature of its exact text.
  Future<({String json, String signature})> manifestFor(
    Uint8List list, {
    int version = 2,
    String minAppVersion = '0.1.0',
    Map<String, bool> flags = const <String, bool>{'cast': true},
  }) async {
    final String json = jsonEncode(<String, Object?>{
      'version': version,
      'sha256': await sha256Of(list),
      'size': list.length,
      'minAppVersion': minAppVersion,
      'rules': <String, int>{'block': 1, 'allow': 0, 'hide': 0},
      'flags': flags,
    });
    return (json: json, signature: await signText(json));
  }

  Future<String> signText(String text) async => base64Encode(
    (await Ed25519().sign(utf8.encode(text), keyPair: _pair)).bytes,
  );
}

/// Answers GETs from a map; anything else is a 404.
class FakeHttpClient implements HttpClient {
  final Map<String, HttpResult> responses = <String, HttpResult>{};
  final List<String> requested = <String>[];
  Object? failWith;

  void answer(String url, List<int> body, {int status = 200}) {
    responses[url] = HttpResult(status, Uint8List.fromList(body));
  }

  @override
  Future<HttpResult> get(
    Uri url, {
    Map<String, String> headers = const <String, String>{},
    Duration timeout = const Duration(seconds: 20),
  }) async {
    requested.add(url.toString());
    final Object? error = failWith;
    if (error != null) {
      throw error;
    }
    return responses[url.toString()] ?? HttpResult(404, Uint8List(0));
  }
}

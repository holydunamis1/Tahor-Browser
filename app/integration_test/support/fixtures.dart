import 'dart:convert';
import 'dart:io';

/// Pages for the integration tests, kept as strings so none of them ships in
/// the app. They are served from a loopback server because the app refuses to
/// show `data:` addresses as pages.
abstract final class Fixtures {
  static String page(String title, {String? body}) =>
      '<!doctype html><html><head><meta charset="utf-8">'
      '<meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>$title</title></head>'
      '<body>${body ?? '<h1>$title</h1>'}</body></html>';

  /// A page about 7,000 CSS pixels tall, so there is room to scroll.
  static String tall(String title) => page(
    title,
    body:
        '<h1>$title</h1>'
        '${List<String>.generate(120, (int i) => '<p style="height:60px;margin:0">Line $i</p>').join()}',
  );

  static final Map<String, String> pages = <String, String>{
    '/a': page('Page A'),
    '/b': page('Page B'),
    '/tall1': tall('Tall 1'),
    '/tall2': tall('Tall 2'),
    '/tall3': tall('Tall 3'),
  };
}

/// Serves [Fixtures.pages] on a free loopback port of the device the tests run
/// on.
class FixtureServer {
  FixtureServer._(this._server);

  final HttpServer _server;

  static Future<FixtureServer> start() async {
    final HttpServer server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final FixtureServer fixture = FixtureServer._(server);
    server.listen(fixture._handle);
    return fixture;
  }

  Uri uri(String path) =>
      Uri.parse('http://${_server.address.host}:${_server.port}$path');

  void _handle(HttpRequest request) {
    final String? body = Fixtures.pages[request.uri.path];
    final HttpResponse response = request.response;
    if (body == null) {
      response.statusCode = HttpStatus.notFound;
    } else {
      response.headers.contentType = ContentType.html;
      response.add(utf8.encode(body));
    }
    response.close();
  }

  Future<void> close() => _server.close(force: true);
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/platform/android/android_external_launcher.dart';
import 'package:tahorbrowser/platform/common/url_launcher_external_launcher.dart';

class Recorder {
  Recorder(this.results);

  /// What each launch returns, in order; later launches return false.
  final List<bool> results;
  final List<String> launched = <String>[];

  Future<bool> call(Uri uri) async {
    launched.add(uri.toString());
    return launched.length <= results.length
        ? results[launched.length - 1]
        : false;
  }
}

void main() {
  group('UrlLauncherExternalLauncher', () {
    test('the system browser takes only web addresses', () async {
      final Recorder r = Recorder(<bool>[true, true]);
      final UrlLauncherExternalLauncher l = UrlLauncherExternalLauncher(
        launch: r.call,
      );
      expect(
        await l.openInSystemBrowser(Uri.parse('https://example.com')),
        isTrue,
      );
      expect(
        await l.openInSystemBrowser(Uri.parse('http://example.com')),
        isTrue,
      );
      expect(await l.openInSystemBrowser(Uri.parse('tel:+123')), isFalse);
      expect(
        await l.openInSystemBrowser(Uri.parse('javascript:alert(1)')),
        isFalse,
      );
      expect(r.launched, <String>['https://example.com', 'http://example.com']);
    });

    test(
      'other apps can be opened for phone, mail and similar addresses',
      () async {
        final Recorder r = Recorder(<bool>[true, true, true]);
        final UrlLauncherExternalLauncher l = UrlLauncherExternalLauncher(
          launch: r.call,
        );
        expect(await l.openExternalApp(Uri.parse('tel:+123')), isTrue);
        expect(await l.openExternalApp(Uri.parse('mailto:a@b.co')), isTrue);
        expect(
          await l.openExternalApp(Uri.parse('market://details?id=com.x')),
          isTrue,
        );
        expect(r.launched.length, 3);
      },
    );

    test('addresses that run code or read files are never handed on', () async {
      final Recorder r = Recorder(<bool>[true]);
      final UrlLauncherExternalLauncher l = UrlLauncherExternalLauncher(
        launch: r.call,
      );
      for (final String url in <String>[
        'javascript:alert(1)',
        'file:///etc/passwd',
        'data:text/html,x',
        'blob:https://a.com/1',
        'content://media/1',
        'about:blank',
      ]) {
        expect(await l.openExternalApp(Uri.parse(url)), isFalse, reason: url);
      }
      expect(await l.openExternalApp(Uri.parse('relative/path')), isFalse);
      expect(r.launched, isEmpty);
    });

    test('a platform failure becomes false', () async {
      final UrlLauncherExternalLauncher l = UrlLauncherExternalLauncher(
        launch: (Uri uri) => throw Exception('no handler'),
      );
      expect(await l.openInSystemBrowser(Uri.parse('https://a.com')), isFalse);
      expect(await l.openExternalApp(Uri.parse('tel:1')), isFalse);
    });
  });

  group('AndroidExternalLauncher', () {
    const String link =
        'intent://scan/#Intent;scheme=zxing;package=com.google.zxing.client.android;'
        'S.browser_fallback_url=https%3A%2F%2Fexample.com%2Fdl;end';

    test('opens the app named by an intent link', () async {
      final Recorder r = Recorder(<bool>[true]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(await l.openExternalApp(Uri.parse(link)), isTrue);
      expect(r.launched, <String>['zxing://scan/']);
    });

    test('falls back to the store page when no app handles it', () async {
      final Recorder r = Recorder(<bool>[false, true]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(await l.openExternalApp(Uri.parse(link)), isTrue);
      expect(r.launched, <String>[
        'zxing://scan/',
        'market://details?id=com.google.zxing.client.android',
      ]);
    });

    test('reports failure when neither the app nor the store opens', () async {
      final Recorder r = Recorder(<bool>[false, false]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(await l.openExternalApp(Uri.parse(link)), isFalse);
      expect(r.launched.length, 2);
    });

    test('an unusable intent link opens nothing', () async {
      final Recorder r = Recorder(<bool>[true]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(await l.openExternalApp(Uri.parse('intent://x')), isFalse);
      expect(r.launched, isEmpty);
    });

    test('a store address opens directly', () async {
      final Recorder r = Recorder(<bool>[true]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(
        await l.openExternalApp(Uri.parse('market://details?id=com.x')),
        isTrue,
      );
      expect(r.launched, <String>['market://details?id=com.x']);
    });

    test('other schemes behave like the common launcher', () async {
      final Recorder r = Recorder(<bool>[true]);
      final AndroidExternalLauncher l = AndroidExternalLauncher(launch: r.call);
      expect(await l.openExternalApp(Uri.parse('tel:+123')), isTrue);
      expect(
        await l.openExternalApp(Uri.parse('javascript:alert(1)')),
        isFalse,
      );
      expect(r.launched, <String>['tel:+123']);
    });
  });
}

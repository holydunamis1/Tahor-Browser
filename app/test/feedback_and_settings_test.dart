import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/models/app_settings.dart';
import 'package:tahorbrowser/core/providers/feedback_provider.dart';

void main() {
  group('FeedbackProvider', () {
    test('shows a message and clears it by itself', () async {
      final FeedbackProvider feedback = FeedbackProvider(
        visibleFor: const Duration(milliseconds: 20),
      );
      feedback.show('Link copied');
      expect(feedback.value, const FeedbackMessage('Link copied'));
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(feedback.value, isNull);
      feedback.dispose();
    });

    test('a new message replaces the old one and restarts the clock', () async {
      final FeedbackProvider feedback = FeedbackProvider(
        visibleFor: const Duration(milliseconds: 60),
      );
      feedback.show('one');
      await Future<void>.delayed(const Duration(milliseconds: 40));
      feedback.show('two', isError: true);
      await Future<void>.delayed(const Duration(milliseconds: 40));
      expect(feedback.value, const FeedbackMessage('two', isError: true));
      feedback.dispose();
    });

    test('dismiss clears it at once', () {
      final FeedbackProvider feedback = FeedbackProvider();
      feedback.show('x');
      feedback.dismiss();
      expect(feedback.value, isNull);
      feedback.dispose();
    });

    test('disposing with a message showing leaves no timer running', () {
      final FeedbackProvider feedback = FeedbackProvider();
      feedback.show('x');
      feedback.dispose();
    });
  });

  group('start-up setting', () {
    test('the default is to continue where the person left off', () {
      expect(const AppSettings().startupMode, StartupMode.continueSession);
    });

    test('it survives toJson and fromJson', () {
      const AppSettings s = AppSettings(startupMode: StartupMode.startPage);
      expect(AppSettings.fromJson(s.toJson()), s);
    });

    test('a value saved before it existed takes the default', () {
      final AppSettings old = AppSettings.fromJson(<String, Object?>{
        'v': 1,
        'themeMode': 'dark',
      });
      expect(old.startupMode, StartupMode.continueSession);
      expect(old.themeMode, AppThemeMode.dark);
    });

    test('an unknown or wrong-typed value takes the default', () {
      for (final Object? bad in <Object?>['later', 7, null]) {
        expect(
          AppSettings.fromJson(<String, Object?>{'startupMode': bad})
              .startupMode,
          StartupMode.continueSession,
          reason: '$bad',
        );
      }
    });

    test('copyWith changes only the start-up mode', () {
      const AppSettings s = AppSettings(themeMode: AppThemeMode.light);
      final AppSettings changed = s.copyWith(
        startupMode: StartupMode.startPage,
      );
      expect(changed.startupMode, StartupMode.startPage);
      expect(changed.themeMode, AppThemeMode.light);
    });
  });
}

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tahorbrowser/core/error/error_taxonomy.dart';

class Expectation {
  const Expectation(
    this.error,
    this.code,
    this.kind,
    this.recoverability,
    this.retryability,
    this.cause,
    this.treatment,
  );

  final AppError error;
  final String code;
  final ErrorKind kind;
  final Recoverability recoverability;
  final Retryability retryability;
  final ErrorCause cause;
  final ErrorTreatment treatment;
}

/// Compiles only while every subclass of the sealed [AppError] is handled.
ErrorKind kindOfSubclass(AppError e) => switch (e) {
  NetworkError() => ErrorKind.network,
  StorageError() => ErrorKind.storage,
  PermissionError() => ErrorKind.permission,
  WebViewError() => ErrorKind.webView,
  BlocklistError() => ErrorKind.blocklist,
  BillingError() => ErrorKind.billing,
  ConsentError() => ErrorKind.consent,
  UnexpectedError() => ErrorKind.unexpected,
};

void main() {
  const Recoverability rec = Recoverability.recoverable;
  const Retryability retry = Retryability.retriable;
  const Retryability term = Retryability.terminal;
  const ErrorCause sys = ErrorCause.system;
  const ErrorCause usr = ErrorCause.user;

  final List<Expectation> table = <Expectation>[
    const Expectation(
      NetworkError.offline(),
      'network.offline',
      ErrorKind.network,
      rec,
      retry,
      sys,
      ErrorTreatment.inlineBanner,
    ),
    const Expectation(
      NetworkError.timeout(),
      'network.timeout',
      ErrorKind.network,
      rec,
      retry,
      sys,
      ErrorTreatment.inlineBanner,
    ),
    Expectation(
      NetworkError.http(503),
      'network.http.503',
      ErrorKind.network,
      rec,
      retry,
      sys,
      ErrorTreatment.inlineBanner,
    ),
    Expectation(
      NetworkError.http(404),
      'network.http.404',
      ErrorKind.network,
      rec,
      term,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      StorageError.readFailed(),
      'storage.read',
      ErrorKind.storage,
      rec,
      term,
      sys,
      ErrorTreatment.inlineBanner,
    ),
    const Expectation(
      StorageError.writeFailed(),
      'storage.write',
      ErrorKind.storage,
      rec,
      term,
      sys,
      ErrorTreatment.inlineBanner,
    ),
    const Expectation(
      StorageError.corrupted(),
      'storage.corrupted',
      ErrorKind.storage,
      rec,
      term,
      sys,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      StorageError.full(),
      'storage.full',
      ErrorKind.storage,
      rec,
      retry,
      usr,
      ErrorTreatment.feedbackBanner,
    ),
    Expectation(
      PermissionError.denied('camera'),
      'permission.denied.camera',
      ErrorKind.permission,
      rec,
      retry,
      usr,
      ErrorTreatment.inlineBanner,
    ),
    Expectation(
      PermissionError.deniedForever('location'),
      'permission.denied_forever.location',
      ErrorKind.permission,
      rec,
      term,
      usr,
      ErrorTreatment.inlineBanner,
    ),
    const Expectation(
      WebViewError.loadFailed(),
      'webview.load',
      ErrorKind.webView,
      rec,
      retry,
      sys,
      ErrorTreatment.fullScreen,
    ),
    const Expectation(
      WebViewError.rendererGone(),
      'webview.renderer_gone',
      ErrorKind.webView,
      rec,
      retry,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      WebViewError.certificate(),
      'webview.certificate',
      ErrorKind.webView,
      rec,
      term,
      sys,
      ErrorTreatment.fullScreen,
    ),
    const Expectation(
      BlocklistError.fetchFailed(),
      'blocklist.fetch',
      ErrorKind.blocklist,
      rec,
      retry,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      BlocklistError.fetchFailed(background: true),
      'blocklist.fetch',
      ErrorKind.blocklist,
      rec,
      retry,
      sys,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      BlocklistError.verificationFailed(),
      'blocklist.verification',
      ErrorKind.blocklist,
      rec,
      term,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      BlocklistError.invalid(),
      'blocklist.invalid',
      ErrorKind.blocklist,
      rec,
      term,
      sys,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      BillingError.unavailable(),
      'billing.unavailable',
      ErrorKind.billing,
      rec,
      retry,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      BillingError.purchaseFailed(),
      'billing.purchase',
      ErrorKind.billing,
      rec,
      retry,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      BillingError.cancelled(),
      'billing.cancelled',
      ErrorKind.billing,
      rec,
      retry,
      usr,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      BillingError.pending(),
      'billing.pending',
      ErrorKind.billing,
      rec,
      retry,
      sys,
      ErrorTreatment.feedbackBanner,
    ),
    const Expectation(
      ConsentError.refreshFailed(),
      'consent.refresh',
      ErrorKind.consent,
      rec,
      retry,
      sys,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      ConsentError.formFailed(),
      'consent.form',
      ErrorKind.consent,
      rec,
      retry,
      sys,
      ErrorTreatment.silentLog,
    ),
    const Expectation(
      UnexpectedError.build('x'),
      'unexpected.build',
      ErrorKind.unexpected,
      Recoverability.fatal,
      term,
      sys,
      ErrorTreatment.fullScreen,
    ),
    const Expectation(
      UnexpectedError.async('x'),
      'unexpected.async',
      ErrorKind.unexpected,
      rec,
      term,
      sys,
      ErrorTreatment.silentLog,
    ),
  ];

  test('every error class is classified and has a treatment', () {
    for (final Expectation e in table) {
      expect(e.error.code, e.code);
      expect(e.error.kind, e.kind, reason: e.code);
      expect(e.error.recoverability, e.recoverability, reason: e.code);
      expect(e.error.retryability, e.retryability, reason: e.code);
      expect(e.error.cause, e.cause, reason: e.code);
      expect(e.error.treatment, e.treatment, reason: e.code);
      expect(kindOfSubclass(e.error), e.kind, reason: e.code);
    }
  });

  test('every class of the sealed hierarchy appears in the table', () {
    final Set<ErrorKind> seen = table
        .map((Expectation e) => kindOfSubclass(e.error))
        .toSet();
    expect(seen, ErrorKind.values.toSet());
  });

  test('codes are stable dotted identifiers', () {
    final RegExp pattern = RegExp(r'^[a-z_]+(\.[a-z0-9_]+)+$');
    for (final Expectation e in table) {
      expect(pattern.hasMatch(e.code), isTrue, reason: e.code);
    }
  });

  test('a fatal error always replaces the screen', () {
    for (final Expectation e in table) {
      if (e.error.recoverability == Recoverability.fatal) {
        expect(e.error.treatment, ErrorTreatment.fullScreen);
        expect(e.error.isRecoverable, isFalse);
      }
    }
  });

  test('flags mirror the axes', () {
    expect(const NetworkError.offline().isRecoverable, isTrue);
    expect(const NetworkError.offline().isRetriable, isTrue);
    expect(const StorageError.corrupted().isRetriable, isFalse);
  });

  group('classify', () {
    test('an AppError is returned unchanged', () {
      const NetworkError e = NetworkError.offline();
      expect(identical(AppError.classify(e), e), isTrue);
    });

    test('a TimeoutException becomes a network timeout', () {
      expect(
        AppError.classify(TimeoutException('slow')).code,
        'network.timeout',
      );
    });

    test('anything else is unexpected: silent in the background', () {
      final AppError e = AppError.classify(StateError('boom'));
      expect(e.code, 'unexpected.async');
      expect(e.treatment, ErrorTreatment.silentLog);
      expect(e.detail, contains('boom'));
    });

    test('anything else from a build is fatal and full screen', () {
      final AppError e = AppError.classify(StateError('boom'), fromBuild: true);
      expect(e.code, 'unexpected.build');
      expect(e.treatment, ErrorTreatment.fullScreen);
      expect(e.isRecoverable, isFalse);
    });
  });

  test('toString carries the code and the detail', () {
    expect(
      const NetworkError.offline().toString(),
      'AppError(network.offline)',
    );
    expect(
      const StorageError.readFailed(detail: 'disk').toString(),
      'AppError(storage.read: disk)',
    );
  });
}

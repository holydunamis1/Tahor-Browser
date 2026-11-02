import 'dart:async';

import 'package:flutter/widgets.dart';

/// Which part of the app an error comes from.
enum ErrorKind {
  network,
  storage,
  permission,
  webView,
  blocklist,
  billing,
  consent,
  unexpected,
}

/// Axis one: can the app carry on after this error?
enum Recoverability { recoverable, fatal }

/// Axis two: would trying again help?
enum Retryability { retriable, terminal }

/// Axis three: who caused it?
enum ErrorCause { user, system }

/// How an error is shown. Every error has exactly one treatment.
enum ErrorTreatment {
  /// A banner inside the content that failed.
  inlineBanner,

  /// A short message after an action (save, copy, update).
  feedbackBanner,

  /// The error replaces the whole content area or screen.
  fullScreen,

  /// Nothing is shown; the error is only written to the in-memory log.
  silentLog,
}

/// An error classified on three axes with a defined treatment.
///
/// [code] is a stable dotted identifier such as `network.offline`. It is the
/// only thing an error report carries.
@immutable
sealed class AppError implements Exception {
  const AppError({
    required this.code,
    required this.kind,
    required this.recoverability,
    required this.retryability,
    required this.cause,
    required this.treatment,
    this.detail,
  });

  final String code;
  final ErrorKind kind;
  final Recoverability recoverability;
  final Retryability retryability;
  final ErrorCause cause;
  final ErrorTreatment treatment;

  /// Technical detail for the in-memory log. Never shown and never sent.
  final String? detail;

  bool get isRecoverable => recoverability == Recoverability.recoverable;
  bool get isRetriable => retryability == Retryability.retriable;

  /// Turns anything that was thrown into an [AppError].
  ///
  /// Errors thrown while building widgets pass `fromBuild: true` and become
  /// fatal full-screen errors; everything else unknown is logged silently.
  static AppError classify(Object error, {bool fromBuild = false}) {
    if (error is AppError) {
      return error;
    }
    if (error is TimeoutException) {
      return const NetworkError.timeout();
    }
    return fromBuild
        ? UnexpectedError.build(error.toString())
        : UnexpectedError.async(error.toString());
  }

  @override
  String toString() => 'AppError($code${detail == null ? '' : ': $detail'})';
}

final class NetworkError extends AppError {
  const NetworkError._({
    required super.code,
    required super.retryability,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.network,
         recoverability: Recoverability.recoverable,
         cause: ErrorCause.system,
       );

  const NetworkError.offline()
    : this._(
        code: 'network.offline',
        retryability: Retryability.retriable,
        treatment: ErrorTreatment.inlineBanner,
      );

  const NetworkError.timeout()
    : this._(
        code: 'network.timeout',
        retryability: Retryability.retriable,
        treatment: ErrorTreatment.inlineBanner,
      );

  /// A server answered with an error status. Server faults (5xx) are worth
  /// retrying; client faults (4xx) are not.
  NetworkError.http(int status)
    : this._(
        code: 'network.http.$status',
        retryability: status >= 500
            ? Retryability.retriable
            : Retryability.terminal,
        treatment: status >= 500
            ? ErrorTreatment.inlineBanner
            : ErrorTreatment.feedbackBanner,
        detail: 'status $status',
      );
}

final class StorageError extends AppError {
  const StorageError._({
    required super.code,
    required super.retryability,
    required super.cause,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.storage,
         recoverability: Recoverability.recoverable,
       );

  /// A read failed; the app continues with in-memory values.
  const StorageError.readFailed({String? detail})
    : this._(
        code: 'storage.read',
        retryability: Retryability.terminal,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.inlineBanner,
        detail: detail,
      );

  /// A write failed; changes may be lost when the app closes.
  const StorageError.writeFailed({String? detail})
    : this._(
        code: 'storage.write',
        retryability: Retryability.terminal,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.inlineBanner,
        detail: detail,
      );

  /// Stored data was unreadable and was replaced with defaults.
  const StorageError.corrupted({String? detail})
    : this._(
        code: 'storage.corrupted',
        retryability: Retryability.terminal,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.silentLog,
        detail: detail,
      );

  /// The device is out of space.
  const StorageError.full()
    : this._(
        code: 'storage.full',
        retryability: Retryability.retriable,
        cause: ErrorCause.user,
        treatment: ErrorTreatment.feedbackBanner,
      );
}

final class PermissionError extends AppError {
  const PermissionError._({
    required super.code,
    required super.retryability,
    super.detail,
  }) : super(
         kind: ErrorKind.permission,
         recoverability: Recoverability.recoverable,
         cause: ErrorCause.user,
         treatment: ErrorTreatment.inlineBanner,
       );

  /// The user declined; asking again can succeed.
  PermissionError.denied(String permission)
    : this._(
        code: 'permission.denied.$permission',
        retryability: Retryability.retriable,
        detail: permission,
      );

  /// Declined for good; only the system settings can change it.
  PermissionError.deniedForever(String permission)
    : this._(
        code: 'permission.denied_forever.$permission',
        retryability: Retryability.terminal,
        detail: permission,
      );
}

final class WebViewError extends AppError {
  const WebViewError._({
    required super.code,
    required super.retryability,
    required super.cause,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.webView,
         recoverability: Recoverability.recoverable,
       );

  /// The main frame failed to load.
  const WebViewError.loadFailed({String? detail})
    : this._(
        code: 'webview.load',
        retryability: Retryability.retriable,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.fullScreen,
        detail: detail,
      );

  /// The renderer process died; the page is reloaded from saved state.
  const WebViewError.rendererGone()
    : this._(
        code: 'webview.renderer_gone',
        retryability: Retryability.retriable,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.feedbackBanner,
      );

  /// The site presented a bad certificate.
  const WebViewError.certificate({String? detail})
    : this._(
        code: 'webview.certificate',
        retryability: Retryability.terminal,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.fullScreen,
        detail: detail,
      );
}

final class BlocklistError extends AppError {
  const BlocklistError._({
    required super.code,
    required super.retryability,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.blocklist,
         recoverability: Recoverability.recoverable,
         cause: ErrorCause.system,
       );

  /// The list could not be downloaded. A background refresh stays silent; a
  /// manual one tells the user. The last good list always stays active.
  const BlocklistError.fetchFailed({bool background = false, String? detail})
    : this._(
        code: 'blocklist.fetch',
        retryability: Retryability.retriable,
        treatment: background
            ? ErrorTreatment.silentLog
            : ErrorTreatment.feedbackBanner,
        detail: detail,
      );

  /// The downloaded list failed its signature or hash check.
  const BlocklistError.verificationFailed({String? detail})
    : this._(
        code: 'blocklist.verification',
        retryability: Retryability.terminal,
        treatment: ErrorTreatment.feedbackBanner,
        detail: detail,
      );

  /// A list could not be parsed or compiled.
  const BlocklistError.invalid({String? detail})
    : this._(
        code: 'blocklist.invalid',
        retryability: Retryability.terminal,
        treatment: ErrorTreatment.silentLog,
        detail: detail,
      );
}

final class BillingError extends AppError {
  const BillingError._({
    required super.code,
    required super.retryability,
    required super.cause,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.billing,
         recoverability: Recoverability.recoverable,
       );

  /// The store is not available on this device.
  const BillingError.unavailable()
    : this._(
        code: 'billing.unavailable',
        retryability: Retryability.retriable,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.feedbackBanner,
      );

  const BillingError.purchaseFailed({String? detail})
    : this._(
        code: 'billing.purchase',
        retryability: Retryability.retriable,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.feedbackBanner,
        detail: detail,
      );

  /// The user closed the purchase sheet.
  const BillingError.cancelled()
    : this._(
        code: 'billing.cancelled',
        retryability: Retryability.retriable,
        cause: ErrorCause.user,
        treatment: ErrorTreatment.silentLog,
      );

  /// The store is still processing the payment.
  const BillingError.pending()
    : this._(
        code: 'billing.pending',
        retryability: Retryability.retriable,
        cause: ErrorCause.system,
        treatment: ErrorTreatment.feedbackBanner,
      );
}

final class ConsentError extends AppError {
  const ConsentError._({
    required super.code,
    required super.retryability,
    super.detail,
  }) : super(
         kind: ErrorKind.consent,
         recoverability: Recoverability.recoverable,
         cause: ErrorCause.system,
         treatment: ErrorTreatment.silentLog,
       );

  /// The consent refresh failed. A saved record that permits ads stays valid.
  const ConsentError.refreshFailed({String? detail})
    : this._(
        code: 'consent.refresh',
        retryability: Retryability.retriable,
        detail: detail,
      );

  const ConsentError.formFailed({String? detail})
    : this._(
        code: 'consent.form',
        retryability: Retryability.retriable,
        detail: detail,
      );
}

final class UnexpectedError extends AppError {
  const UnexpectedError._({
    required super.code,
    required super.recoverability,
    required super.treatment,
    super.detail,
  }) : super(
         kind: ErrorKind.unexpected,
         retryability: Retryability.terminal,
         cause: ErrorCause.system,
       );

  /// Thrown while building or laying out widgets: the screen is replaced by
  /// the fallback view.
  const UnexpectedError.build(String detail)
    : this._(
        code: 'unexpected.build',
        recoverability: Recoverability.fatal,
        treatment: ErrorTreatment.fullScreen,
        detail: detail,
      );

  /// An uncaught error outside the widget tree: logged, the app carries on.
  const UnexpectedError.async(String detail)
    : this._(
        code: 'unexpected.async',
        recoverability: Recoverability.recoverable,
        treatment: ErrorTreatment.silentLog,
        detail: detail,
      );
}

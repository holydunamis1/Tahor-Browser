import 'package:flutter/widgets.dart';

import '../../core/error/error_taxonomy.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../l10n/l10n_extensions.dart';
import '../icons/semantic_icons.dart';
import 'empty_state.dart';
import 'primary_button.dart';

/// The words for an error, chosen by its class and code.
String errorMessage(AppLocalizations l10n, AppError error) {
  switch (error) {
    case NetworkError():
      if (error.code == 'network.offline') {
        return l10n.errorOffline;
      }
      if (error.code == 'network.timeout') {
        return l10n.errorTimeout;
      }
      final int? status = int.tryParse(error.code.split('.').last);
      return status == null ? l10n.errorUnexpected : l10n.errorServer(status);
    case StorageError():
      return error.code == 'storage.full'
          ? l10n.errorStorageFull
          : l10n.errorStorage;
    case PermissionError():
      return l10n.errorPermissionDenied;
    case WebViewError():
      switch (error.code) {
        case 'webview.renderer_gone':
          return l10n.errorRendererGone;
        case 'webview.certificate':
          return l10n.errorCertificate;
        default:
          return l10n.errorWebViewLoad;
      }
    case BlocklistError():
      return error.code == 'blocklist.verification'
          ? l10n.errorBlocklistVerify
          : l10n.errorBlocklistFetch;
    case BillingError():
      switch (error.code) {
        case 'billing.unavailable':
          return l10n.errorBillingUnavailable;
        case 'billing.pending':
          return l10n.errorBillingPending;
        default:
          return l10n.errorBillingFailed;
      }
    case ConsentError():
    case UnexpectedError():
      return l10n.errorUnexpected;
  }
}

/// A screen or area that could not load, with a Try again button when trying
/// again can help. The words come from the error's class.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.error, this.onRetry});

  final AppError error;

  /// Shown as a button only when the error can be retried.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bool offline = error.code == 'network.offline';
    return EmptyState(
      glyph: offline ? AppIcons.offline : AppIcons.warning,
      title: errorMessage(l10n, error),
      action: error.isRetriable && onRetry != null
          ? PrimaryButton(
              label: l10n.errorFallbackRetry,
              onPressed: onRetry,
              expanded: false,
            )
          : null,
    );
  }
}

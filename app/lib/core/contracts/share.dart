/// The system share sheet.
abstract interface class Share {
  Future<void> shareUrl(Uri url, {String? title});
}

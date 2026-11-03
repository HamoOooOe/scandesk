/// What is printed inside an asset's QR sticker, and how to read it back.
///
/// Format: `scandesk://asset/LAP-0007`. The code alone (`LAP-0007`) is
/// accepted too, which is what a person types when the camera is not an
/// option. Anything else is not ours and is rejected.
class QrPayload {
  const QrPayload._();

  static const String scheme = 'scandesk';
  static const String host = 'asset';

  static final RegExp _code = RegExp(r'^[A-Z]{3}-\d{4,}$');

  static String encode(String assetCode) => '$scheme://$host/$assetCode';

  /// Returns the asset code, or null when [raw] is not a ScanDesk label.
  static String? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    var candidate = text;
    final uri = Uri.tryParse(text);
    if (uri != null && uri.hasScheme) {
      if (uri.scheme != scheme || uri.host != host || uri.pathSegments.length != 1) {
        return null;
      }
      candidate = uri.pathSegments.first;
    }

    candidate = candidate.toUpperCase();
    return _code.hasMatch(candidate) ? candidate : null;
  }
}

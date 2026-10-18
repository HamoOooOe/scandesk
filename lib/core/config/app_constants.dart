/// App-wide constants. Keep magic strings and numbers here, not in widgets.
class AppConstants {
  const AppConstants._();

  static const String appName = 'ScanDesk';

  /// Prefix inside every asset QR code, e.g. `scandesk://asset/PC-0042`.
  static const String qrPrefix = 'scandesk://asset/';

  static const Duration networkTimeout = Duration(seconds: 15);
  static const int pageSize = 20;

  // Supabase table names (one place to change them).
  static const String profilesTable = 'profiles';
  static const String sitesTable = 'sites';
  static const String locationsTable = 'locations';
  static const String assetsTable = 'assets';
  static const String ticketsTable = 'tickets';
  static const String ticketPhotosTable = 'ticket_photos';
  static const String workLogsTable = 'work_logs';
  static const String deviceTokensTable = 'device_tokens';
}

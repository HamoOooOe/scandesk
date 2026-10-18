/// Exceptions are thrown in the data layer (talking to Supabase, the
/// local database, the camera...). Repositories catch them and turn them
/// into [Failure]s so the UI never sees raw exceptions.
class ServerException implements Exception {
  const ServerException(this.message);
  final String message;

  @override
  String toString() => 'ServerException: $message';
}

class CacheException implements Exception {
  const CacheException(this.message);
  final String message;

  @override
  String toString() => 'CacheException: $message';
}

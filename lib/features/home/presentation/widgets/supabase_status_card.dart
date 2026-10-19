import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:scandesk/core/config/app_constants.dart';
import 'package:scandesk/core/config/env.dart';
import 'package:scandesk/core/di/injection.dart';
import 'package:scandesk/core/l10n/generated/app_localizations.dart';

enum _Connection { notConfigured, connected, unreachable }

/// Sprint 0 check: can the app reach your Supabase project?
class SupabaseStatusCard extends StatefulWidget {
  const SupabaseStatusCard({super.key});

  @override
  State<SupabaseStatusCard> createState() => _SupabaseStatusCardState();
}

class _SupabaseStatusCardState extends State<SupabaseStatusCard> {
  late Future<(_Connection, String?)> _check = _runCheck();

  Future<(_Connection, String?)> _runCheck() async {
    if (!Env.isSupabaseConfigured) return (_Connection.notConfigured, null);
    try {
      await sl<SupabaseClient>()
          .from(AppConstants.profilesTable)
          .select('id')
          .limit(1);
      return (_Connection.connected, null);
    } on PostgrestException catch (e) {
      // The server answered, so the connection works. Usually this just
      // means the table doesn't exist yet (it's created in Sprint 1).
      return (_Connection.connected, e.message);
    } catch (e) {
      return (_Connection.unreachable, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: FutureBuilder<(_Connection, String?)>(
        future: _check,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return ListTile(
              leading: const SizedBox.square(
                dimension: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              title: Text(l10n.supabaseStatus),
            );
          }

          final (connection, detail) = snapshot.data!;
          final (icon, color, label) = switch (connection) {
            _Connection.connected => (
                Icons.check_circle,
                Colors.green,
                l10n.supabaseConnected,
              ),
            _Connection.notConfigured => (
                Icons.settings_outlined,
                scheme.outline,
                l10n.supabaseNotConfigured,
              ),
            _Connection.unreachable => (
                Icons.cloud_off,
                scheme.error,
                l10n.supabaseUnreachable,
              ),
          };

          return ListTile(
            leading: Icon(icon, color: color),
            title: Text(l10n.supabaseStatus),
            subtitle: Text(detail == null ? label : '$label\n$detail'),
            isThreeLine: detail != null,
            trailing: IconButton(
              tooltip: l10n.checkAgain,
              icon: const Icon(Icons.refresh),
              onPressed: () => setState(() => _check = _runCheck()),
            ),
          );
        },
      ),
    );
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../config/app_config.dart';
import '../l10n/generated/app_localizations.dart';

/// A thin strip that appears while the phone has no connection, so the
/// user knows the screen is showing saved data. Hidden in demo mode.
class ConnectivityBanner extends StatelessWidget {
  const ConnectivityBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (AppConfig.demo) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final offline = snapshot.data?.every((r) => r == ConnectivityResult.none) ?? false;
        return AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          child: offline
              ? Container(
                  width: double.infinity,
                  color: scheme.tertiaryContainer,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.cloud_off_outlined, size: 18, color: scheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.offlineBanner,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

import '../../../../core/l10n/generated/app_localizations.dart';
import '../../domain/asset.dart';

extension AssetCategoryStyle on AssetCategory {
  String label(AppLocalizations l10n) => switch (this) {
    AssetCategory.laptop => l10n.catLaptop,
    AssetCategory.desktop => l10n.catDesktop,
    AssetCategory.monitor => l10n.catMonitor,
    AssetCategory.printer => l10n.catPrinter,
    AssetCategory.phone => l10n.catPhone,
    AssetCategory.network => l10n.catNetwork,
    AssetCategory.other => l10n.catOther,
  };

  IconData get icon => switch (this) {
    AssetCategory.laptop => Icons.laptop_mac_rounded,
    AssetCategory.desktop => Icons.desktop_windows_outlined,
    AssetCategory.monitor => Icons.monitor_outlined,
    AssetCategory.printer => Icons.print_outlined,
    AssetCategory.phone => Icons.smartphone_outlined,
    AssetCategory.network => Icons.router_outlined,
    AssetCategory.other => Icons.devices_other_outlined,
  };
}

extension AssetStatusStyle on AssetStatus {
  String label(AppLocalizations l10n) => switch (this) {
    AssetStatus.active => l10n.assetStatusActive,
    AssetStatus.inRepair => l10n.assetStatusInRepair,
    AssetStatus.storage => l10n.assetStatusStorage,
    AssetStatus.retired => l10n.assetStatusRetired,
  };

  /// Glyph stage for [StatusTag]: how "alive" the asset is.
  int get stage => switch (this) {
    AssetStatus.active => 3,
    AssetStatus.inRepair => 1,
    AssetStatus.storage => 0,
    AssetStatus.retired => 0,
  };

  Color color(ColorScheme scheme) => switch (this) {
    AssetStatus.active => scheme.primary,
    AssetStatus.inRepair => scheme.tertiary,
    AssetStatus.storage => scheme.secondary,
    AssetStatus.retired => scheme.outline,
  };
}

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../assets/domain/asset.dart';
import '../../../assets/domain/assets_repository.dart';
import '../../data/label_pdf.dart';
import '../../domain/qr_payload.dart';

/// The sticker for one device: its QR code on white, big enough to scan
/// from a distance, with buttons to print it or send it as a PDF.
class AssetQrPage extends StatelessWidget {
  const AssetQrPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.qrTitle)),
      body: FutureBuilder<Asset?>(
        future: sl<AssetsRepository>().getById(assetId),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const LoadingView();
          final asset = snapshot.data;
          if (asset == null) {
            return EmptyView(message: l10n.assetGone, icon: Icons.search_off_outlined);
          }
          return _Sticker(asset: asset);
        },
      ),
    );
  }
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.asset});

  final Asset asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // The sticker is always white with dark ink, in both themes,
        // so a camera can read it from any screen.
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              QrImageView(
                data: QrPayload.encode(asset.code),
                size: 240,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF0E1A2B)),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0E1A2B),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                asset.code,
                style: AppTheme.mono(context, size: 24).copyWith(color: const Color(0xFF0E1A2B)),
              ),
              const SizedBox(height: 4),
              Text(
                asset.name,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(color: const Color(0xFF0E1A2B)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.stickHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.print_outlined),
          label: Text(l10n.printLabels),
          onPressed: () => Printing.layoutPdf(onLayout: (_) => LabelPdf.single(asset), name: asset.code),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          icon: const Icon(Icons.ios_share_rounded),
          label: Text(l10n.shareLabel),
          onPressed: () async =>
              Printing.sharePdf(bytes: await LabelPdf.single(asset), filename: '${asset.code}.pdf'),
        ),
      ],
    );
  }
}

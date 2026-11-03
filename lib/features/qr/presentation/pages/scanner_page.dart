import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../assets/domain/assets_repository.dart';
import '../../../auth/domain/user_role.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/scan_cubit.dart';

/// Scan a device sticker. Where you land depends on your role:
/// employees go straight to "report an issue" for that device,
/// technicians and managers open the device (history, tickets).
class ScannerPage extends StatelessWidget {
  const ScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(create: (_) => sl<ScanCubit>(), child: const _ScannerView());
  }
}

class _ScannerView extends StatefulWidget {
  const _ScannerView();

  @override
  State<_ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<_ScannerView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _torch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  UserRole get _role {
    final state = context.read<AuthCubit>().state;
    return state is Authenticated ? state.user.role : UserRole.employee;
  }

  void _onState(BuildContext context, ScanState state) {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    switch (state.status) {
      case ScanStatus.found:
        final asset = state.asset!;
        context.pushReplacement(
          _role == UserRole.employee ? Routes.reportPath(asset.id) : Routes.assetPath(asset.id),
        );
      case ScanStatus.notOurs:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.scanNotOurs)));
        context.read<ScanCubit>().reset();
      case ScanStatus.notFound:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(l10n.assetNotFoundCode)));
        context.read<ScanCubit>().reset();
      case ScanStatus.error:
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(state.error ?? l10n.somethingWentWrong)));
        context.read<ScanCubit>().reset();
      case ScanStatus.idle || ScanStatus.resolving:
        break;
    }
  }

  Future<void> _enterByHand() async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<ScanCubit>();
    final controller = TextEditingController();
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.enterCode, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: AppTheme.mono(context, size: 18),
              decoration: InputDecoration(hintText: l10n.enterCodeHint),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: Text(l10n.openAction),
            ),
          ],
        ),
      ),
    );
    if (code != null && code.trim().isNotEmpty) await cubit.submit(code);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocListener<ScanCubit, ScanState>(
      listener: _onState,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          title: Text(_role == UserRole.employee ? l10n.scanToReport : l10n.scanTitle),
          actions: [
            IconButton(
              tooltip: l10n.flashlight,
              icon: Icon(_torch ? Icons.flash_on_rounded : Icons.flash_off_rounded),
              onPressed: () {
                _controller.toggleTorch();
                setState(() => _torch = !_torch);
              },
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                final raw = capture.barcodes.firstOrNull?.rawValue;
                if (raw != null) context.read<ScanCubit>().submit(raw);
              },
              errorBuilder: (context, error) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    l10n.cameraOff,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
            const IgnorePointer(child: CustomPaint(painter: _FramePainter())),
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        l10n.scanHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _enterByHand,
                        icon: const Icon(Icons.keyboard_outlined),
                        label: Text(l10n.enterCode),
                      ),
                      if (AppConfig.demo) _DemoScans(onPick: (c) => context.read<ScanCubit>().submit(c)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Demo mode only: an emulator has no stickers to point at, so offer a
/// few device codes to "scan".
class _DemoScans extends StatelessWidget {
  const _DemoScans({required this.onPick});

  final void Function(String code) onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FutureBuilder(
      future: sl<AssetsRepository>().list(limit: 4),
      builder: (context, snapshot) {
        final items = snapshot.data?.items ?? const [];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.simulateScan.toUpperCase(), style: Theme.of(context).textTheme.labelSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in items)
                    ActionChip(
                      label: Text(a.code, style: AppTheme.mono(context, size: 12)),
                      onPressed: () => onPick(a.code),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dimmed camera with a clear square and four corner brackets.
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.width * 0.66;
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height * 0.40),
      width: side,
      height: side,
    );
    final hole = RRect.fromRectAndRadius(rect, const Radius.circular(24));
    final dim = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(hole)
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(dim, Paint()..color = Colors.black.withValues(alpha: 0.55));

    final bracket = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    const len = 34.0;
    for (final corner in [rect.topLeft, rect.topRight, rect.bottomLeft, rect.bottomRight]) {
      final dx = corner.dx == rect.left ? 1.0 : -1.0;
      final dy = corner.dy == rect.top ? 1.0 : -1.0;
      canvas.drawLine(corner, corner + Offset(len * dx, 0), bracket);
      canvas.drawLine(corner, corner + Offset(0, len * dy), bracket);
    }
  }

  @override
  bool shouldRepaint(_FramePainter oldDelegate) => false;
}

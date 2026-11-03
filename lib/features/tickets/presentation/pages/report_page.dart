import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/legend.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/primary_button.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../assets/presentation/widgets/asset_style.dart';
import '../../domain/ticket.dart';
import '../cubit/report_cubit.dart';
import '../widgets/ticket_style.dart';

/// "Report an issue" for one device: a few words, optional photos, a
/// priority. Employees get here by scanning the sticker.
class ReportPage extends StatelessWidget {
  const ReportPage({super.key, required this.assetId});

  final String assetId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<ReportCubit>()..load(assetId),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView();

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  TicketPriority _priority = TicketPriority.medium;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    final cubit = context.read<ReportCubit>();
    try {
      final file = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 82);
      if (file != null) cubit.addPhoto(file.path);
    } on Exception {
      // Permission denied or no camera: the user simply gets no photo.
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<ReportCubit, ReportState>(
      listener: (context, state) {
        final messenger = ScaffoldMessenger.of(context);
        if (state.status == ReportStatus.sent) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(l10n.reportSent)));
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.employeeHome);
          }
        } else if (state.error != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.error!)));
        }
      },
      builder: (context, state) {
        final asset = state.asset;
        return Scaffold(
          appBar: AppBar(title: Text(l10n.reportTitle)),
          body: switch (state.status) {
            ReportStatus.loading => const LoadingView(),
            ReportStatus.notFound || ReportStatus.error => EmptyView(
              message: l10n.assetGone,
              icon: Icons.search_off_outlined,
            ),
            _ => ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                if (asset != null)
                  TagCard(
                    child: Row(
                      children: [
                        Icon(asset.category.icon, size: 28, color: theme.colorScheme.primary),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(asset.code, style: AppTheme.mono(context, size: 12)),
                              Text(asset.name, style: theme.textTheme.titleMedium),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Legend(l10n.whatsWrong),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final quick in [
                            l10n.quickWontTurnOn,
                            l10n.quickSlow,
                            l10n.quickScreen,
                            l10n.quickNetwork,
                            l10n.quickPrinting,
                          ])
                            ActionChip(
                              label: Text(quick),
                              onPressed: () => setState(() => _title.text = quick),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _title,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(labelText: l10n.whatsWrong),
                        validator: (v) => (v ?? '').trim().length < 3 ? l10n.titleRequired : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 6,
                        decoration: InputDecoration(labelText: l10n.describeProblem),
                      ),
                      const SizedBox(height: 20),
                      Legend(l10n.priorityLabel),
                      const SizedBox(height: 8),
                      SegmentedButton<TicketPriority>(
                        showSelectedIcon: false,
                        segments: [
                          for (final p in TicketPriority.values)
                            ButtonSegment(value: p, label: Text(p.label(l10n))),
                        ],
                        selected: {_priority},
                        onSelectionChanged: (s) => setState(() => _priority = s.first),
                      ),
                      const SizedBox(height: 20),
                      Legend(l10n.addPhotos),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          for (final path in state.photos)
                            Padding(
                              padding: const EdgeInsetsDirectional.only(end: 8),
                              child: _Thumb(
                                path: path,
                                onRemove: () => context.read<ReportCubit>().removePhoto(path),
                              ),
                            ),
                          if (state.photos.length < ReportCubit.maxPhotos) ...[
                            _AddPhoto(
                              icon: Icons.photo_camera_outlined,
                              label: l10n.takePhoto,
                              onTap: () => _pick(ImageSource.camera),
                            ),
                            const SizedBox(width: 8),
                            _AddPhoto(
                              icon: Icons.photo_outlined,
                              label: l10n.fromGallery,
                              onTap: () => _pick(ImageSource.gallery),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 28),
                      PrimaryButton(
                        label: l10n.sendReport,
                        icon: Icons.send_rounded,
                        isLoading: state.status == ReportStatus.sending,
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            context.read<ReportCubit>().send(
                              title: _title.text.trim(),
                              description: _description.text.trim(),
                              priority: _priority,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          },
        );
      },
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.path, required this.onRemove});

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(File(path), width: 72, height: 72, fit: BoxFit.cover),
        ),
        PositionedDirectional(
          top: 2,
          end: 2,
          child: InkWell(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 16, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddPhoto extends StatelessWidget {
  const _AddPhoto({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 84,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outline),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: scheme.primary),
            const SizedBox(height: 2),
            Text(label, style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
    );
  }
}

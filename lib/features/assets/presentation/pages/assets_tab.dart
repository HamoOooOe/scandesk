import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/router/routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/punch_ring.dart';
import '../../../../core/widgets/status_tag.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../../auth/domain/user_role.dart';
import '../../domain/asset.dart';
import '../cubit/assets_list_cubit.dart';
import '../widgets/asset_style.dart';

/// The asset list: search, filters and infinite scroll. Each row carries
/// its punch ring, so you can see at a glance what has been serviced.
class AssetsTab extends StatelessWidget {
  const AssetsTab({super.key, required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssetsListCubit>()..load(),
      child: _AssetsView(role: role),
    );
  }
}

class _AssetsView extends StatefulWidget {
  const _AssetsView({required this.role});

  final UserRole role;

  @override
  State<_AssetsView> createState() => _AssetsViewState();
}

class _AssetsViewState extends State<_AssetsView> {
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 400) {
        context.read<AssetsListCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (mounted) context.read<AssetsListCubit>().setText(text);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<AssetsListCubit>();

    return BlocBuilder<AssetsListCubit, AssetsListState>(
      builder: (context, state) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: TextField(
                controller: _search,
                onChanged: _onSearch,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: l10n.searchAssets,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _search.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _search.clear();
                            cubit.setText('');
                            setState(() {});
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                children: [
                  _Chip(
                    label: l10n.filterAll,
                    selected: !state.query.hasFilters,
                    onTap: cubit.clearFilters,
                  ),
                  for (final s in [AssetStatus.active, AssetStatus.inRepair, AssetStatus.storage])
                    _Chip(
                      label: s.label(l10n),
                      selected: state.query.status == s,
                      onTap: () => cubit.setStatus(state.query.status == s ? null : s),
                    ),
                  for (final c in AssetCategory.values.where((c) => c != AssetCategory.other))
                    _Chip(
                      label: c.label(l10n),
                      selected: state.query.category == c,
                      onTap: () => cubit.setCategory(state.query.category == c ? null : c),
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (state.status) {
                AssetsListStatus.loading when state.items.isEmpty => const Center(
                  child: CircularProgressIndicator(),
                ),
                AssetsListStatus.error => ErrorView(message: state.error, onRetry: cubit.load),
                _ when state.items.isEmpty => EmptyView(
                  message: l10n.noAssets,
                  icon: Icons.search_off_outlined,
                  action: state.query.hasFilters
                      ? TextButton(onPressed: cubit.clearFilters, child: Text(l10n.clearFilters))
                      : null,
                ),
                _ => ListView.separated(
                  controller: _scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  itemCount: state.items.length + (state.hasMore ? 1 : 0),
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i >= state.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
                      );
                    }
                    final asset = state.items[i];
                    return AssetRow(
                      asset: asset,
                      punchedMonths: state.punches[asset.id] ?? const {},
                    );
                  },
                ),
              },
            ),
          ],
        );
      },
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
      ),
    );
  }
}

class AssetRow extends StatelessWidget {
  const AssetRow({super.key, required this.asset, required this.punchedMonths});

  final Asset asset;
  final Set<int> punchedMonths;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return TagCard(
      onTap: () => context.push(Routes.assetPath(asset.id)),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          PunchRing(
            punchedMonths: punchedMonths,
            size: 62,
            currentMonth: DateTime.now().month,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 18),
                  child: Text(asset.code, style: AppTheme.mono(context, size: 12)),
                ),
                const SizedBox(height: 2),
                Text(
                  asset.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  asset.assignedTo.isEmpty ? asset.category.label(l10n) : asset.assignedTo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
                if (asset.status != AssetStatus.active) ...[
                  const SizedBox(height: 8),
                  StatusTag(
                    label: asset.status.label(l10n),
                    stage: asset.status.stage,
                    color: asset.status.color(scheme),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

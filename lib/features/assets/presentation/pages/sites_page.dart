import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/tag_card.dart';
import '../../domain/asset.dart';
import '../cubit/sites_cubit.dart';

/// Manager screen: sites, and the rooms and floors inside them.
class SitesPage extends StatelessWidget {
  const SitesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SitesCubit>()..load(),
      child: const _SitesView(),
    );
  }
}

class _SitesView extends StatelessWidget {
  const _SitesView();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return BlocConsumer<SitesCubit, SitesState>(
      listenWhen: (a, b) => b.error != null && a.error != b.error,
      listener: (context, state) => ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error!))),
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: Text(l10n.sitesTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _editSite(context),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(l10n.addSite),
          ),
          body: state.loading
              ? const LoadingView()
              : state.sites.isEmpty
              ? EmptyView(message: l10n.noSites, icon: Icons.apartment_outlined)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  children: [
                    for (final site in state.sites)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TagCard(
                          padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(site.name, style: theme.textTheme.titleLarge),
                                        Text(
                                          [
                                            if (site.city.isNotEmpty) site.city,
                                            l10n.locationsCount(state.locationsOf(site.id).length),
                                          ].join('  ·  '),
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: l10n.editAsset,
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _editSite(context, site: site),
                                  ),
                                  IconButton(
                                    tooltip: l10n.deleteAction,
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _confirmDelete(context, site),
                                  ),
                                ],
                              ),
                              const Divider(),
                              for (final loc in state.locationsOf(site.id))
                                ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsetsDirectional.only(start: 0, end: 4),
                                  leading: const Icon(Icons.meeting_room_outlined),
                                  title: Text(loc.name),
                                  trailing: IconButton(
                                    tooltip: l10n.deleteAction,
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    onPressed: () => context.read<SitesCubit>().deleteLocation(loc.id),
                                  ),
                                  onTap: () => _editLocation(context, site.id, location: loc),
                                ),
                              TextButton.icon(
                                onPressed: () => _editLocation(context, site.id),
                                icon: const Icon(Icons.add_rounded),
                                label: Text(l10n.addLocation),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _editSite(BuildContext context, {Site? site}) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SitesCubit>();
    final result = await _twoFieldDialog(
      context,
      title: site == null ? l10n.addSite : l10n.editAsset,
      first: l10n.siteName,
      second: l10n.cityLabel,
      initialFirst: site?.name ?? '',
      initialSecond: site?.city ?? '',
    );
    if (result != null) {
      await cubit.saveSite(Site(id: site?.id ?? '', name: result.$1, city: result.$2));
    }
  }

  Future<void> _editLocation(BuildContext context, String siteId, {Location? location}) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SitesCubit>();
    final result = await _twoFieldDialog(
      context,
      title: location == null ? l10n.addLocation : l10n.editAsset,
      first: l10n.locationName,
      initialFirst: location?.name ?? '',
    );
    if (result != null) {
      await cubit.saveLocation(Location(id: location?.id ?? '', siteId: siteId, name: result.$1));
    }
  }

  Future<void> _confirmDelete(BuildContext context, Site site) async {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<SitesCubit>();
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site.name),
        content: Text(l10n.deleteSiteConfirm),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.cancelAction)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.deleteAction),
          ),
        ],
      ),
    );
    if (yes ?? false) await cubit.deleteSite(site.id);
  }

  Future<(String, String)?> _twoFieldDialog(
    BuildContext context, {
    required String title,
    required String first,
    String? second,
    String initialFirst = '',
    String initialSecond = '',
  }) {
    final l10n = AppLocalizations.of(context);
    final a = TextEditingController(text: initialFirst);
    final b = TextEditingController(text: initialSecond);
    return showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: a, autofocus: true, decoration: InputDecoration(labelText: first)),
            if (second != null) ...[
              const SizedBox(height: 12),
              TextField(controller: b, decoration: InputDecoration(labelText: second)),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelAction)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 44)),
            onPressed: () {
              if (a.text.trim().isNotEmpty) Navigator.pop(context, (a.text.trim(), b.text.trim()));
            },
            child: Text(l10n.saveAction),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:printing/printing.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/generated/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../assets/domain/asset.dart';
import '../../../assets/presentation/cubit/assets_list_cubit.dart';
import '../../../assets/presentation/widgets/asset_style.dart';
import '../../data/label_pdf.dart';

/// Manager screen: tick the devices that need a sticker and print an A4
/// sheet of QR labels.
class LabelSheetPage extends StatelessWidget {
  const LabelSheetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AssetsListCubit>()..load(),
      child: const _SheetView(),
    );
  }
}

class _SheetView extends StatefulWidget {
  const _SheetView();

  @override
  State<_SheetView> createState() => _SheetViewState();
}

class _SheetViewState extends State<_SheetView> {
  // Keyed by id, so a ticked device stays ticked when search hides it.
  final Map<String, Asset> _selected = {};
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels > _scroll.position.maxScrollExtent - 300) {
        context.read<AssetsListCubit>().loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<AssetsListCubit, AssetsListState>(
      builder: (context, state) {
        final allTicked = state.items.isNotEmpty && state.items.every((a) => _selected.containsKey(a.id));
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.labelSheetTitle),
            actions: [
              TextButton(
                onPressed: () => setState(() {
                  if (allTicked) {
                    for (final a in state.items) {
                      _selected.remove(a.id);
                    }
                  } else {
                    for (final a in state.items) {
                      _selected[a.id] = a;
                    }
                  }
                }),
                child: Text(
                  l10n.selectAll,
                  style: TextStyle(color: Theme.of(context).appBarTheme.foregroundColor),
                ),
              ),
            ],
          ),
          body: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.only(bottom: 100),
            itemCount: state.items.length,
            itemBuilder: (context, i) {
              final a = state.items[i];
              return CheckboxListTile(
                value: _selected.containsKey(a.id),
                onChanged: (v) => setState(() {
                  if (v ?? false) {
                    _selected[a.id] = a;
                  } else {
                    _selected.remove(a.id);
                  }
                }),
                secondary: Icon(a.category.icon),
                title: Text(a.name),
                subtitle: Text(a.code, style: AppTheme.mono(context, size: 12)),
              );
            },
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _selected.isEmpty
                    ? null
                    : () => Printing.layoutPdf(
                        onLayout: (_) => LabelPdf.sheet(_selected.values.toList()),
                        name: 'scandesk-labels',
                      ),
                icon: const Icon(Icons.print_outlined),
                label: Text('${l10n.printSheet}  ·  ${l10n.selectedCount(_selected.length)}'),
              ),
            ),
          ),
        );
      },
    );
  }
}

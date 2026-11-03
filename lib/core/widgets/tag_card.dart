import 'package:flutter/material.dart';

/// The standard surface: a piece of tag stock with its lanyard hole.
///
/// [flagged] is the "changed since you last looked" state: the card stays
/// tinted until the user opens it, so a changed row never just vanishes
/// into the list.
class TagCard extends StatelessWidget {
  const TagCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.flagged = false,
    this.hole = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final bool flagged;
  final bool hole;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = flagged
        ? Color.alphaBlend(scheme.tertiary.withValues(alpha: 0.09), scheme.surfaceContainerLowest)
        : scheme.surfaceContainerLowest;

    return Material(
      color: fill,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: flagged ? scheme.tertiary.withValues(alpha: 0.55) : scheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(padding: padding, child: child),
            if (hole)
              PositionedDirectional(
                top: 9,
                end: 10,
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: scheme.outlineVariant),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

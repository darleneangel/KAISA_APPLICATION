import 'package:flutter/material.dart';

/// Shared responsive layout rules for BOTH Android and Flutter web.
/// These widgets only arrange their children; they do not own navigation,
/// credentials, Supabase requests, QR payloads, or screen state.
abstract final class KaisaBreakpoints {
  static const double mobile = 600;
  static const double desktop = 1024;
  static const double maxContentWidth = 1240;

  static bool isMobile(double width) => width < mobile;
  static bool isDesktop(double width) => width >= desktop;
  static double horizontalInset(double width) => width < mobile ? 16 : 28;
}

/// Constrains content to a consistent readable width on desktop while using
/// the same spacing and visual components on phones and mobile-sized browsers.
/// Add around a *page's content*, not around the existing navigation shell.
class KaisaAdaptiveContent extends StatelessWidget {
  const KaisaAdaptiveContent({
    super.key,
    required this.child,
    this.maxWidth = KaisaBreakpoints.maxContentWidth,
    this.verticalPadding = 16,
  });

  final Widget child;
  final double maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final inset = KaisaBreakpoints.horizontalInset(availableWidth);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: inset,
                vertical: verticalPadding,
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// Responsive card layout with identical Android/web styling.
/// Phones show one column; tablets two; wide browser windows three.
/// Keep using existing data-backed card widgets as children.
class KaisaAdaptiveCardGrid extends StatelessWidget {
  const KaisaAdaptiveCardGrid({
    super.key,
    required this.children,
    this.spacing = 14,
    this.runSpacing = 14,
    this.maxColumns = 3,
  });

  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final int maxColumns;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final proposedColumns = width < KaisaBreakpoints.mobile
            ? 1
            : width < KaisaBreakpoints.desktop
            ? 2
            : 3;
        final columns = proposedColumns.clamp(
          1,
          maxColumns < 1 ? 1 : maxColumns,
        );
        final itemWidth = (width - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(growable: false),
        );
      },
    );
  }
}

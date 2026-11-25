import 'package:flutter/material.dart';
import 'kaisa_resident_design.dart';
import 'kaisa_resident_hero.dart';

class KaisaHero extends StatelessWidget {
  const KaisaHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.eyebrow,
  });
  final String title, subtitle, eyebrow;
  final IconData icon;
  @override
  Widget build(BuildContext context) => KaisaResidentHero(
    eyebrow: eyebrow,
    title: title,
    subtitle: subtitle,
    icon: icon,
  );
}

class KaisaPageLayout extends StatelessWidget {
  const KaisaPageLayout({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        c.maxWidth < 600 ? 16 : 26,
        24,
        c.maxWidth < 600 ? 16 : 26,
        65,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    ),
  );
}

class KaisaTile extends StatelessWidget {
  const KaisaTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.trailing,
  });
  final String title, subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: KaisaResidentDesign.border),
    ),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(19),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: KaisaResidentDesign.mint,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: KaisaResidentDesign.forest, size: 27),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KaisaTypography.heading(
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: KaisaTypography.body(
                      TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ],
        ),
      ),
    ),
  );
}

class KaisaResponsiveGrid extends StatelessWidget {
  const KaisaResponsiveGrid({
    super.key,
    required this.children,
    this.minWidth = 320,
  });
  final List<Widget> children;
  final double minWidth;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final columns = ((c.maxWidth + 14) / (minWidth.clamp(120.0, 1440.0) + 14))
          .floor()
          .clamp(1, 3)
          .toInt();
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          mainAxisExtent: 155,
        ),
        itemCount: children.length,
        itemBuilder: (context, i) => children[i],
      );
    },
  );
}

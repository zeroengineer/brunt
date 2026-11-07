import 'package:flutter/material.dart';

import 'tokens.dart';

/// Dark surface card (reference white review cards, dark version).
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(BSpace.l), this.onTap, this.color, this.borderColor, this.radius = BRadius.card});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? BColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? BColors.border),
      ),
      child: child,
    );
    if (onTap == null) return box;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: BColors.primary.withValues(alpha: 0.15),
        highlightColor: BColors.surfaceRaised.withValues(alpha: 0.5),
        child: box,
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(4, BSpace.xl, 4, BSpace.m)});

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(child: Semantics(header: true, child: Text(title, style: BText.h2.copyWith(fontSize: 17)))),
        ?trailing,
      ]),
    );
  }
}

/// Round icon badge used in list rows.
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, required this.color, this.size = 40});

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.16), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.48, color: color),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: BSpace.xxl, horizontal: BSpace.xl),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IconBadge(icon: icon, color: BColors.primaryLight, size: 56),
        const SizedBox(height: BSpace.l),
        Text(title, style: BText.h2.copyWith(fontSize: 17), textAlign: TextAlign.center),
        if (message != null) ...[
          const SizedBox(height: BSpace.s),
          Text(message!, style: BText.bodyMuted, textAlign: TextAlign.center),
        ],
        if (action != null) ...[const SizedBox(height: BSpace.l), action!],
      ]),
    );
  }
}

/// Inline banner for warnings (gap check, cash run-out, card limit).
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, required this.color, this.icon, this.title, this.onTap});

  final String message;
  final String? title;
  final Color color;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (icon != null) ...[Icon(icon, size: 20, color: color), const SizedBox(width: 12)],
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (title != null) ...[Text(title!, style: BText.label.copyWith(color: color)), const SizedBox(height: 3)],
            Text(message, style: BText.body.copyWith(fontSize: 13.5)),
          ]),
        ),
      ]),
    );
  }
}

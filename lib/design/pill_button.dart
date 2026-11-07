import 'package:flutter/material.dart';

import 'tokens.dart';

enum PillVariant { primary, outline, soft }

/// Pill buttons from the reference: Active / Pressed / Disabled, filled + outline.
class PillButton extends StatefulWidget {
  const PillButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = PillVariant.primary,
    this.icon,
    this.expand = false,
    this.dense = false,
    this.danger = false,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final PillVariant variant;
  final IconData? icon;
  final bool expand;
  final bool dense;
  final bool danger;
  final bool busy;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.busy;
    final accent = widget.danger ? BColors.danger : BColors.primary;
    Color bg;
    Color fg;
    Color border;
    switch (widget.variant) {
      case PillVariant.primary:
        if (!enabled) {
          bg = BColors.disabled;
          fg = BColors.text.withValues(alpha: 0.6);
        } else if (_pressed) {
          bg = widget.danger ? BColors.danger.withValues(alpha: 0.7) : BColors.primarySoft;
          fg = widget.danger ? BColors.text : BColors.primary;
        } else {
          bg = accent;
          fg = BColors.text;
        }
        border = Colors.transparent;
      case PillVariant.outline:
        bg = _pressed && enabled ? BColors.surfaceRaised : Colors.transparent;
        fg = enabled ? (widget.danger ? BColors.danger : (_pressed ? BColors.text : BColors.primaryLight)) : BColors.textMuted;
        border = enabled ? (widget.danger ? BColors.danger : (_pressed ? BColors.text : accent)) : BColors.borderStrong;
      case PillVariant.soft:
        bg = enabled ? (_pressed ? BColors.surfaceRaised : BColors.surface) : BColors.surface.withValues(alpha: 0.5);
        fg = enabled ? (widget.danger ? BColors.danger : BColors.text) : BColors.textMuted;
        border = BColors.border;
    }

    final h = widget.dense ? 36.0 : 52.0;
    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.busy)
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (widget.icon != null)
          Icon(widget.icon, size: widget.dense ? 16 : 18, color: fg),
        if (widget.busy || widget.icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(widget.label,
              overflow: TextOverflow.ellipsis,
              style: BText.label.copyWith(color: fg, fontSize: widget.dense ? 13 : 15, fontWeight: FontWeight.w700)),
        ),
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTap: enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: h,
          padding: EdgeInsets.symmetric(horizontal: widget.dense ? 10 : 22),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(BRadius.pill),
            border: Border.all(color: border, width: 1.2),
          ),
          child: content,
        ),
      ),
    );
  }
}

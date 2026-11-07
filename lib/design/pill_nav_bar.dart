import 'package:flutter/material.dart';

import 'tokens.dart';

class NavItem {
  const NavItem(this.icon, this.label);
  final IconData icon;
  final String label;
}

/// Bottom icon nav with an active pill (reference bottom-right block).
class PillNavBar extends StatelessWidget {
  const PillNavBar({super.key, required this.items, required this.selected, required this.onChanged, this.action});

  final List<NavItem> items;
  final int selected;
  final ValueChanged<int> onChanged;

  /// Optional round action at the right end (BRUNT's + button lives here so it never covers content).
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: BSpace.gutter),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: BColors.surface.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(BRadius.pill),
            border: Border.all(color: BColors.borderStrong),
            boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 24, offset: Offset(0, 8))],
          ),
          child: Row(children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                flex: i == selected ? 9 : 5,
                child: Semantics(
                  selected: i == selected,
                  button: true,
                  label: items[i].label,
                  excludeSemantics: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      decoration: BoxDecoration(
                        color: i == selected ? BColors.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(BRadius.pill),
                      ),
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(items[i].icon, size: 21, color: i == selected ? BColors.text : BColors.textMuted),
                        if (i == selected) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(items[i].label,
                                overflow: TextOverflow.clip, softWrap: false, style: BText.label.copyWith(fontSize: 13)),
                          ),
                        ],
                      ]),
                    ),
                  ),
                ),
              ),
            if (action != null) ...[const SizedBox(width: 6), action!],
          ]),
        ),
      ),
    );
  }
}

/// Round primary button sized for the nav pill.
class NavAction extends StatelessWidget {
  const NavAction({super.key, required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: BColors.primaryLight,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(width: 50, height: 50, child: Icon(icon, size: 24, color: const Color(0xFF0B1A2E))),
        ),
      ),
    );
  }
}

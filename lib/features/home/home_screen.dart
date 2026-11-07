import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/providers.dart';
import '../../core/dates.dart';
import '../../design/design.dart';
import '../dashboard/dashboard_view.dart';
import '../history/history_screen.dart';
import '../insights/insights_screen.dart';
import '../plan/plan_screen.dart';

/// Home: top segmented tabs Overview · Plan · Insights · History (spec §11.4).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _tab = 0;
  final _visited = <int>{0};

  @override
  Widget build(BuildContext context) {
    final month = ref.watch(monthProvider).value;
    return SafeArea(
      bottom: false,
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(BSpace.gutter + 4, 10, 8, 0),
          child: Row(children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(month == null ? 'BRUNT' : Dates.monthLabel(month.yearMonth), style: BText.h1),
              ),
            ),
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(LucideIcons.settings, color: BColors.text),
            ),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(BSpace.gutter, 12, BSpace.gutter, 8),
          child: SegmentTabs(
            items: const [
              SegmentItem('Overview', LucideIcons.layoutGrid),
              SegmentItem('Plan', LucideIcons.calendarDays),
              SegmentItem('Insights', LucideIcons.chartColumn),
              SegmentItem('History', LucideIcons.history),
            ],
            selected: _tab,
            onChanged: (i) => setState(() {
              _tab = i;
              _visited.add(i);
            }),
          ),
        ),
        Expanded(
          // Lazy: a tab is only built once it has been visited, then kept alive.
          child: IndexedStack(index: _tab, children: [
            for (var i = 0; i < 4; i++)
              _visited.contains(i)
                  ? const [DashboardView(), PlanView(), InsightsScreen(), HistoryScreen()][i]
                  : const SizedBox.shrink(),
          ]),
        ),
      ]),
    );
  }
}

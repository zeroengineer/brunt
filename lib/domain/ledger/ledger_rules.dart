import '../../core/constants.dart';

/// Balance rules from spec §8, as a pure function.
///
/// Returns the change applied to each account's cached `balance` column.
/// For credit cards `balance` is the **outstanding due**, so a card spend *increases* it.
Map<int, int> balanceDeltas({
  required TxType type,
  required int amount,
  required int accountId,
  required bool accountIsCard,
  int? toAccountId,
  bool toIsCard = false,
}) {
  final d = <int, int>{};
  void add(int id, int v) => d[id] = (d[id] ?? 0) + v;

  switch (type) {
    case TxType.expense:
      add(accountId, accountIsCard ? amount : -amount);
    case TxType.salary:
    case TxType.extraIncome:
      // Income into a card (e.g. a refund) reduces the outstanding.
      add(accountId, accountIsCard ? -amount : amount);
    case TxType.transfer:
      if (toAccountId == null) throw ArgumentError('transfer needs toAccountId');
      add(accountId, accountIsCard ? amount : -amount); // card as source = cash advance
      add(toAccountId, toIsCard ? -amount : amount); // paying a card bill reduces outstanding
    case TxType.adjustment:
      // amount is the signed difference (real − recorded).
      add(accountId, amount);
  }
  d.removeWhere((_, v) => v == 0);
  return d;
}

/// Whether the entry counts as spending in stats (transfers & adjustments never do).
bool countsAsSpending(TxType t) => t == TxType.expense;

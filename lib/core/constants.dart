/// Domain enums shared by data, domain and UI layers.
library;

/// The money stack tiers. Order is fixed: it drives the projection.
enum Tier {
  income(0, 'Income'),
  priority(1, 'Priority'),
  savings(2, 'Savings'),
  fixed(3, 'Fixed bills'),
  daily(4, 'Daily'),
  variable(5, 'Variable');

  const Tier(this.value, this.label);
  final int value;
  final String label;

  static Tier of(int v) => Tier.values.firstWhere((t) => t.value == v, orElse: () => Tier.variable);

  /// Tiers that are planned monthly commitments.
  bool get isCommitted => this == priority || this == savings || this == fixed;
}

enum AccountType {
  cash('cash', 'Cash'),
  bank('bank', 'Bank'),
  upi('upi', 'UPI'),
  wallet('wallet', 'Wallet'),
  creditCard('credit_card', 'Credit card'),
  savings('savings', 'Savings'),

  /// Money borrowed from someone (system account, balance = what you still owe).
  loan('loan', 'Borrowed'),

  /// Money lent to someone (system account, balance = what is owed to you).
  lent('lent', 'Lent out'),

  /// Money kept aside inside a bank (system account linked to that bank). Never spendable;
  /// shown as part of the bank's balance.
  reserve('reserve', 'Reserve');

  const AccountType(this.code, this.label);
  final String code;
  final String label;

  static AccountType of(String c) => AccountType.values.firstWhere((t) => t.code == c, orElse: () => AccountType.cash);

  bool get holdsBalance => this != upi;
  bool get isCard => this == creditCard;

  /// Balance is an amount owed: spends/borrowing raise it, payments lower it.
  bool get isLiability => this == creditCard || this == loan;

  /// Created by BRUNT on demand, never offered in "Add account".
  bool get isSystem => this == loan || this == lent || this == reserve;
  bool get defaultSpendable => this == cash || this == bank || this == wallet;
}

enum TxType {
  expense('expense'),
  extraIncome('extra_income'),
  salary('salary'),
  transfer('transfer'),
  adjustment('adjustment');

  const TxType(this.code);
  final String code;

  static TxType of(String c) => TxType.values.firstWhere((t) => t.code == c, orElse: () => TxType.expense);

  bool get isIncome => this == extraIncome || this == salary;

  /// Transfers and adjustments are never spending.
  bool get countsAsSpending => this == expense;
}

enum Frequency {
  monthly('monthly', 'Monthly'),
  daily('daily', 'Daily'),
  oneTime('one_time', 'One time');

  const Frequency(this.code, this.label);
  final String code;
  final String label;

  static Frequency of(String c) => Frequency.values.firstWhere((t) => t.code == c, orElse: () => Frequency.monthly);
}

enum PlannedStatus {
  pending('pending', 'Pending'),
  paid('paid', 'Paid'),
  skipped('skipped', 'Skipped');

  const PlannedStatus(this.code, this.label);
  final String code;
  final String label;

  static PlannedStatus of(String c) => PlannedStatus.values.firstWhere((t) => t.code == c, orElse: () => PlannedStatus.pending);
}

enum DailyLogState {
  confirmed('confirmed'),
  edited('edited'),
  skipped('skipped');

  const DailyLogState(this.code);
  final String code;

  static DailyLogState of(String c) => DailyLogState.values.firstWhere((t) => t.code == c, orElse: () => DailyLogState.confirmed);
}

/// Settings keys (settings table, inside the encrypted DB).
abstract final class SettingKeys {
  static const salaryAmount = 'salary_amount';
  static const salaryUsualDay = 'salary_usual_day';
  static const salaryLatestDay = 'salary_latest_day';
  static const salaryAccountId = 'salary_account_id';
  static const reminderTime = 'reminder_time'; // 'HH:mm'
  static const remindersEnabled = 'reminders_enabled';
  static const dueRemindersEnabled = 'due_reminders_enabled';
  static const comfortThresholdPct = 'comfort_threshold_pct';
  static const variableBudget = 'variable_budget';
  static const autoLock = 'auto_lock'; // immediate | 1m | 5m
  static const onboardedAt = 'onboarded_at'; // ISO date tracking starts
  static const lastAccountForCategory = 'last_account_cat_'; // + categoryId
  static const cardWarnPct = 'card_warn_pct';
}

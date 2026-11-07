// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $AccountsTable extends Accounts
    with TableInfo<$AccountsTable, AccountRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startingBalanceMeta = const VerificationMeta(
    'startingBalance',
  );
  @override
  late final GeneratedColumn<int> startingBalance = GeneratedColumn<int>(
    'starting_balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _balanceMeta = const VerificationMeta(
    'balance',
  );
  @override
  late final GeneratedColumn<int> balance = GeneratedColumn<int>(
    'balance',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _linkedAccountIdMeta = const VerificationMeta(
    'linkedAccountId',
  );
  @override
  late final GeneratedColumn<int> linkedAccountId = GeneratedColumn<int>(
    'linked_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _includeInSpendableMeta =
      const VerificationMeta('includeInSpendable');
  @override
  late final GeneratedColumn<bool> includeInSpendable = GeneratedColumn<bool>(
    'include_in_spendable',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("include_in_spendable" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _creditLimitMeta = const VerificationMeta(
    'creditLimit',
  );
  @override
  late final GeneratedColumn<int> creditLimit = GeneratedColumn<int>(
    'credit_limit',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statementDayMeta = const VerificationMeta(
    'statementDay',
  );
  @override
  late final GeneratedColumn<int> statementDay = GeneratedColumn<int>(
    'statement_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    type,
    icon,
    color,
    startingBalance,
    balance,
    linkedAccountId,
    includeInSpendable,
    creditLimit,
    statementDay,
    dueDay,
    sortOrder,
    archived,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'accounts';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('starting_balance')) {
      context.handle(
        _startingBalanceMeta,
        startingBalance.isAcceptableOrUnknown(
          data['starting_balance']!,
          _startingBalanceMeta,
        ),
      );
    }
    if (data.containsKey('balance')) {
      context.handle(
        _balanceMeta,
        balance.isAcceptableOrUnknown(data['balance']!, _balanceMeta),
      );
    }
    if (data.containsKey('linked_account_id')) {
      context.handle(
        _linkedAccountIdMeta,
        linkedAccountId.isAcceptableOrUnknown(
          data['linked_account_id']!,
          _linkedAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('include_in_spendable')) {
      context.handle(
        _includeInSpendableMeta,
        includeInSpendable.isAcceptableOrUnknown(
          data['include_in_spendable']!,
          _includeInSpendableMeta,
        ),
      );
    }
    if (data.containsKey('credit_limit')) {
      context.handle(
        _creditLimitMeta,
        creditLimit.isAcceptableOrUnknown(
          data['credit_limit']!,
          _creditLimitMeta,
        ),
      );
    }
    if (data.containsKey('statement_day')) {
      context.handle(
        _statementDayMeta,
        statementDay.isAcceptableOrUnknown(
          data['statement_day']!,
          _statementDayMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AccountRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      startingBalance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}starting_balance'],
      )!,
      balance: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}balance'],
      )!,
      linkedAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}linked_account_id'],
      ),
      includeInSpendable: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}include_in_spendable'],
      )!,
      creditLimit: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}credit_limit'],
      ),
      statementDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}statement_day'],
      ),
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      ),
    );
  }

  @override
  $AccountsTable createAlias(String alias) {
    return $AccountsTable(attachedDatabase, alias);
  }
}

class AccountRow extends DataClass implements Insertable<AccountRow> {
  final int id;
  final String name;
  final String type;
  final String? icon;
  final String? color;
  final int startingBalance;

  /// Cached live balance; for cards this is the outstanding due.
  final int balance;
  final int? linkedAccountId;
  final bool includeInSpendable;
  final int? creditLimit;
  final int? statementDay;
  final int? dueDay;
  final int sortOrder;
  final bool archived;
  final String? createdAt;
  const AccountRow({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.startingBalance,
    required this.balance,
    this.linkedAccountId,
    required this.includeInSpendable,
    this.creditLimit,
    this.statementDay,
    this.dueDay,
    required this.sortOrder,
    required this.archived,
    this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['starting_balance'] = Variable<int>(startingBalance);
    map['balance'] = Variable<int>(balance);
    if (!nullToAbsent || linkedAccountId != null) {
      map['linked_account_id'] = Variable<int>(linkedAccountId);
    }
    map['include_in_spendable'] = Variable<bool>(includeInSpendable);
    if (!nullToAbsent || creditLimit != null) {
      map['credit_limit'] = Variable<int>(creditLimit);
    }
    if (!nullToAbsent || statementDay != null) {
      map['statement_day'] = Variable<int>(statementDay);
    }
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    if (!nullToAbsent || createdAt != null) {
      map['created_at'] = Variable<String>(createdAt);
    }
    return map;
  }

  AccountsCompanion toCompanion(bool nullToAbsent) {
    return AccountsCompanion(
      id: Value(id),
      name: Value(name),
      type: Value(type),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      startingBalance: Value(startingBalance),
      balance: Value(balance),
      linkedAccountId: linkedAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(linkedAccountId),
      includeInSpendable: Value(includeInSpendable),
      creditLimit: creditLimit == null && nullToAbsent
          ? const Value.absent()
          : Value(creditLimit),
      statementDay: statementDay == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDay),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
      createdAt: createdAt == null && nullToAbsent
          ? const Value.absent()
          : Value(createdAt),
    );
  }

  factory AccountRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      type: serializer.fromJson<String>(json['type']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      startingBalance: serializer.fromJson<int>(json['startingBalance']),
      balance: serializer.fromJson<int>(json['balance']),
      linkedAccountId: serializer.fromJson<int?>(json['linkedAccountId']),
      includeInSpendable: serializer.fromJson<bool>(json['includeInSpendable']),
      creditLimit: serializer.fromJson<int?>(json['creditLimit']),
      statementDay: serializer.fromJson<int?>(json['statementDay']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
      createdAt: serializer.fromJson<String?>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'type': serializer.toJson<String>(type),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'startingBalance': serializer.toJson<int>(startingBalance),
      'balance': serializer.toJson<int>(balance),
      'linkedAccountId': serializer.toJson<int?>(linkedAccountId),
      'includeInSpendable': serializer.toJson<bool>(includeInSpendable),
      'creditLimit': serializer.toJson<int?>(creditLimit),
      'statementDay': serializer.toJson<int?>(statementDay),
      'dueDay': serializer.toJson<int?>(dueDay),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
      'createdAt': serializer.toJson<String?>(createdAt),
    };
  }

  AccountRow copyWith({
    int? id,
    String? name,
    String? type,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? startingBalance,
    int? balance,
    Value<int?> linkedAccountId = const Value.absent(),
    bool? includeInSpendable,
    Value<int?> creditLimit = const Value.absent(),
    Value<int?> statementDay = const Value.absent(),
    Value<int?> dueDay = const Value.absent(),
    int? sortOrder,
    bool? archived,
    Value<String?> createdAt = const Value.absent(),
  }) => AccountRow(
    id: id ?? this.id,
    name: name ?? this.name,
    type: type ?? this.type,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    startingBalance: startingBalance ?? this.startingBalance,
    balance: balance ?? this.balance,
    linkedAccountId: linkedAccountId.present
        ? linkedAccountId.value
        : this.linkedAccountId,
    includeInSpendable: includeInSpendable ?? this.includeInSpendable,
    creditLimit: creditLimit.present ? creditLimit.value : this.creditLimit,
    statementDay: statementDay.present ? statementDay.value : this.statementDay,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
    createdAt: createdAt.present ? createdAt.value : this.createdAt,
  );
  AccountRow copyWithCompanion(AccountsCompanion data) {
    return AccountRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      type: data.type.present ? data.type.value : this.type,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      startingBalance: data.startingBalance.present
          ? data.startingBalance.value
          : this.startingBalance,
      balance: data.balance.present ? data.balance.value : this.balance,
      linkedAccountId: data.linkedAccountId.present
          ? data.linkedAccountId.value
          : this.linkedAccountId,
      includeInSpendable: data.includeInSpendable.present
          ? data.includeInSpendable.value
          : this.includeInSpendable,
      creditLimit: data.creditLimit.present
          ? data.creditLimit.value
          : this.creditLimit,
      statementDay: data.statementDay.present
          ? data.statementDay.value
          : this.statementDay,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('startingBalance: $startingBalance, ')
          ..write('balance: $balance, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('includeInSpendable: $includeInSpendable, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    type,
    icon,
    color,
    startingBalance,
    balance,
    linkedAccountId,
    includeInSpendable,
    creditLimit,
    statementDay,
    dueDay,
    sortOrder,
    archived,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.type == this.type &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.startingBalance == this.startingBalance &&
          other.balance == this.balance &&
          other.linkedAccountId == this.linkedAccountId &&
          other.includeInSpendable == this.includeInSpendable &&
          other.creditLimit == this.creditLimit &&
          other.statementDay == this.statementDay &&
          other.dueDay == this.dueDay &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived &&
          other.createdAt == this.createdAt);
}

class AccountsCompanion extends UpdateCompanion<AccountRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<String> type;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int> startingBalance;
  final Value<int> balance;
  final Value<int?> linkedAccountId;
  final Value<bool> includeInSpendable;
  final Value<int?> creditLimit;
  final Value<int?> statementDay;
  final Value<int?> dueDay;
  final Value<int> sortOrder;
  final Value<bool> archived;
  final Value<String?> createdAt;
  const AccountsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.type = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.startingBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.includeInSpendable = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  AccountsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required String type,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.startingBalance = const Value.absent(),
    this.balance = const Value.absent(),
    this.linkedAccountId = const Value.absent(),
    this.includeInSpendable = const Value.absent(),
    this.creditLimit = const Value.absent(),
    this.statementDay = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
    this.createdAt = const Value.absent(),
  }) : name = Value(name),
       type = Value(type);
  static Insertable<AccountRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? type,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? startingBalance,
    Expression<int>? balance,
    Expression<int>? linkedAccountId,
    Expression<bool>? includeInSpendable,
    Expression<int>? creditLimit,
    Expression<int>? statementDay,
    Expression<int>? dueDay,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (type != null) 'type': type,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (startingBalance != null) 'starting_balance': startingBalance,
      if (balance != null) 'balance': balance,
      if (linkedAccountId != null) 'linked_account_id': linkedAccountId,
      if (includeInSpendable != null)
        'include_in_spendable': includeInSpendable,
      if (creditLimit != null) 'credit_limit': creditLimit,
      if (statementDay != null) 'statement_day': statementDay,
      if (dueDay != null) 'due_day': dueDay,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  AccountsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String>? type,
    Value<String?>? icon,
    Value<String?>? color,
    Value<int>? startingBalance,
    Value<int>? balance,
    Value<int?>? linkedAccountId,
    Value<bool>? includeInSpendable,
    Value<int?>? creditLimit,
    Value<int?>? statementDay,
    Value<int?>? dueDay,
    Value<int>? sortOrder,
    Value<bool>? archived,
    Value<String?>? createdAt,
  }) {
    return AccountsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      startingBalance: startingBalance ?? this.startingBalance,
      balance: balance ?? this.balance,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      includeInSpendable: includeInSpendable ?? this.includeInSpendable,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDay: statementDay ?? this.statementDay,
      dueDay: dueDay ?? this.dueDay,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (startingBalance.present) {
      map['starting_balance'] = Variable<int>(startingBalance.value);
    }
    if (balance.present) {
      map['balance'] = Variable<int>(balance.value);
    }
    if (linkedAccountId.present) {
      map['linked_account_id'] = Variable<int>(linkedAccountId.value);
    }
    if (includeInSpendable.present) {
      map['include_in_spendable'] = Variable<bool>(includeInSpendable.value);
    }
    if (creditLimit.present) {
      map['credit_limit'] = Variable<int>(creditLimit.value);
    }
    if (statementDay.present) {
      map['statement_day'] = Variable<int>(statementDay.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('type: $type, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('startingBalance: $startingBalance, ')
          ..write('balance: $balance, ')
          ..write('linkedAccountId: $linkedAccountId, ')
          ..write('includeInSpendable: $includeInSpendable, ')
          ..write('creditLimit: $creditLimit, ')
          ..write('statementDay: $statementDay, ')
          ..write('dueDay: $dueDay, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $MonthsTable extends Months with TableInfo<$MonthsTable, MonthRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _yearMonthMeta = const VerificationMeta(
    'yearMonth',
  );
  @override
  late final GeneratedColumn<String> yearMonth = GeneratedColumn<String>(
    'year_month',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _salaryExpectedMeta = const VerificationMeta(
    'salaryExpected',
  );
  @override
  late final GeneratedColumn<int> salaryExpected = GeneratedColumn<int>(
    'salary_expected',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _salaryAccountIdMeta = const VerificationMeta(
    'salaryAccountId',
  );
  @override
  late final GeneratedColumn<int> salaryAccountId = GeneratedColumn<int>(
    'salary_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _salaryReceivedMeta = const VerificationMeta(
    'salaryReceived',
  );
  @override
  late final GeneratedColumn<int> salaryReceived = GeneratedColumn<int>(
    'salary_received',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _salaryReceivedDateMeta =
      const VerificationMeta('salaryReceivedDate');
  @override
  late final GeneratedColumn<String> salaryReceivedDate =
      GeneratedColumn<String>(
        'salary_received_date',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _salaryPendingCarriedMeta =
      const VerificationMeta('salaryPendingCarried');
  @override
  late final GeneratedColumn<bool> salaryPendingCarried = GeneratedColumn<bool>(
    'salary_pending_carried',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("salary_pending_carried" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('open'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    yearMonth,
    salaryExpected,
    salaryAccountId,
    salaryReceived,
    salaryReceivedDate,
    salaryPendingCarried,
    status,
    version,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'months';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('year_month')) {
      context.handle(
        _yearMonthMeta,
        yearMonth.isAcceptableOrUnknown(data['year_month']!, _yearMonthMeta),
      );
    } else if (isInserting) {
      context.missing(_yearMonthMeta);
    }
    if (data.containsKey('salary_expected')) {
      context.handle(
        _salaryExpectedMeta,
        salaryExpected.isAcceptableOrUnknown(
          data['salary_expected']!,
          _salaryExpectedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_salaryExpectedMeta);
    }
    if (data.containsKey('salary_account_id')) {
      context.handle(
        _salaryAccountIdMeta,
        salaryAccountId.isAcceptableOrUnknown(
          data['salary_account_id']!,
          _salaryAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('salary_received')) {
      context.handle(
        _salaryReceivedMeta,
        salaryReceived.isAcceptableOrUnknown(
          data['salary_received']!,
          _salaryReceivedMeta,
        ),
      );
    }
    if (data.containsKey('salary_received_date')) {
      context.handle(
        _salaryReceivedDateMeta,
        salaryReceivedDate.isAcceptableOrUnknown(
          data['salary_received_date']!,
          _salaryReceivedDateMeta,
        ),
      );
    }
    if (data.containsKey('salary_pending_carried')) {
      context.handle(
        _salaryPendingCarriedMeta,
        salaryPendingCarried.isAcceptableOrUnknown(
          data['salary_pending_carried']!,
          _salaryPendingCarriedMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MonthRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      yearMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}year_month'],
      )!,
      salaryExpected: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_expected'],
      )!,
      salaryAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_account_id'],
      ),
      salaryReceived: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}salary_received'],
      ),
      salaryReceivedDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}salary_received_date'],
      ),
      salaryPendingCarried: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}salary_pending_carried'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
    );
  }

  @override
  $MonthsTable createAlias(String alias) {
    return $MonthsTable(attachedDatabase, alias);
  }
}

class MonthRow extends DataClass implements Insertable<MonthRow> {
  final int id;
  final String yearMonth;
  final int salaryExpected;
  final int? salaryAccountId;
  final int? salaryReceived;
  final String? salaryReceivedDate;

  /// Previous month ended without salary — carried as a flag (spec §5 edge cases).
  final bool salaryPendingCarried;
  final String status;
  final int version;
  const MonthRow({
    required this.id,
    required this.yearMonth,
    required this.salaryExpected,
    this.salaryAccountId,
    this.salaryReceived,
    this.salaryReceivedDate,
    required this.salaryPendingCarried,
    required this.status,
    required this.version,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['year_month'] = Variable<String>(yearMonth);
    map['salary_expected'] = Variable<int>(salaryExpected);
    if (!nullToAbsent || salaryAccountId != null) {
      map['salary_account_id'] = Variable<int>(salaryAccountId);
    }
    if (!nullToAbsent || salaryReceived != null) {
      map['salary_received'] = Variable<int>(salaryReceived);
    }
    if (!nullToAbsent || salaryReceivedDate != null) {
      map['salary_received_date'] = Variable<String>(salaryReceivedDate);
    }
    map['salary_pending_carried'] = Variable<bool>(salaryPendingCarried);
    map['status'] = Variable<String>(status);
    map['version'] = Variable<int>(version);
    return map;
  }

  MonthsCompanion toCompanion(bool nullToAbsent) {
    return MonthsCompanion(
      id: Value(id),
      yearMonth: Value(yearMonth),
      salaryExpected: Value(salaryExpected),
      salaryAccountId: salaryAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryAccountId),
      salaryReceived: salaryReceived == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryReceived),
      salaryReceivedDate: salaryReceivedDate == null && nullToAbsent
          ? const Value.absent()
          : Value(salaryReceivedDate),
      salaryPendingCarried: Value(salaryPendingCarried),
      status: Value(status),
      version: Value(version),
    );
  }

  factory MonthRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthRow(
      id: serializer.fromJson<int>(json['id']),
      yearMonth: serializer.fromJson<String>(json['yearMonth']),
      salaryExpected: serializer.fromJson<int>(json['salaryExpected']),
      salaryAccountId: serializer.fromJson<int?>(json['salaryAccountId']),
      salaryReceived: serializer.fromJson<int?>(json['salaryReceived']),
      salaryReceivedDate: serializer.fromJson<String?>(
        json['salaryReceivedDate'],
      ),
      salaryPendingCarried: serializer.fromJson<bool>(
        json['salaryPendingCarried'],
      ),
      status: serializer.fromJson<String>(json['status']),
      version: serializer.fromJson<int>(json['version']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'yearMonth': serializer.toJson<String>(yearMonth),
      'salaryExpected': serializer.toJson<int>(salaryExpected),
      'salaryAccountId': serializer.toJson<int?>(salaryAccountId),
      'salaryReceived': serializer.toJson<int?>(salaryReceived),
      'salaryReceivedDate': serializer.toJson<String?>(salaryReceivedDate),
      'salaryPendingCarried': serializer.toJson<bool>(salaryPendingCarried),
      'status': serializer.toJson<String>(status),
      'version': serializer.toJson<int>(version),
    };
  }

  MonthRow copyWith({
    int? id,
    String? yearMonth,
    int? salaryExpected,
    Value<int?> salaryAccountId = const Value.absent(),
    Value<int?> salaryReceived = const Value.absent(),
    Value<String?> salaryReceivedDate = const Value.absent(),
    bool? salaryPendingCarried,
    String? status,
    int? version,
  }) => MonthRow(
    id: id ?? this.id,
    yearMonth: yearMonth ?? this.yearMonth,
    salaryExpected: salaryExpected ?? this.salaryExpected,
    salaryAccountId: salaryAccountId.present
        ? salaryAccountId.value
        : this.salaryAccountId,
    salaryReceived: salaryReceived.present
        ? salaryReceived.value
        : this.salaryReceived,
    salaryReceivedDate: salaryReceivedDate.present
        ? salaryReceivedDate.value
        : this.salaryReceivedDate,
    salaryPendingCarried: salaryPendingCarried ?? this.salaryPendingCarried,
    status: status ?? this.status,
    version: version ?? this.version,
  );
  MonthRow copyWithCompanion(MonthsCompanion data) {
    return MonthRow(
      id: data.id.present ? data.id.value : this.id,
      yearMonth: data.yearMonth.present ? data.yearMonth.value : this.yearMonth,
      salaryExpected: data.salaryExpected.present
          ? data.salaryExpected.value
          : this.salaryExpected,
      salaryAccountId: data.salaryAccountId.present
          ? data.salaryAccountId.value
          : this.salaryAccountId,
      salaryReceived: data.salaryReceived.present
          ? data.salaryReceived.value
          : this.salaryReceived,
      salaryReceivedDate: data.salaryReceivedDate.present
          ? data.salaryReceivedDate.value
          : this.salaryReceivedDate,
      salaryPendingCarried: data.salaryPendingCarried.present
          ? data.salaryPendingCarried.value
          : this.salaryPendingCarried,
      status: data.status.present ? data.status.value : this.status,
      version: data.version.present ? data.version.value : this.version,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthRow(')
          ..write('id: $id, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('salaryExpected: $salaryExpected, ')
          ..write('salaryAccountId: $salaryAccountId, ')
          ..write('salaryReceived: $salaryReceived, ')
          ..write('salaryReceivedDate: $salaryReceivedDate, ')
          ..write('salaryPendingCarried: $salaryPendingCarried, ')
          ..write('status: $status, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    yearMonth,
    salaryExpected,
    salaryAccountId,
    salaryReceived,
    salaryReceivedDate,
    salaryPendingCarried,
    status,
    version,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthRow &&
          other.id == this.id &&
          other.yearMonth == this.yearMonth &&
          other.salaryExpected == this.salaryExpected &&
          other.salaryAccountId == this.salaryAccountId &&
          other.salaryReceived == this.salaryReceived &&
          other.salaryReceivedDate == this.salaryReceivedDate &&
          other.salaryPendingCarried == this.salaryPendingCarried &&
          other.status == this.status &&
          other.version == this.version);
}

class MonthsCompanion extends UpdateCompanion<MonthRow> {
  final Value<int> id;
  final Value<String> yearMonth;
  final Value<int> salaryExpected;
  final Value<int?> salaryAccountId;
  final Value<int?> salaryReceived;
  final Value<String?> salaryReceivedDate;
  final Value<bool> salaryPendingCarried;
  final Value<String> status;
  final Value<int> version;
  const MonthsCompanion({
    this.id = const Value.absent(),
    this.yearMonth = const Value.absent(),
    this.salaryExpected = const Value.absent(),
    this.salaryAccountId = const Value.absent(),
    this.salaryReceived = const Value.absent(),
    this.salaryReceivedDate = const Value.absent(),
    this.salaryPendingCarried = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
  });
  MonthsCompanion.insert({
    this.id = const Value.absent(),
    required String yearMonth,
    required int salaryExpected,
    this.salaryAccountId = const Value.absent(),
    this.salaryReceived = const Value.absent(),
    this.salaryReceivedDate = const Value.absent(),
    this.salaryPendingCarried = const Value.absent(),
    this.status = const Value.absent(),
    this.version = const Value.absent(),
  }) : yearMonth = Value(yearMonth),
       salaryExpected = Value(salaryExpected);
  static Insertable<MonthRow> custom({
    Expression<int>? id,
    Expression<String>? yearMonth,
    Expression<int>? salaryExpected,
    Expression<int>? salaryAccountId,
    Expression<int>? salaryReceived,
    Expression<String>? salaryReceivedDate,
    Expression<bool>? salaryPendingCarried,
    Expression<String>? status,
    Expression<int>? version,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (yearMonth != null) 'year_month': yearMonth,
      if (salaryExpected != null) 'salary_expected': salaryExpected,
      if (salaryAccountId != null) 'salary_account_id': salaryAccountId,
      if (salaryReceived != null) 'salary_received': salaryReceived,
      if (salaryReceivedDate != null)
        'salary_received_date': salaryReceivedDate,
      if (salaryPendingCarried != null)
        'salary_pending_carried': salaryPendingCarried,
      if (status != null) 'status': status,
      if (version != null) 'version': version,
    });
  }

  MonthsCompanion copyWith({
    Value<int>? id,
    Value<String>? yearMonth,
    Value<int>? salaryExpected,
    Value<int?>? salaryAccountId,
    Value<int?>? salaryReceived,
    Value<String?>? salaryReceivedDate,
    Value<bool>? salaryPendingCarried,
    Value<String>? status,
    Value<int>? version,
  }) {
    return MonthsCompanion(
      id: id ?? this.id,
      yearMonth: yearMonth ?? this.yearMonth,
      salaryExpected: salaryExpected ?? this.salaryExpected,
      salaryAccountId: salaryAccountId ?? this.salaryAccountId,
      salaryReceived: salaryReceived ?? this.salaryReceived,
      salaryReceivedDate: salaryReceivedDate ?? this.salaryReceivedDate,
      salaryPendingCarried: salaryPendingCarried ?? this.salaryPendingCarried,
      status: status ?? this.status,
      version: version ?? this.version,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (yearMonth.present) {
      map['year_month'] = Variable<String>(yearMonth.value);
    }
    if (salaryExpected.present) {
      map['salary_expected'] = Variable<int>(salaryExpected.value);
    }
    if (salaryAccountId.present) {
      map['salary_account_id'] = Variable<int>(salaryAccountId.value);
    }
    if (salaryReceived.present) {
      map['salary_received'] = Variable<int>(salaryReceived.value);
    }
    if (salaryReceivedDate.present) {
      map['salary_received_date'] = Variable<String>(salaryReceivedDate.value);
    }
    if (salaryPendingCarried.present) {
      map['salary_pending_carried'] = Variable<bool>(
        salaryPendingCarried.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthsCompanion(')
          ..write('id: $id, ')
          ..write('yearMonth: $yearMonth, ')
          ..write('salaryExpected: $salaryExpected, ')
          ..write('salaryAccountId: $salaryAccountId, ')
          ..write('salaryReceived: $salaryReceived, ')
          ..write('salaryReceivedDate: $salaryReceivedDate, ')
          ..write('salaryPendingCarried: $salaryPendingCarried, ')
          ..write('status: $status, ')
          ..write('version: $version')
          ..write(')'))
        .toString();
  }
}

class $AccountMonthBalancesTable extends AccountMonthBalances
    with TableInfo<$AccountMonthBalancesTable, AccountMonthBalanceRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AccountMonthBalancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _openingMeta = const VerificationMeta(
    'opening',
  );
  @override
  late final GeneratedColumn<int> opening = GeneratedColumn<int>(
    'opening',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _closingMeta = const VerificationMeta(
    'closing',
  );
  @override
  late final GeneratedColumn<int> closing = GeneratedColumn<int>(
    'closing',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [monthId, accountId, opening, closing];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'account_month_balances';
  @override
  VerificationContext validateIntegrity(
    Insertable<AccountMonthBalanceRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('opening')) {
      context.handle(
        _openingMeta,
        opening.isAcceptableOrUnknown(data['opening']!, _openingMeta),
      );
    } else if (isInserting) {
      context.missing(_openingMeta);
    }
    if (data.containsKey('closing')) {
      context.handle(
        _closingMeta,
        closing.isAcceptableOrUnknown(data['closing']!, _closingMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {monthId, accountId};
  @override
  AccountMonthBalanceRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AccountMonthBalanceRow(
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      opening: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opening'],
      )!,
      closing: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}closing'],
      ),
    );
  }

  @override
  $AccountMonthBalancesTable createAlias(String alias) {
    return $AccountMonthBalancesTable(attachedDatabase, alias);
  }
}

class AccountMonthBalanceRow extends DataClass
    implements Insertable<AccountMonthBalanceRow> {
  final int monthId;
  final int accountId;
  final int opening;
  final int? closing;
  const AccountMonthBalanceRow({
    required this.monthId,
    required this.accountId,
    required this.opening,
    this.closing,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month_id'] = Variable<int>(monthId);
    map['account_id'] = Variable<int>(accountId);
    map['opening'] = Variable<int>(opening);
    if (!nullToAbsent || closing != null) {
      map['closing'] = Variable<int>(closing);
    }
    return map;
  }

  AccountMonthBalancesCompanion toCompanion(bool nullToAbsent) {
    return AccountMonthBalancesCompanion(
      monthId: Value(monthId),
      accountId: Value(accountId),
      opening: Value(opening),
      closing: closing == null && nullToAbsent
          ? const Value.absent()
          : Value(closing),
    );
  }

  factory AccountMonthBalanceRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AccountMonthBalanceRow(
      monthId: serializer.fromJson<int>(json['monthId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      opening: serializer.fromJson<int>(json['opening']),
      closing: serializer.fromJson<int?>(json['closing']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthId': serializer.toJson<int>(monthId),
      'accountId': serializer.toJson<int>(accountId),
      'opening': serializer.toJson<int>(opening),
      'closing': serializer.toJson<int?>(closing),
    };
  }

  AccountMonthBalanceRow copyWith({
    int? monthId,
    int? accountId,
    int? opening,
    Value<int?> closing = const Value.absent(),
  }) => AccountMonthBalanceRow(
    monthId: monthId ?? this.monthId,
    accountId: accountId ?? this.accountId,
    opening: opening ?? this.opening,
    closing: closing.present ? closing.value : this.closing,
  );
  AccountMonthBalanceRow copyWithCompanion(AccountMonthBalancesCompanion data) {
    return AccountMonthBalanceRow(
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      opening: data.opening.present ? data.opening.value : this.opening,
      closing: data.closing.present ? data.closing.value : this.closing,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AccountMonthBalanceRow(')
          ..write('monthId: $monthId, ')
          ..write('accountId: $accountId, ')
          ..write('opening: $opening, ')
          ..write('closing: $closing')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(monthId, accountId, opening, closing);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AccountMonthBalanceRow &&
          other.monthId == this.monthId &&
          other.accountId == this.accountId &&
          other.opening == this.opening &&
          other.closing == this.closing);
}

class AccountMonthBalancesCompanion
    extends UpdateCompanion<AccountMonthBalanceRow> {
  final Value<int> monthId;
  final Value<int> accountId;
  final Value<int> opening;
  final Value<int?> closing;
  final Value<int> rowid;
  const AccountMonthBalancesCompanion({
    this.monthId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.opening = const Value.absent(),
    this.closing = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AccountMonthBalancesCompanion.insert({
    required int monthId,
    required int accountId,
    required int opening,
    this.closing = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : monthId = Value(monthId),
       accountId = Value(accountId),
       opening = Value(opening);
  static Insertable<AccountMonthBalanceRow> custom({
    Expression<int>? monthId,
    Expression<int>? accountId,
    Expression<int>? opening,
    Expression<int>? closing,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (monthId != null) 'month_id': monthId,
      if (accountId != null) 'account_id': accountId,
      if (opening != null) 'opening': opening,
      if (closing != null) 'closing': closing,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AccountMonthBalancesCompanion copyWith({
    Value<int>? monthId,
    Value<int>? accountId,
    Value<int>? opening,
    Value<int?>? closing,
    Value<int>? rowid,
  }) {
    return AccountMonthBalancesCompanion(
      monthId: monthId ?? this.monthId,
      accountId: accountId ?? this.accountId,
      opening: opening ?? this.opening,
      closing: closing ?? this.closing,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (opening.present) {
      map['opening'] = Variable<int>(opening.value);
    }
    if (closing.present) {
      map['closing'] = Variable<int>(closing.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AccountMonthBalancesCompanion(')
          ..write('monthId: $monthId, ')
          ..write('accountId: $accountId, ')
          ..write('opening: $opening, ')
          ..write('closing: $closing, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CategoriesTable extends Categories
    with TableInfo<$CategoriesTable, CategoryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CategoriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<int> tier = GeneratedColumn<int>(
    'tier',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<String> color = GeneratedColumn<String>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    tier,
    icon,
    color,
    sortOrder,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'categories';
  @override
  VerificationContext validateIntegrity(
    Insertable<CategoryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CategoryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CategoryRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tier'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $CategoriesTable createAlias(String alias) {
    return $CategoriesTable(attachedDatabase, alias);
  }
}

class CategoryRow extends DataClass implements Insertable<CategoryRow> {
  final int id;
  final String name;
  final int tier;
  final String? icon;
  final String? color;
  final int sortOrder;
  final bool archived;
  const CategoryRow({
    required this.id,
    required this.name,
    required this.tier,
    this.icon,
    this.color,
    required this.sortOrder,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    map['tier'] = Variable<int>(tier);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<String>(color);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  CategoriesCompanion toCompanion(bool nullToAbsent) {
    return CategoriesCompanion(
      id: Value(id),
      name: Value(name),
      tier: Value(tier),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      sortOrder: Value(sortOrder),
      archived: Value(archived),
    );
  }

  factory CategoryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CategoryRow(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tier: serializer.fromJson<int>(json['tier']),
      icon: serializer.fromJson<String?>(json['icon']),
      color: serializer.fromJson<String?>(json['color']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'tier': serializer.toJson<int>(tier),
      'icon': serializer.toJson<String?>(icon),
      'color': serializer.toJson<String?>(color),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  CategoryRow copyWith({
    int? id,
    String? name,
    int? tier,
    Value<String?> icon = const Value.absent(),
    Value<String?> color = const Value.absent(),
    int? sortOrder,
    bool? archived,
  }) => CategoryRow(
    id: id ?? this.id,
    name: name ?? this.name,
    tier: tier ?? this.tier,
    icon: icon.present ? icon.value : this.icon,
    color: color.present ? color.value : this.color,
    sortOrder: sortOrder ?? this.sortOrder,
    archived: archived ?? this.archived,
  );
  CategoryRow copyWithCompanion(CategoriesCompanion data) {
    return CategoryRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tier: data.tier.present ? data.tier.value : this.tier,
      icon: data.icon.present ? data.icon.value : this.icon,
      color: data.color.present ? data.color.value : this.color,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CategoryRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tier: $tier, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, tier, icon, color, sortOrder, archived);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CategoryRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.tier == this.tier &&
          other.icon == this.icon &&
          other.color == this.color &&
          other.sortOrder == this.sortOrder &&
          other.archived == this.archived);
}

class CategoriesCompanion extends UpdateCompanion<CategoryRow> {
  final Value<int> id;
  final Value<String> name;
  final Value<int> tier;
  final Value<String?> icon;
  final Value<String?> color;
  final Value<int> sortOrder;
  final Value<bool> archived;
  const CategoriesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tier = const Value.absent(),
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  });
  CategoriesCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    required int tier,
    this.icon = const Value.absent(),
    this.color = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.archived = const Value.absent(),
  }) : name = Value(name),
       tier = Value(tier);
  static Insertable<CategoryRow> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<int>? tier,
    Expression<String>? icon,
    Expression<String>? color,
    Expression<int>? sortOrder,
    Expression<bool>? archived,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tier != null) 'tier': tier,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (archived != null) 'archived': archived,
    });
  }

  CategoriesCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<int>? tier,
    Value<String?>? icon,
    Value<String?>? color,
    Value<int>? sortOrder,
    Value<bool>? archived,
  }) {
    return CategoriesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tier: tier ?? this.tier,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      sortOrder: sortOrder ?? this.sortOrder,
      archived: archived ?? this.archived,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tier.present) {
      map['tier'] = Variable<int>(tier.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (color.present) {
      map['color'] = Variable<String>(color.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CategoriesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tier: $tier, ')
          ..write('icon: $icon, ')
          ..write('color: $color, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }
}

class $TemplatesTable extends Templates
    with TableInfo<$TemplatesTable, TemplateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultAmountMeta = const VerificationMeta(
    'defaultAmount',
  );
  @override
  late final GeneratedColumn<int> defaultAmount = GeneratedColumn<int>(
    'default_amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultAccountIdMeta = const VerificationMeta(
    'defaultAccountId',
  );
  @override
  late final GeneratedColumn<int> defaultAccountId = GeneratedColumn<int>(
    'default_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('monthly'),
  );
  static const VerificationMeta _daysOfWeekMeta = const VerificationMeta(
    'daysOfWeek',
  );
  @override
  late final GeneratedColumn<int> daysOfWeek = GeneratedColumn<int>(
    'days_of_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(127),
  );
  static const VerificationMeta _dueDayMeta = const VerificationMeta('dueDay');
  @override
  late final GeneratedColumn<int> dueDay = GeneratedColumn<int>(
    'due_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _variableAmountMeta = const VerificationMeta(
    'variableAmount',
  );
  @override
  late final GeneratedColumn<bool> variableAmount = GeneratedColumn<bool>(
    'variable_amount',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("variable_amount" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _startMonthMeta = const VerificationMeta(
    'startMonth',
  );
  @override
  late final GeneratedColumn<String> startMonth = GeneratedColumn<String>(
    'start_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endMonthMeta = const VerificationMeta(
    'endMonth',
  );
  @override
  late final GeneratedColumn<String> endMonth = GeneratedColumn<String>(
    'end_month',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    categoryId,
    name,
    defaultAmount,
    defaultAccountId,
    toAccountId,
    frequency,
    daysOfWeek,
    dueDay,
    variableAmount,
    startMonth,
    endMonth,
    active,
    sortOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('default_amount')) {
      context.handle(
        _defaultAmountMeta,
        defaultAmount.isAcceptableOrUnknown(
          data['default_amount']!,
          _defaultAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultAmountMeta);
    }
    if (data.containsKey('default_account_id')) {
      context.handle(
        _defaultAccountIdMeta,
        defaultAccountId.isAcceptableOrUnknown(
          data['default_account_id']!,
          _defaultAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('days_of_week')) {
      context.handle(
        _daysOfWeekMeta,
        daysOfWeek.isAcceptableOrUnknown(
          data['days_of_week']!,
          _daysOfWeekMeta,
        ),
      );
    }
    if (data.containsKey('due_day')) {
      context.handle(
        _dueDayMeta,
        dueDay.isAcceptableOrUnknown(data['due_day']!, _dueDayMeta),
      );
    }
    if (data.containsKey('variable_amount')) {
      context.handle(
        _variableAmountMeta,
        variableAmount.isAcceptableOrUnknown(
          data['variable_amount']!,
          _variableAmountMeta,
        ),
      );
    }
    if (data.containsKey('start_month')) {
      context.handle(
        _startMonthMeta,
        startMonth.isAcceptableOrUnknown(data['start_month']!, _startMonthMeta),
      );
    }
    if (data.containsKey('end_month')) {
      context.handle(
        _endMonthMeta,
        endMonth.isAcceptableOrUnknown(data['end_month']!, _endMonthMeta),
      );
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      defaultAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_amount'],
      )!,
      defaultAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_account_id'],
      ),
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      daysOfWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_of_week'],
      )!,
      dueDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}due_day'],
      ),
      variableAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}variable_amount'],
      )!,
      startMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_month'],
      ),
      endMonth: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_month'],
      ),
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
    );
  }

  @override
  $TemplatesTable createAlias(String alias) {
    return $TemplatesTable(attachedDatabase, alias);
  }
}

class TemplateRow extends DataClass implements Insertable<TemplateRow> {
  final int id;
  final int categoryId;
  final String name;
  final int defaultAmount;
  final int? defaultAccountId;

  /// For savings deposits (RD/SIP): paying moves money Bank → this account as a transfer.
  final int? toAccountId;
  final String frequency;
  final int daysOfWeek;
  final int? dueDay;
  final bool variableAmount;
  final String? startMonth;
  final String? endMonth;
  final bool active;
  final int sortOrder;
  const TemplateRow({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.defaultAmount,
    this.defaultAccountId,
    this.toAccountId,
    required this.frequency,
    required this.daysOfWeek,
    this.dueDay,
    required this.variableAmount,
    this.startMonth,
    this.endMonth,
    required this.active,
    required this.sortOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['category_id'] = Variable<int>(categoryId);
    map['name'] = Variable<String>(name);
    map['default_amount'] = Variable<int>(defaultAmount);
    if (!nullToAbsent || defaultAccountId != null) {
      map['default_account_id'] = Variable<int>(defaultAccountId);
    }
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    map['frequency'] = Variable<String>(frequency);
    map['days_of_week'] = Variable<int>(daysOfWeek);
    if (!nullToAbsent || dueDay != null) {
      map['due_day'] = Variable<int>(dueDay);
    }
    map['variable_amount'] = Variable<bool>(variableAmount);
    if (!nullToAbsent || startMonth != null) {
      map['start_month'] = Variable<String>(startMonth);
    }
    if (!nullToAbsent || endMonth != null) {
      map['end_month'] = Variable<String>(endMonth);
    }
    map['active'] = Variable<bool>(active);
    map['sort_order'] = Variable<int>(sortOrder);
    return map;
  }

  TemplatesCompanion toCompanion(bool nullToAbsent) {
    return TemplatesCompanion(
      id: Value(id),
      categoryId: Value(categoryId),
      name: Value(name),
      defaultAmount: Value(defaultAmount),
      defaultAccountId: defaultAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(defaultAccountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      frequency: Value(frequency),
      daysOfWeek: Value(daysOfWeek),
      dueDay: dueDay == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDay),
      variableAmount: Value(variableAmount),
      startMonth: startMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(startMonth),
      endMonth: endMonth == null && nullToAbsent
          ? const Value.absent()
          : Value(endMonth),
      active: Value(active),
      sortOrder: Value(sortOrder),
    );
  }

  factory TemplateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateRow(
      id: serializer.fromJson<int>(json['id']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      defaultAmount: serializer.fromJson<int>(json['defaultAmount']),
      defaultAccountId: serializer.fromJson<int?>(json['defaultAccountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      frequency: serializer.fromJson<String>(json['frequency']),
      daysOfWeek: serializer.fromJson<int>(json['daysOfWeek']),
      dueDay: serializer.fromJson<int?>(json['dueDay']),
      variableAmount: serializer.fromJson<bool>(json['variableAmount']),
      startMonth: serializer.fromJson<String?>(json['startMonth']),
      endMonth: serializer.fromJson<String?>(json['endMonth']),
      active: serializer.fromJson<bool>(json['active']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'categoryId': serializer.toJson<int>(categoryId),
      'name': serializer.toJson<String>(name),
      'defaultAmount': serializer.toJson<int>(defaultAmount),
      'defaultAccountId': serializer.toJson<int?>(defaultAccountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'frequency': serializer.toJson<String>(frequency),
      'daysOfWeek': serializer.toJson<int>(daysOfWeek),
      'dueDay': serializer.toJson<int?>(dueDay),
      'variableAmount': serializer.toJson<bool>(variableAmount),
      'startMonth': serializer.toJson<String?>(startMonth),
      'endMonth': serializer.toJson<String?>(endMonth),
      'active': serializer.toJson<bool>(active),
      'sortOrder': serializer.toJson<int>(sortOrder),
    };
  }

  TemplateRow copyWith({
    int? id,
    int? categoryId,
    String? name,
    int? defaultAmount,
    Value<int?> defaultAccountId = const Value.absent(),
    Value<int?> toAccountId = const Value.absent(),
    String? frequency,
    int? daysOfWeek,
    Value<int?> dueDay = const Value.absent(),
    bool? variableAmount,
    Value<String?> startMonth = const Value.absent(),
    Value<String?> endMonth = const Value.absent(),
    bool? active,
    int? sortOrder,
  }) => TemplateRow(
    id: id ?? this.id,
    categoryId: categoryId ?? this.categoryId,
    name: name ?? this.name,
    defaultAmount: defaultAmount ?? this.defaultAmount,
    defaultAccountId: defaultAccountId.present
        ? defaultAccountId.value
        : this.defaultAccountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    frequency: frequency ?? this.frequency,
    daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    dueDay: dueDay.present ? dueDay.value : this.dueDay,
    variableAmount: variableAmount ?? this.variableAmount,
    startMonth: startMonth.present ? startMonth.value : this.startMonth,
    endMonth: endMonth.present ? endMonth.value : this.endMonth,
    active: active ?? this.active,
    sortOrder: sortOrder ?? this.sortOrder,
  );
  TemplateRow copyWithCompanion(TemplatesCompanion data) {
    return TemplateRow(
      id: data.id.present ? data.id.value : this.id,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      defaultAmount: data.defaultAmount.present
          ? data.defaultAmount.value
          : this.defaultAmount,
      defaultAccountId: data.defaultAccountId.present
          ? data.defaultAccountId.value
          : this.defaultAccountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      daysOfWeek: data.daysOfWeek.present
          ? data.daysOfWeek.value
          : this.daysOfWeek,
      dueDay: data.dueDay.present ? data.dueDay.value : this.dueDay,
      variableAmount: data.variableAmount.present
          ? data.variableAmount.value
          : this.variableAmount,
      startMonth: data.startMonth.present
          ? data.startMonth.value
          : this.startMonth,
      endMonth: data.endMonth.present ? data.endMonth.value : this.endMonth,
      active: data.active.present ? data.active.value : this.active,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateRow(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('defaultAmount: $defaultAmount, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('frequency: $frequency, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('dueDay: $dueDay, ')
          ..write('variableAmount: $variableAmount, ')
          ..write('startMonth: $startMonth, ')
          ..write('endMonth: $endMonth, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    categoryId,
    name,
    defaultAmount,
    defaultAccountId,
    toAccountId,
    frequency,
    daysOfWeek,
    dueDay,
    variableAmount,
    startMonth,
    endMonth,
    active,
    sortOrder,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateRow &&
          other.id == this.id &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.defaultAmount == this.defaultAmount &&
          other.defaultAccountId == this.defaultAccountId &&
          other.toAccountId == this.toAccountId &&
          other.frequency == this.frequency &&
          other.daysOfWeek == this.daysOfWeek &&
          other.dueDay == this.dueDay &&
          other.variableAmount == this.variableAmount &&
          other.startMonth == this.startMonth &&
          other.endMonth == this.endMonth &&
          other.active == this.active &&
          other.sortOrder == this.sortOrder);
}

class TemplatesCompanion extends UpdateCompanion<TemplateRow> {
  final Value<int> id;
  final Value<int> categoryId;
  final Value<String> name;
  final Value<int> defaultAmount;
  final Value<int?> defaultAccountId;
  final Value<int?> toAccountId;
  final Value<String> frequency;
  final Value<int> daysOfWeek;
  final Value<int?> dueDay;
  final Value<bool> variableAmount;
  final Value<String?> startMonth;
  final Value<String?> endMonth;
  final Value<bool> active;
  final Value<int> sortOrder;
  const TemplatesCompanion({
    this.id = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.defaultAmount = const Value.absent(),
    this.defaultAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.variableAmount = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
  });
  TemplatesCompanion.insert({
    this.id = const Value.absent(),
    required int categoryId,
    required String name,
    required int defaultAmount,
    this.defaultAccountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.frequency = const Value.absent(),
    this.daysOfWeek = const Value.absent(),
    this.dueDay = const Value.absent(),
    this.variableAmount = const Value.absent(),
    this.startMonth = const Value.absent(),
    this.endMonth = const Value.absent(),
    this.active = const Value.absent(),
    this.sortOrder = const Value.absent(),
  }) : categoryId = Value(categoryId),
       name = Value(name),
       defaultAmount = Value(defaultAmount);
  static Insertable<TemplateRow> custom({
    Expression<int>? id,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<int>? defaultAmount,
    Expression<int>? defaultAccountId,
    Expression<int>? toAccountId,
    Expression<String>? frequency,
    Expression<int>? daysOfWeek,
    Expression<int>? dueDay,
    Expression<bool>? variableAmount,
    Expression<String>? startMonth,
    Expression<String>? endMonth,
    Expression<bool>? active,
    Expression<int>? sortOrder,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (defaultAmount != null) 'default_amount': defaultAmount,
      if (defaultAccountId != null) 'default_account_id': defaultAccountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (frequency != null) 'frequency': frequency,
      if (daysOfWeek != null) 'days_of_week': daysOfWeek,
      if (dueDay != null) 'due_day': dueDay,
      if (variableAmount != null) 'variable_amount': variableAmount,
      if (startMonth != null) 'start_month': startMonth,
      if (endMonth != null) 'end_month': endMonth,
      if (active != null) 'active': active,
      if (sortOrder != null) 'sort_order': sortOrder,
    });
  }

  TemplatesCompanion copyWith({
    Value<int>? id,
    Value<int>? categoryId,
    Value<String>? name,
    Value<int>? defaultAmount,
    Value<int?>? defaultAccountId,
    Value<int?>? toAccountId,
    Value<String>? frequency,
    Value<int>? daysOfWeek,
    Value<int?>? dueDay,
    Value<bool>? variableAmount,
    Value<String?>? startMonth,
    Value<String?>? endMonth,
    Value<bool>? active,
    Value<int>? sortOrder,
  }) {
    return TemplatesCompanion(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      defaultAmount: defaultAmount ?? this.defaultAmount,
      defaultAccountId: defaultAccountId ?? this.defaultAccountId,
      toAccountId: toAccountId ?? this.toAccountId,
      frequency: frequency ?? this.frequency,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      dueDay: dueDay ?? this.dueDay,
      variableAmount: variableAmount ?? this.variableAmount,
      startMonth: startMonth ?? this.startMonth,
      endMonth: endMonth ?? this.endMonth,
      active: active ?? this.active,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (defaultAmount.present) {
      map['default_amount'] = Variable<int>(defaultAmount.value);
    }
    if (defaultAccountId.present) {
      map['default_account_id'] = Variable<int>(defaultAccountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (daysOfWeek.present) {
      map['days_of_week'] = Variable<int>(daysOfWeek.value);
    }
    if (dueDay.present) {
      map['due_day'] = Variable<int>(dueDay.value);
    }
    if (variableAmount.present) {
      map['variable_amount'] = Variable<bool>(variableAmount.value);
    }
    if (startMonth.present) {
      map['start_month'] = Variable<String>(startMonth.value);
    }
    if (endMonth.present) {
      map['end_month'] = Variable<String>(endMonth.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplatesCompanion(')
          ..write('id: $id, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('defaultAmount: $defaultAmount, ')
          ..write('defaultAccountId: $defaultAccountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('frequency: $frequency, ')
          ..write('daysOfWeek: $daysOfWeek, ')
          ..write('dueDay: $dueDay, ')
          ..write('variableAmount: $variableAmount, ')
          ..write('startMonth: $startMonth, ')
          ..write('endMonth: $endMonth, ')
          ..write('active: $active, ')
          ..write('sortOrder: $sortOrder')
          ..write(')'))
        .toString();
  }
}

class $PlannedItemsTable extends PlannedItems
    with TableInfo<$PlannedItemsTable, PlannedRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PlannedItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _cardAccountIdMeta = const VerificationMeta(
    'cardAccountId',
  );
  @override
  late final GeneratedColumn<int> cardAccountId = GeneratedColumn<int>(
    'card_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _statementDateMeta = const VerificationMeta(
    'statementDate',
  );
  @override
  late final GeneratedColumn<String> statementDate = GeneratedColumn<String>(
    'statement_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    templateId,
    categoryId,
    name,
    amount,
    dueDate,
    status,
    cardAccountId,
    statementDate,
    transactionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'planned_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<PlannedRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('card_account_id')) {
      context.handle(
        _cardAccountIdMeta,
        cardAccountId.isAcceptableOrUnknown(
          data['card_account_id']!,
          _cardAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('statement_date')) {
      context.handle(
        _statementDateMeta,
        statementDate.isAcceptableOrUnknown(
          data['statement_date']!,
          _statementDateMeta,
        ),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PlannedRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PlannedRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      ),
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      cardAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}card_account_id'],
      ),
      statementDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}statement_date'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      ),
    );
  }

  @override
  $PlannedItemsTable createAlias(String alias) {
    return $PlannedItemsTable(attachedDatabase, alias);
  }
}

class PlannedRow extends DataClass implements Insertable<PlannedRow> {
  final int id;
  final int monthId;

  /// Null for auto-created credit-card bills.
  final int? templateId;
  final int? categoryId;
  final String name;
  final int amount;
  final String? dueDate;
  final String status;

  /// Credit card bill: the card this bill pays, and the statement date it froze.
  final int? cardAccountId;
  final String? statementDate;
  final int? transactionId;
  const PlannedRow({
    required this.id,
    required this.monthId,
    this.templateId,
    this.categoryId,
    required this.name,
    required this.amount,
    this.dueDate,
    required this.status,
    this.cardAccountId,
    this.statementDate,
    this.transactionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    map['name'] = Variable<String>(name);
    map['amount'] = Variable<int>(amount);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || cardAccountId != null) {
      map['card_account_id'] = Variable<int>(cardAccountId);
    }
    if (!nullToAbsent || statementDate != null) {
      map['statement_date'] = Variable<String>(statementDate);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<int>(transactionId);
    }
    return map;
  }

  PlannedItemsCompanion toCompanion(bool nullToAbsent) {
    return PlannedItemsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      name: Value(name),
      amount: Value(amount),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      status: Value(status),
      cardAccountId: cardAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(cardAccountId),
      statementDate: statementDate == null && nullToAbsent
          ? const Value.absent()
          : Value(statementDate),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
    );
  }

  factory PlannedRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PlannedRow(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      name: serializer.fromJson<String>(json['name']),
      amount: serializer.fromJson<int>(json['amount']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      status: serializer.fromJson<String>(json['status']),
      cardAccountId: serializer.fromJson<int?>(json['cardAccountId']),
      statementDate: serializer.fromJson<String?>(json['statementDate']),
      transactionId: serializer.fromJson<int?>(json['transactionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'templateId': serializer.toJson<int?>(templateId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'name': serializer.toJson<String>(name),
      'amount': serializer.toJson<int>(amount),
      'dueDate': serializer.toJson<String?>(dueDate),
      'status': serializer.toJson<String>(status),
      'cardAccountId': serializer.toJson<int?>(cardAccountId),
      'statementDate': serializer.toJson<String?>(statementDate),
      'transactionId': serializer.toJson<int?>(transactionId),
    };
  }

  PlannedRow copyWith({
    int? id,
    int? monthId,
    Value<int?> templateId = const Value.absent(),
    Value<int?> categoryId = const Value.absent(),
    String? name,
    int? amount,
    Value<String?> dueDate = const Value.absent(),
    String? status,
    Value<int?> cardAccountId = const Value.absent(),
    Value<String?> statementDate = const Value.absent(),
    Value<int?> transactionId = const Value.absent(),
  }) => PlannedRow(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    templateId: templateId.present ? templateId.value : this.templateId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    name: name ?? this.name,
    amount: amount ?? this.amount,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    status: status ?? this.status,
    cardAccountId: cardAccountId.present
        ? cardAccountId.value
        : this.cardAccountId,
    statementDate: statementDate.present
        ? statementDate.value
        : this.statementDate,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
  );
  PlannedRow copyWithCompanion(PlannedItemsCompanion data) {
    return PlannedRow(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      name: data.name.present ? data.name.value : this.name,
      amount: data.amount.present ? data.amount.value : this.amount,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      status: data.status.present ? data.status.value : this.status,
      cardAccountId: data.cardAccountId.present
          ? data.cardAccountId.value
          : this.cardAccountId,
      statementDate: data.statementDate.present
          ? data.statementDate.value
          : this.statementDate,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PlannedRow(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('templateId: $templateId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('cardAccountId: $cardAccountId, ')
          ..write('statementDate: $statementDate, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthId,
    templateId,
    categoryId,
    name,
    amount,
    dueDate,
    status,
    cardAccountId,
    statementDate,
    transactionId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PlannedRow &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.templateId == this.templateId &&
          other.categoryId == this.categoryId &&
          other.name == this.name &&
          other.amount == this.amount &&
          other.dueDate == this.dueDate &&
          other.status == this.status &&
          other.cardAccountId == this.cardAccountId &&
          other.statementDate == this.statementDate &&
          other.transactionId == this.transactionId);
}

class PlannedItemsCompanion extends UpdateCompanion<PlannedRow> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<int?> templateId;
  final Value<int?> categoryId;
  final Value<String> name;
  final Value<int> amount;
  final Value<String?> dueDate;
  final Value<String> status;
  final Value<int?> cardAccountId;
  final Value<String?> statementDate;
  final Value<int?> transactionId;
  const PlannedItemsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.name = const Value.absent(),
    this.amount = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.cardAccountId = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.transactionId = const Value.absent(),
  });
  PlannedItemsCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    this.templateId = const Value.absent(),
    this.categoryId = const Value.absent(),
    required String name,
    required int amount,
    this.dueDate = const Value.absent(),
    this.status = const Value.absent(),
    this.cardAccountId = const Value.absent(),
    this.statementDate = const Value.absent(),
    this.transactionId = const Value.absent(),
  }) : monthId = Value(monthId),
       name = Value(name),
       amount = Value(amount);
  static Insertable<PlannedRow> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<int>? templateId,
    Expression<int>? categoryId,
    Expression<String>? name,
    Expression<int>? amount,
    Expression<String>? dueDate,
    Expression<String>? status,
    Expression<int>? cardAccountId,
    Expression<String>? statementDate,
    Expression<int>? transactionId,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (templateId != null) 'template_id': templateId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (amount != null) 'amount': amount,
      if (dueDate != null) 'due_date': dueDate,
      if (status != null) 'status': status,
      if (cardAccountId != null) 'card_account_id': cardAccountId,
      if (statementDate != null) 'statement_date': statementDate,
      if (transactionId != null) 'transaction_id': transactionId,
    });
  }

  PlannedItemsCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<int?>? templateId,
    Value<int?>? categoryId,
    Value<String>? name,
    Value<int>? amount,
    Value<String?>? dueDate,
    Value<String>? status,
    Value<int?>? cardAccountId,
    Value<String?>? statementDate,
    Value<int?>? transactionId,
  }) {
    return PlannedItemsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      templateId: templateId ?? this.templateId,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      cardAccountId: cardAccountId ?? this.cardAccountId,
      statementDate: statementDate ?? this.statementDate,
      transactionId: transactionId ?? this.transactionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (cardAccountId.present) {
      map['card_account_id'] = Variable<int>(cardAccountId.value);
    }
    if (statementDate.present) {
      map['statement_date'] = Variable<String>(statementDate.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PlannedItemsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('templateId: $templateId, ')
          ..write('categoryId: $categoryId, ')
          ..write('name: $name, ')
          ..write('amount: $amount, ')
          ..write('dueDate: $dueDate, ')
          ..write('status: $status, ')
          ..write('cardAccountId: $cardAccountId, ')
          ..write('statementDate: $statementDate, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }
}

class $TransactionsTable extends Transactions
    with TableInfo<$TransactionsTable, TxRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TransactionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES months (id)',
    ),
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
    ),
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
  );
  static const VerificationMeta _plannedIdMeta = const VerificationMeta(
    'plannedId',
  );
  @override
  late final GeneratedColumn<int> plannedId = GeneratedColumn<int>(
    'planned_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES planned_items (id)',
    ),
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _toAccountIdMeta = const VerificationMeta(
    'toAccountId',
  );
  @override
  late final GeneratedColumn<int> toAccountId = GeneratedColumn<int>(
    'to_account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _viaUpiIdMeta = const VerificationMeta(
    'viaUpiId',
  );
  @override
  late final GeneratedColumn<int> viaUpiId = GeneratedColumn<int>(
    'via_upi_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<String> createdAt = GeneratedColumn<String>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    monthId,
    categoryId,
    templateId,
    plannedId,
    accountId,
    toAccountId,
    viaUpiId,
    type,
    amount,
    date,
    note,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'transactions';
  @override
  VerificationContext validateIntegrity(
    Insertable<TxRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('planned_id')) {
      context.handle(
        _plannedIdMeta,
        plannedId.isAcceptableOrUnknown(data['planned_id']!, _plannedIdMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    } else if (isInserting) {
      context.missing(_accountIdMeta);
    }
    if (data.containsKey('to_account_id')) {
      context.handle(
        _toAccountIdMeta,
        toAccountId.isAcceptableOrUnknown(
          data['to_account_id']!,
          _toAccountIdMeta,
        ),
      );
    }
    if (data.containsKey('via_upi_id')) {
      context.handle(
        _viaUpiIdMeta,
        viaUpiId.isAcceptableOrUnknown(data['via_upi_id']!, _viaUpiIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TxRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TxRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      ),
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      ),
      plannedId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned_id'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      )!,
      toAccountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}to_account_id'],
      ),
      viaUpiId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}via_upi_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      )!,
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $TransactionsTable createAlias(String alias) {
    return $TransactionsTable(attachedDatabase, alias);
  }
}

class TxRow extends DataClass implements Insertable<TxRow> {
  final int id;
  final int monthId;
  final int? categoryId;
  final int? templateId;
  final int? plannedId;
  final int accountId;
  final int? toAccountId;
  final int? viaUpiId;
  final String type;
  final int amount;
  final String date;
  final String? note;
  final String createdAt;
  const TxRow({
    required this.id,
    required this.monthId,
    this.categoryId,
    this.templateId,
    this.plannedId,
    required this.accountId,
    this.toAccountId,
    this.viaUpiId,
    required this.type,
    required this.amount,
    required this.date,
    this.note,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['month_id'] = Variable<int>(monthId);
    if (!nullToAbsent || categoryId != null) {
      map['category_id'] = Variable<int>(categoryId);
    }
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<int>(templateId);
    }
    if (!nullToAbsent || plannedId != null) {
      map['planned_id'] = Variable<int>(plannedId);
    }
    map['account_id'] = Variable<int>(accountId);
    if (!nullToAbsent || toAccountId != null) {
      map['to_account_id'] = Variable<int>(toAccountId);
    }
    if (!nullToAbsent || viaUpiId != null) {
      map['via_upi_id'] = Variable<int>(viaUpiId);
    }
    map['type'] = Variable<String>(type);
    map['amount'] = Variable<int>(amount);
    map['date'] = Variable<String>(date);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<String>(createdAt);
    return map;
  }

  TransactionsCompanion toCompanion(bool nullToAbsent) {
    return TransactionsCompanion(
      id: Value(id),
      monthId: Value(monthId),
      categoryId: categoryId == null && nullToAbsent
          ? const Value.absent()
          : Value(categoryId),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      plannedId: plannedId == null && nullToAbsent
          ? const Value.absent()
          : Value(plannedId),
      accountId: Value(accountId),
      toAccountId: toAccountId == null && nullToAbsent
          ? const Value.absent()
          : Value(toAccountId),
      viaUpiId: viaUpiId == null && nullToAbsent
          ? const Value.absent()
          : Value(viaUpiId),
      type: Value(type),
      amount: Value(amount),
      date: Value(date),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
    );
  }

  factory TxRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TxRow(
      id: serializer.fromJson<int>(json['id']),
      monthId: serializer.fromJson<int>(json['monthId']),
      categoryId: serializer.fromJson<int?>(json['categoryId']),
      templateId: serializer.fromJson<int?>(json['templateId']),
      plannedId: serializer.fromJson<int?>(json['plannedId']),
      accountId: serializer.fromJson<int>(json['accountId']),
      toAccountId: serializer.fromJson<int?>(json['toAccountId']),
      viaUpiId: serializer.fromJson<int?>(json['viaUpiId']),
      type: serializer.fromJson<String>(json['type']),
      amount: serializer.fromJson<int>(json['amount']),
      date: serializer.fromJson<String>(json['date']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<String>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'monthId': serializer.toJson<int>(monthId),
      'categoryId': serializer.toJson<int?>(categoryId),
      'templateId': serializer.toJson<int?>(templateId),
      'plannedId': serializer.toJson<int?>(plannedId),
      'accountId': serializer.toJson<int>(accountId),
      'toAccountId': serializer.toJson<int?>(toAccountId),
      'viaUpiId': serializer.toJson<int?>(viaUpiId),
      'type': serializer.toJson<String>(type),
      'amount': serializer.toJson<int>(amount),
      'date': serializer.toJson<String>(date),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<String>(createdAt),
    };
  }

  TxRow copyWith({
    int? id,
    int? monthId,
    Value<int?> categoryId = const Value.absent(),
    Value<int?> templateId = const Value.absent(),
    Value<int?> plannedId = const Value.absent(),
    int? accountId,
    Value<int?> toAccountId = const Value.absent(),
    Value<int?> viaUpiId = const Value.absent(),
    String? type,
    int? amount,
    String? date,
    Value<String?> note = const Value.absent(),
    String? createdAt,
  }) => TxRow(
    id: id ?? this.id,
    monthId: monthId ?? this.monthId,
    categoryId: categoryId.present ? categoryId.value : this.categoryId,
    templateId: templateId.present ? templateId.value : this.templateId,
    plannedId: plannedId.present ? plannedId.value : this.plannedId,
    accountId: accountId ?? this.accountId,
    toAccountId: toAccountId.present ? toAccountId.value : this.toAccountId,
    viaUpiId: viaUpiId.present ? viaUpiId.value : this.viaUpiId,
    type: type ?? this.type,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
  );
  TxRow copyWithCompanion(TransactionsCompanion data) {
    return TxRow(
      id: data.id.present ? data.id.value : this.id,
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      plannedId: data.plannedId.present ? data.plannedId.value : this.plannedId,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      toAccountId: data.toAccountId.present
          ? data.toAccountId.value
          : this.toAccountId,
      viaUpiId: data.viaUpiId.present ? data.viaUpiId.value : this.viaUpiId,
      type: data.type.present ? data.type.value : this.type,
      amount: data.amount.present ? data.amount.value : this.amount,
      date: data.date.present ? data.date.value : this.date,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TxRow(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('categoryId: $categoryId, ')
          ..write('templateId: $templateId, ')
          ..write('plannedId: $plannedId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('viaUpiId: $viaUpiId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    monthId,
    categoryId,
    templateId,
    plannedId,
    accountId,
    toAccountId,
    viaUpiId,
    type,
    amount,
    date,
    note,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TxRow &&
          other.id == this.id &&
          other.monthId == this.monthId &&
          other.categoryId == this.categoryId &&
          other.templateId == this.templateId &&
          other.plannedId == this.plannedId &&
          other.accountId == this.accountId &&
          other.toAccountId == this.toAccountId &&
          other.viaUpiId == this.viaUpiId &&
          other.type == this.type &&
          other.amount == this.amount &&
          other.date == this.date &&
          other.note == this.note &&
          other.createdAt == this.createdAt);
}

class TransactionsCompanion extends UpdateCompanion<TxRow> {
  final Value<int> id;
  final Value<int> monthId;
  final Value<int?> categoryId;
  final Value<int?> templateId;
  final Value<int?> plannedId;
  final Value<int> accountId;
  final Value<int?> toAccountId;
  final Value<int?> viaUpiId;
  final Value<String> type;
  final Value<int> amount;
  final Value<String> date;
  final Value<String?> note;
  final Value<String> createdAt;
  const TransactionsCompanion({
    this.id = const Value.absent(),
    this.monthId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.plannedId = const Value.absent(),
    this.accountId = const Value.absent(),
    this.toAccountId = const Value.absent(),
    this.viaUpiId = const Value.absent(),
    this.type = const Value.absent(),
    this.amount = const Value.absent(),
    this.date = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  TransactionsCompanion.insert({
    this.id = const Value.absent(),
    required int monthId,
    this.categoryId = const Value.absent(),
    this.templateId = const Value.absent(),
    this.plannedId = const Value.absent(),
    required int accountId,
    this.toAccountId = const Value.absent(),
    this.viaUpiId = const Value.absent(),
    required String type,
    required int amount,
    required String date,
    this.note = const Value.absent(),
    required String createdAt,
  }) : monthId = Value(monthId),
       accountId = Value(accountId),
       type = Value(type),
       amount = Value(amount),
       date = Value(date),
       createdAt = Value(createdAt);
  static Insertable<TxRow> custom({
    Expression<int>? id,
    Expression<int>? monthId,
    Expression<int>? categoryId,
    Expression<int>? templateId,
    Expression<int>? plannedId,
    Expression<int>? accountId,
    Expression<int>? toAccountId,
    Expression<int>? viaUpiId,
    Expression<String>? type,
    Expression<int>? amount,
    Expression<String>? date,
    Expression<String>? note,
    Expression<String>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (monthId != null) 'month_id': monthId,
      if (categoryId != null) 'category_id': categoryId,
      if (templateId != null) 'template_id': templateId,
      if (plannedId != null) 'planned_id': plannedId,
      if (accountId != null) 'account_id': accountId,
      if (toAccountId != null) 'to_account_id': toAccountId,
      if (viaUpiId != null) 'via_upi_id': viaUpiId,
      if (type != null) 'type': type,
      if (amount != null) 'amount': amount,
      if (date != null) 'date': date,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  TransactionsCompanion copyWith({
    Value<int>? id,
    Value<int>? monthId,
    Value<int?>? categoryId,
    Value<int?>? templateId,
    Value<int?>? plannedId,
    Value<int>? accountId,
    Value<int?>? toAccountId,
    Value<int?>? viaUpiId,
    Value<String>? type,
    Value<int>? amount,
    Value<String>? date,
    Value<String?>? note,
    Value<String>? createdAt,
  }) {
    return TransactionsCompanion(
      id: id ?? this.id,
      monthId: monthId ?? this.monthId,
      categoryId: categoryId ?? this.categoryId,
      templateId: templateId ?? this.templateId,
      plannedId: plannedId ?? this.plannedId,
      accountId: accountId ?? this.accountId,
      toAccountId: toAccountId ?? this.toAccountId,
      viaUpiId: viaUpiId ?? this.viaUpiId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (plannedId.present) {
      map['planned_id'] = Variable<int>(plannedId.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (toAccountId.present) {
      map['to_account_id'] = Variable<int>(toAccountId.value);
    }
    if (viaUpiId.present) {
      map['via_upi_id'] = Variable<int>(viaUpiId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<String>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TransactionsCompanion(')
          ..write('id: $id, ')
          ..write('monthId: $monthId, ')
          ..write('categoryId: $categoryId, ')
          ..write('templateId: $templateId, ')
          ..write('plannedId: $plannedId, ')
          ..write('accountId: $accountId, ')
          ..write('toAccountId: $toAccountId, ')
          ..write('viaUpiId: $viaUpiId, ')
          ..write('type: $type, ')
          ..write('amount: $amount, ')
          ..write('date: $date, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $DailyLogsTable extends DailyLogs
    with TableInfo<$DailyLogsTable, DailyLogRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _dateMeta = const VerificationMeta('date');
  @override
  late final GeneratedColumn<String> date = GeneratedColumn<String>(
    'date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<int> templateId = GeneratedColumn<int>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES templates (id)',
    ),
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<int> amount = GeneratedColumn<int>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _accountIdMeta = const VerificationMeta(
    'accountId',
  );
  @override
  late final GeneratedColumn<int> accountId = GeneratedColumn<int>(
    'account_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES accounts (id)',
    ),
  );
  static const VerificationMeta _transactionIdMeta = const VerificationMeta(
    'transactionId',
  );
  @override
  late final GeneratedColumn<int> transactionId = GeneratedColumn<int>(
    'transaction_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    date,
    templateId,
    state,
    amount,
    accountId,
    transactionId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyLogRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('date')) {
      context.handle(
        _dateMeta,
        date.isAcceptableOrUnknown(data['date']!, _dateMeta),
      );
    } else if (isInserting) {
      context.missing(_dateMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('account_id')) {
      context.handle(
        _accountIdMeta,
        accountId.isAcceptableOrUnknown(data['account_id']!, _accountIdMeta),
      );
    }
    if (data.containsKey('transaction_id')) {
      context.handle(
        _transactionIdMeta,
        transactionId.isAcceptableOrUnknown(
          data['transaction_id']!,
          _transactionIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {date, templateId};
  @override
  DailyLogRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyLogRow(
      date: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}date'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}template_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}amount'],
      ),
      accountId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}account_id'],
      ),
      transactionId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}transaction_id'],
      ),
    );
  }

  @override
  $DailyLogsTable createAlias(String alias) {
    return $DailyLogsTable(attachedDatabase, alias);
  }
}

class DailyLogRow extends DataClass implements Insertable<DailyLogRow> {
  final String date;
  final int templateId;
  final String state;
  final int? amount;
  final int? accountId;
  final int? transactionId;
  const DailyLogRow({
    required this.date,
    required this.templateId,
    required this.state,
    this.amount,
    this.accountId,
    this.transactionId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['date'] = Variable<String>(date);
    map['template_id'] = Variable<int>(templateId);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<int>(amount);
    }
    if (!nullToAbsent || accountId != null) {
      map['account_id'] = Variable<int>(accountId);
    }
    if (!nullToAbsent || transactionId != null) {
      map['transaction_id'] = Variable<int>(transactionId);
    }
    return map;
  }

  DailyLogsCompanion toCompanion(bool nullToAbsent) {
    return DailyLogsCompanion(
      date: Value(date),
      templateId: Value(templateId),
      state: Value(state),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      accountId: accountId == null && nullToAbsent
          ? const Value.absent()
          : Value(accountId),
      transactionId: transactionId == null && nullToAbsent
          ? const Value.absent()
          : Value(transactionId),
    );
  }

  factory DailyLogRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyLogRow(
      date: serializer.fromJson<String>(json['date']),
      templateId: serializer.fromJson<int>(json['templateId']),
      state: serializer.fromJson<String>(json['state']),
      amount: serializer.fromJson<int?>(json['amount']),
      accountId: serializer.fromJson<int?>(json['accountId']),
      transactionId: serializer.fromJson<int?>(json['transactionId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'date': serializer.toJson<String>(date),
      'templateId': serializer.toJson<int>(templateId),
      'state': serializer.toJson<String>(state),
      'amount': serializer.toJson<int?>(amount),
      'accountId': serializer.toJson<int?>(accountId),
      'transactionId': serializer.toJson<int?>(transactionId),
    };
  }

  DailyLogRow copyWith({
    String? date,
    int? templateId,
    String? state,
    Value<int?> amount = const Value.absent(),
    Value<int?> accountId = const Value.absent(),
    Value<int?> transactionId = const Value.absent(),
  }) => DailyLogRow(
    date: date ?? this.date,
    templateId: templateId ?? this.templateId,
    state: state ?? this.state,
    amount: amount.present ? amount.value : this.amount,
    accountId: accountId.present ? accountId.value : this.accountId,
    transactionId: transactionId.present
        ? transactionId.value
        : this.transactionId,
  );
  DailyLogRow copyWithCompanion(DailyLogsCompanion data) {
    return DailyLogRow(
      date: data.date.present ? data.date.value : this.date,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      state: data.state.present ? data.state.value : this.state,
      amount: data.amount.present ? data.amount.value : this.amount,
      accountId: data.accountId.present ? data.accountId.value : this.accountId,
      transactionId: data.transactionId.present
          ? data.transactionId.value
          : this.transactionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogRow(')
          ..write('date: $date, ')
          ..write('templateId: $templateId, ')
          ..write('state: $state, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('transactionId: $transactionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(date, templateId, state, amount, accountId, transactionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyLogRow &&
          other.date == this.date &&
          other.templateId == this.templateId &&
          other.state == this.state &&
          other.amount == this.amount &&
          other.accountId == this.accountId &&
          other.transactionId == this.transactionId);
}

class DailyLogsCompanion extends UpdateCompanion<DailyLogRow> {
  final Value<String> date;
  final Value<int> templateId;
  final Value<String> state;
  final Value<int?> amount;
  final Value<int?> accountId;
  final Value<int?> transactionId;
  final Value<int> rowid;
  const DailyLogsCompanion({
    this.date = const Value.absent(),
    this.templateId = const Value.absent(),
    this.state = const Value.absent(),
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyLogsCompanion.insert({
    required String date,
    required int templateId,
    required String state,
    this.amount = const Value.absent(),
    this.accountId = const Value.absent(),
    this.transactionId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : date = Value(date),
       templateId = Value(templateId),
       state = Value(state);
  static Insertable<DailyLogRow> custom({
    Expression<String>? date,
    Expression<int>? templateId,
    Expression<String>? state,
    Expression<int>? amount,
    Expression<int>? accountId,
    Expression<int>? transactionId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (date != null) 'date': date,
      if (templateId != null) 'template_id': templateId,
      if (state != null) 'state': state,
      if (amount != null) 'amount': amount,
      if (accountId != null) 'account_id': accountId,
      if (transactionId != null) 'transaction_id': transactionId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyLogsCompanion copyWith({
    Value<String>? date,
    Value<int>? templateId,
    Value<String>? state,
    Value<int?>? amount,
    Value<int?>? accountId,
    Value<int?>? transactionId,
    Value<int>? rowid,
  }) {
    return DailyLogsCompanion(
      date: date ?? this.date,
      templateId: templateId ?? this.templateId,
      state: state ?? this.state,
      amount: amount ?? this.amount,
      accountId: accountId ?? this.accountId,
      transactionId: transactionId ?? this.transactionId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (date.present) {
      map['date'] = Variable<String>(date.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<int>(templateId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (amount.present) {
      map['amount'] = Variable<int>(amount.value);
    }
    if (accountId.present) {
      map['account_id'] = Variable<int>(accountId.value);
    }
    if (transactionId.present) {
      map['transaction_id'] = Variable<int>(transactionId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyLogsCompanion(')
          ..write('date: $date, ')
          ..write('templateId: $templateId, ')
          ..write('state: $state, ')
          ..write('amount: $amount, ')
          ..write('accountId: $accountId, ')
          ..write('transactionId: $transactionId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MonthSummaryTable extends MonthSummary
    with TableInfo<$MonthSummaryTable, MonthSummaryRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MonthSummaryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _monthIdMeta = const VerificationMeta(
    'monthId',
  );
  @override
  late final GeneratedColumn<int> monthId = GeneratedColumn<int>(
    'month_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _categoryIdMeta = const VerificationMeta(
    'categoryId',
  );
  @override
  late final GeneratedColumn<int> categoryId = GeneratedColumn<int>(
    'category_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _plannedMeta = const VerificationMeta(
    'planned',
  );
  @override
  late final GeneratedColumn<int> planned = GeneratedColumn<int>(
    'planned',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _actualMeta = const VerificationMeta('actual');
  @override
  late final GeneratedColumn<int> actual = GeneratedColumn<int>(
    'actual',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [monthId, categoryId, planned, actual];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'month_summary';
  @override
  VerificationContext validateIntegrity(
    Insertable<MonthSummaryRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('month_id')) {
      context.handle(
        _monthIdMeta,
        monthId.isAcceptableOrUnknown(data['month_id']!, _monthIdMeta),
      );
    } else if (isInserting) {
      context.missing(_monthIdMeta);
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryIdMeta);
    }
    if (data.containsKey('planned')) {
      context.handle(
        _plannedMeta,
        planned.isAcceptableOrUnknown(data['planned']!, _plannedMeta),
      );
    }
    if (data.containsKey('actual')) {
      context.handle(
        _actualMeta,
        actual.isAcceptableOrUnknown(data['actual']!, _actualMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {monthId, categoryId};
  @override
  MonthSummaryRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MonthSummaryRow(
      monthId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}month_id'],
      )!,
      categoryId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}category_id'],
      )!,
      planned: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}planned'],
      )!,
      actual: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}actual'],
      )!,
    );
  }

  @override
  $MonthSummaryTable createAlias(String alias) {
    return $MonthSummaryTable(attachedDatabase, alias);
  }
}

class MonthSummaryRow extends DataClass implements Insertable<MonthSummaryRow> {
  final int monthId;
  final int categoryId;
  final int planned;
  final int actual;
  const MonthSummaryRow({
    required this.monthId,
    required this.categoryId,
    required this.planned,
    required this.actual,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['month_id'] = Variable<int>(monthId);
    map['category_id'] = Variable<int>(categoryId);
    map['planned'] = Variable<int>(planned);
    map['actual'] = Variable<int>(actual);
    return map;
  }

  MonthSummaryCompanion toCompanion(bool nullToAbsent) {
    return MonthSummaryCompanion(
      monthId: Value(monthId),
      categoryId: Value(categoryId),
      planned: Value(planned),
      actual: Value(actual),
    );
  }

  factory MonthSummaryRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MonthSummaryRow(
      monthId: serializer.fromJson<int>(json['monthId']),
      categoryId: serializer.fromJson<int>(json['categoryId']),
      planned: serializer.fromJson<int>(json['planned']),
      actual: serializer.fromJson<int>(json['actual']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'monthId': serializer.toJson<int>(monthId),
      'categoryId': serializer.toJson<int>(categoryId),
      'planned': serializer.toJson<int>(planned),
      'actual': serializer.toJson<int>(actual),
    };
  }

  MonthSummaryRow copyWith({
    int? monthId,
    int? categoryId,
    int? planned,
    int? actual,
  }) => MonthSummaryRow(
    monthId: monthId ?? this.monthId,
    categoryId: categoryId ?? this.categoryId,
    planned: planned ?? this.planned,
    actual: actual ?? this.actual,
  );
  MonthSummaryRow copyWithCompanion(MonthSummaryCompanion data) {
    return MonthSummaryRow(
      monthId: data.monthId.present ? data.monthId.value : this.monthId,
      categoryId: data.categoryId.present
          ? data.categoryId.value
          : this.categoryId,
      planned: data.planned.present ? data.planned.value : this.planned,
      actual: data.actual.present ? data.actual.value : this.actual,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MonthSummaryRow(')
          ..write('monthId: $monthId, ')
          ..write('categoryId: $categoryId, ')
          ..write('planned: $planned, ')
          ..write('actual: $actual')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(monthId, categoryId, planned, actual);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MonthSummaryRow &&
          other.monthId == this.monthId &&
          other.categoryId == this.categoryId &&
          other.planned == this.planned &&
          other.actual == this.actual);
}

class MonthSummaryCompanion extends UpdateCompanion<MonthSummaryRow> {
  final Value<int> monthId;
  final Value<int> categoryId;
  final Value<int> planned;
  final Value<int> actual;
  final Value<int> rowid;
  const MonthSummaryCompanion({
    this.monthId = const Value.absent(),
    this.categoryId = const Value.absent(),
    this.planned = const Value.absent(),
    this.actual = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MonthSummaryCompanion.insert({
    required int monthId,
    required int categoryId,
    this.planned = const Value.absent(),
    this.actual = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : monthId = Value(monthId),
       categoryId = Value(categoryId);
  static Insertable<MonthSummaryRow> custom({
    Expression<int>? monthId,
    Expression<int>? categoryId,
    Expression<int>? planned,
    Expression<int>? actual,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (monthId != null) 'month_id': monthId,
      if (categoryId != null) 'category_id': categoryId,
      if (planned != null) 'planned': planned,
      if (actual != null) 'actual': actual,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MonthSummaryCompanion copyWith({
    Value<int>? monthId,
    Value<int>? categoryId,
    Value<int>? planned,
    Value<int>? actual,
    Value<int>? rowid,
  }) {
    return MonthSummaryCompanion(
      monthId: monthId ?? this.monthId,
      categoryId: categoryId ?? this.categoryId,
      planned: planned ?? this.planned,
      actual: actual ?? this.actual,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (monthId.present) {
      map['month_id'] = Variable<int>(monthId.value);
    }
    if (categoryId.present) {
      map['category_id'] = Variable<int>(categoryId.value);
    }
    if (planned.present) {
      map['planned'] = Variable<int>(planned.value);
    }
    if (actual.present) {
      map['actual'] = Variable<int>(actual.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MonthSummaryCompanion(')
          ..write('monthId: $monthId, ')
          ..write('categoryId: $categoryId, ')
          ..write('planned: $planned, ')
          ..write('actual: $actual, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $StatsCacheTable extends StatsCache
    with TableInfo<$StatsCacheTable, StatRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $StatsCacheTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _computedAtMeta = const VerificationMeta(
    'computedAt',
  );
  @override
  late final GeneratedColumn<String> computedAt = GeneratedColumn<String>(
    'computed_at',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, computedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'stats_cache';
  @override
  VerificationContext validateIntegrity(
    Insertable<StatRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('computed_at')) {
      context.handle(
        _computedAtMeta,
        computedAt.isAcceptableOrUnknown(data['computed_at']!, _computedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_computedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  StatRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StatRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
      computedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}computed_at'],
      )!,
    );
  }

  @override
  $StatsCacheTable createAlias(String alias) {
    return $StatsCacheTable(attachedDatabase, alias);
  }
}

class StatRow extends DataClass implements Insertable<StatRow> {
  final String key;
  final int value;
  final String computedAt;
  const StatRow({
    required this.key,
    required this.value,
    required this.computedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<int>(value);
    map['computed_at'] = Variable<String>(computedAt);
    return map;
  }

  StatsCacheCompanion toCompanion(bool nullToAbsent) {
    return StatsCacheCompanion(
      key: Value(key),
      value: Value(value),
      computedAt: Value(computedAt),
    );
  }

  factory StatRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StatRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<int>(json['value']),
      computedAt: serializer.fromJson<String>(json['computedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<int>(value),
      'computedAt': serializer.toJson<String>(computedAt),
    };
  }

  StatRow copyWith({String? key, int? value, String? computedAt}) => StatRow(
    key: key ?? this.key,
    value: value ?? this.value,
    computedAt: computedAt ?? this.computedAt,
  );
  StatRow copyWithCompanion(StatsCacheCompanion data) {
    return StatRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      computedAt: data.computedAt.present
          ? data.computedAt.value
          : this.computedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StatRow(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('computedAt: $computedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, computedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StatRow &&
          other.key == this.key &&
          other.value == this.value &&
          other.computedAt == this.computedAt);
}

class StatsCacheCompanion extends UpdateCompanion<StatRow> {
  final Value<String> key;
  final Value<int> value;
  final Value<String> computedAt;
  final Value<int> rowid;
  const StatsCacheCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.computedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  StatsCacheCompanion.insert({
    required String key,
    required int value,
    required String computedAt,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value),
       computedAt = Value(computedAt);
  static Insertable<StatRow> custom({
    Expression<String>? key,
    Expression<int>? value,
    Expression<String>? computedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (computedAt != null) 'computed_at': computedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  StatsCacheCompanion copyWith({
    Value<String>? key,
    Value<int>? value,
    Value<String>? computedAt,
    Value<int>? rowid,
  }) {
    return StatsCacheCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      computedAt: computedAt ?? this.computedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    if (computedAt.present) {
      map['computed_at'] = Variable<String>(computedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('StatsCacheCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('computedAt: $computedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings
    with TableInfo<$SettingsTable, SettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class SettingRow extends DataClass implements Insertable<SettingRow> {
  final String key;
  final String value;
  const SettingRow({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory SettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SettingRow copyWith({String? key, String? value}) =>
      SettingRow(key: key ?? this.key, value: value ?? this.value);
  SettingRow copyWithCompanion(SettingsCompanion data) {
    return SettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<SettingRow> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  late final $AccountsTable accounts = $AccountsTable(this);
  late final $MonthsTable months = $MonthsTable(this);
  late final $AccountMonthBalancesTable accountMonthBalances =
      $AccountMonthBalancesTable(this);
  late final $CategoriesTable categories = $CategoriesTable(this);
  late final $TemplatesTable templates = $TemplatesTable(this);
  late final $PlannedItemsTable plannedItems = $PlannedItemsTable(this);
  late final $TransactionsTable transactions = $TransactionsTable(this);
  late final $DailyLogsTable dailyLogs = $DailyLogsTable(this);
  late final $MonthSummaryTable monthSummary = $MonthSummaryTable(this);
  late final $StatsCacheTable statsCache = $StatsCacheTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final Index idxPlannedMonth = Index(
    'idx_planned_month',
    'CREATE INDEX idx_planned_month ON planned_items (month_id, status)',
  );
  late final Index idxTxMonthDate = Index(
    'idx_tx_month_date',
    'CREATE INDEX idx_tx_month_date ON transactions (month_id, date)',
  );
  late final Index idxTxCategory = Index(
    'idx_tx_category',
    'CREATE INDEX idx_tx_category ON transactions (category_id, month_id)',
  );
  late final Index idxTxAccount = Index(
    'idx_tx_account',
    'CREATE INDEX idx_tx_account ON transactions (account_id, date)',
  );
  late final Index idxTxToAccount = Index(
    'idx_tx_to_account',
    'CREATE INDEX idx_tx_to_account ON transactions (to_account_id, date)',
  );
  late final Index idxDailylogDate = Index(
    'idx_dailylog_date',
    'CREATE INDEX idx_dailylog_date ON daily_logs (date)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    accounts,
    months,
    accountMonthBalances,
    categories,
    templates,
    plannedItems,
    transactions,
    dailyLogs,
    monthSummary,
    statsCache,
    settings,
    idxPlannedMonth,
    idxTxMonthDate,
    idxTxCategory,
    idxTxAccount,
    idxTxToAccount,
    idxDailylogDate,
  ];
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

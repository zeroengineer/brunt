import 'dart:typed_data';

import 'package:brunt/core/constants.dart';
import 'package:brunt/data/repositories/backup_repo.dart';
import 'package:brunt/data/repositories/ledger.dart';
import 'package:brunt/security/backup_crypto.dart';
import 'package:brunt/security/pin_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/harness.dart';

void main() {
  test('encrypt → decrypt round trip; wrong password and tampering fail', () async {
    final file = await BackupCrypto.encryptSync({'hello': 'world', 'n': 42}, 'correct horse', params: KdfParams.test);
    expect(String.fromCharCodes(file.sublist(0, 8)), 'BRUNTBK1');
    expect(await BackupCrypto.decryptSync(file, 'correct horse'), {'hello': 'world', 'n': 42});
    await expectLater(BackupCrypto.decryptSync(file, 'wrong'), throwsA(isA<BackupException>()));
    final bad = Uint8List.fromList(file)..[file.length - 5] ^= 0xFF;
    await expectLater(BackupCrypto.decryptSync(bad, 'correct horse'), throwsA(isA<BackupException>()));
    final badHeader = Uint8List.fromList(file)..[40] ^= 0x01;
    await expectLater(BackupCrypto.decryptSync(badHeader, 'correct horse'), throwsA(isA<BackupException>()));
    await expectLater(BackupCrypto.decryptSync(Uint8List.fromList([1, 2, 3]), 'x'), throwsA(isA<BackupException>()));
  });

  test('full DB export → encrypted file → restore into a fresh DB', () async {
    final a = Harness(DateTime(2026, 11, 7));
    final acc = await a.standard();
    await a.monthlyTemplate('Rent', 'Rent', 1200000, acc.bank, dueDay: 5);
    await a.ledger.add(Entry(type: TxType.expense, amount: 4000, date: a.now, accountId: acc.gpay));
    await a.ledger.receiveSalary(amount: 5000000, date: a.now, accountId: acc.bank);
    final file = await BackupCrypto.encryptSync(await BackupRepo(a.db).export(), 'pw', params: KdfParams.test);

    final b = Harness(DateTime(2026, 11, 7));
    await b.standard(salary: 1);
    await BackupRepo(b.db).restore(await BackupCrypto.decryptSync(file, 'pw'));
    expect(await b.balance(acc.bank), await a.balance(acc.bank));
    expect((await b.db.select(b.db.transactions).get()).length, 2);
    expect((await b.db.select(b.db.plannedItems).get()).single.name, 'Rent');
    expect(await b.engine.verifyBalances(), 0);
    await a.close();
    await b.close();
  });
}

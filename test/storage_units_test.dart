import 'package:flutter_test/flutter_test.dart';

import 'package:cercaposta/shared/format.dart';
import 'package:cercaposta/shared/storage_units.dart';

void main() {
  test('iOS and Android share exact decimal storage conversions', () {
    expect(storageInputBytes('50', 'GB'), 50000000000);
    expect(storageInputBytes('1.5', 'GB'), 1500000000);
    expect(storageInputBytes('1,5', 'GB'), 1500000000);
    expect(storageInputBytes('0.001', 'GB'), 1000000);
    expect(storageInputBytes('0.000000001', 'GB'), 1);
    expect(storageInputBytes('0.0000000015', 'GB'), 2);
    expect(storageInputBytes('NaN', 'GB'), isNull);
    expect(storageInputBytes('Infinity', 'GB'), isNull);
  });

  test('decimal display and locale do not change the unit base', () {
    expect(formatSize(50000000000, 'it_IT'), '50 GB');
    expect(formatSize(50000000000, 'en_US'), '50 GB');
    expect(formatSize(1500000000, 'it_IT'), '1,5 GB');
    expect(formatSize(1500000000, 'en_US'), '1.5 GB');
    expect(formatSize(1000, 'en_US'), '1 kB');
    expect(formatSize(1024, 'en_US'), '1.024 kB');
    expect(formatSize(1502500, 'en_US'), '1.503 MB');
    expect(formatSize(0, 'en_US'), '0 B');
  });
}

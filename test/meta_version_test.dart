import 'package:cercaposta/shared/models/meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('versionBelow uses semver, not string compare', () {
    expect(
      versionBelow('1.9.0', '1.10.0'),
      isTrue,
    ); // string compare would be wrong
    expect(versionBelow('1.0.0', '1.0.0'), isFalse);
    expect(versionBelow('2.0.0', '1.9.9'), isFalse);
    expect(versionBelow('1.2.3', '1.2.4'), isTrue);
    expect(versionBelow('1.0', '1.0.1'), isTrue);
  });

  test('MetaInfo.looksValid requires a name and the standard api prefix', () {
    final ok = MetaInfo.fromJson(<String, dynamic>{
      'name': 'Cerca posta',
      'api_prefix': '/api/v1',
    });
    expect(ok.looksValid, isTrue);
    final noName = MetaInfo.fromJson(<String, dynamic>{
      'name': '',
      'api_prefix': '/api/v1',
    });
    expect(noName.looksValid, isFalse);
    final wrongPrefix = MetaInfo.fromJson(<String, dynamic>{
      'name': 'X',
      'api_prefix': '/api/v2',
    });
    expect(wrongPrefix.looksValid, isFalse);
  });
}

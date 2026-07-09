import 'package:cercaposta/core/config/server_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('normalize adds https, lowercases scheme, strips trailing slashes', () {
    expect(ServerStore.normalize('example.com'), 'https://example.com');
    expect(
      ServerStore.normalize('HTTPS://Example.com/'),
      'https://Example.com',
    );
    expect(ServerStore.normalize('  http://h:8000//  '), 'http://h:8000');
    expect(ServerStore.normalize(''), '');
  });

  test('allowsCleartext: https always ok; http only for debug loopback', () {
    // flutter test runs in debug (kDebugMode == true).
    expect(ServerStore.allowsCleartext('https://example.com'), isTrue);
    expect(ServerStore.allowsCleartext('http://10.0.2.2:8000'), isTrue);
    expect(ServerStore.allowsCleartext('http://localhost'), isTrue);
    expect(ServerStore.allowsCleartext('http://example.com'), isFalse);
  });
}

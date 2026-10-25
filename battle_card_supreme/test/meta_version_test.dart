import 'package:battle_card_supreme/state/meta_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('force upgrade when current older than minimum', () {
    final meta = ServerMeta(
      minAppVersion: '1.1.0',
      catalogueVersion: 1,
      balanceVersion: 1,
      flags: const {},
    );
    expect(ServerMeta.isOlderThan('1.0.0', '1.1.0'), isTrue);
    expect(meta.forceUpgrade, isTrue);
  });

  test('no force upgrade when current meets minimum', () {
    expect(ServerMeta.isOlderThan('1.0.0', '1.0.0'), isFalse);
    expect(ServerMeta.isOlderThan('1.2.0', '1.1.0'), isFalse);
  });
}

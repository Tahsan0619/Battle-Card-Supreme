import 'package:battle_card_supreme/app.dart';
import 'package:battle_card_supreme/state/meta_controller.dart';
import 'package:battle_card_supreme/theme/aetherium_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app boots to home shell', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          metaProvider.overrideWith(_OfflineMeta.new),
        ],
        child: MaterialApp(
          theme: buildAetheriumTheme(),
          home: const BootGate(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('ENTER COMBAT'), findsOneWidget);
  });
}

class _OfflineMeta extends MetaController {
  @override
  Future<ServerMeta> build() async => ServerMeta.offline;
}

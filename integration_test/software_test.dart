import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:software/main.dart' as app;
import 'package:ubuntu_service/ubuntu_service.dart';
import 'package:yaru_widgets/yaru_widgets.dart';

import '../test/test_utils.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  tearDown(resetAllServices);

  group('Package Installer App', () {
    testWidgets('Install local deb', (tester) async {
      final localDeb =
          File('integration_test/assets/hello_2.10-2ubuntu4_amd64.deb');
      expect(localDeb.existsSync(), isTrue);

      final helloExe = File('/usr/bin/hello');
      expect(helloExe.existsSync(), isFalse);

      const packageName = 'hello';
      const packageVersion = '2.10-2ubuntu4';
      const packageArchitecture = 'amd64';
      const packageLicense = 'unknown';
      const packageUninstalledSize = '25.98 KB';
      const packageInstalledSize = '108.00 KB';

      await app.main([localDeb.absolute.path]);
      await tester.pump();

      Future<void> matchField(
        String label,
        String value, {
        bool exact = true,
      }) async {
        final tile = find.widgetWithText(YaruTile, label);
        await tester.pumpUntil(tile);
        expect(tile, findsOneWidget);
        final valueText = find.descendant(
          of: tile,
          matching: exact ? find.text(value) : find.textContaining(value),
        );
        await tester.pumpUntil(valueText);
        expect(valueText, findsOneWidget);
      }

      await matchField(tester.lang.name, packageName);
      await matchField(tester.lang.version, packageVersion);
      await matchField(tester.lang.architecture, packageArchitecture);
      await matchField(tester.lang.license, packageLicense);
      await matchField(tester.lang.size, packageUninstalledSize);

      final installButton = find.text(tester.lang.install);
      await tester.pumpUntil(installButton);
      expect(installButton, findsOneWidget);
      await tester.tap(installButton);

      final uninstallButton = find.text(tester.lang.remove);
      await tester.pumpUntil(uninstallButton);
      expect(uninstallButton, findsOneWidget);
      expect(installButton, findsNothing);

      expect(helloExe.existsSync(), isTrue);
      await matchField(tester.lang.size, packageInstalledSize);

      await tester.tap(uninstallButton);

      await tester.pumpUntil(installButton);
      expect(installButton, findsOneWidget);
      expect(uninstallButton, findsNothing);

      expect(helloExe.existsSync(), isFalse);
      await matchField(tester.lang.size, packageUninstalledSize);
    });
  });
}

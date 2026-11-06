import 'dart:io';

Future<void> main() async {
  if (!File('pubspec.yaml').existsSync() || !File('lib/main.dart').existsSync()) {
    stderr.writeln('Execute na raiz do MyCoffe Mobile.');
    exitCode = 1;
    return;
  }

  final process = await Process.start(
    'flutter',
    [
      'create',
      '--platforms=android,ios',
      '--org=br.edu.fatec',
      '--project-name=mycoffe',
      '--no-pub',
      '.',
    ],
    runInShell: Platform.isWindows,
    mode: ProcessStartMode.inheritStdio,
  );
  final status = await process.exitCode;
  if (status != 0) {
    exitCode = status;
    return;
  }

  final manifest = File('android/app/src/main/AndroidManifest.xml');
  final mainXml = manifest.readAsStringSync();
  var updated = mainXml.replaceFirst('android:label="mycoffe"', 'android:label="MyCoffe"');
  if (!mainXml.contains('android.permission.INTERNET')) {
    updated = updated.replaceFirst(
      '    <application',
      '    <uses-permission android:name="android.permission.INTERNET"/>\n'
      '    <application',
    );
  }
  manifest.writeAsStringSync(updated);

  final debugManifest = File('android/app/src/debug/AndroidManifest.xml');
  final debugXml = debugManifest.readAsStringSync();
  if (!debugXml.contains('android:usesCleartextTraffic')) {
    debugManifest.writeAsStringSync(debugXml.replaceFirst(
      '</manifest>',
      '    <application android:usesCleartextTraffic="true"/>\n</manifest>',
    ));
  }

  final iosInfo = File('ios/Runner/Info.plist');
  if (iosInfo.existsSync()) {
    iosInfo.writeAsStringSync(
      iosInfo.readAsStringSync().replaceAll(
        RegExp(r'<string>Mycoffe</string>|<string>mycoffe</string>'),
        '<string>MyCoffe</string>',
      ),
    );
  }

  stdout.writeln('Plataformas preparadas. Execute flutter pub get.');
}

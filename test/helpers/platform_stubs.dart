import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Registers stub handlers for method channels and plugins used by import/export
/// so widget/integration tests can run without platform bindings.
void registerPlatformStubs() {
  const saveChannel = MethodChannel('app.channel.savefile');
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(saveChannel, (methodCall) async {
    if (methodCall.method == 'saveFile') {
      return '/tmp/${(methodCall.arguments as Map)['fileName']}';
    }
    return null;
  });

  // file_selector: calls should be guarded in tests; no-op here.
}



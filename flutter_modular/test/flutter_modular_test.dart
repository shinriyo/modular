import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_modular/flutter_modular.dart';

void main() {
  test('MaterialApp extension', () {
    final app = const MaterialApp().modular();
    expect(app, isA<MaterialApp>());
  });

  test('CupertinoApp extension', () {
    final app = const CupertinoApp().modular();
    expect(app, isA<CupertinoApp>());
  });

  testWidgets('RouterOutlet', (tester) async {
    Modular.init(AppModule());
    await tester.pumpWidget(const MaterialApp().modular());

    await tester.pump();
    final finder = find.byKey(keyOutlet);
    expect(finder, findsOneWidget);

    final state = tester.state<RouterOutletState>(find.byKey(keyOutlet));
    state.listener();
  });
}

const keyOutlet = ValueKey('keyOutlet');

class AppModule extends Module {
  @override
  List<ModularRoute> get routes => [
        ParallelRoute.child('/',
            child: (_, __) => const RouterOutlet(key: keyOutlet)),
      ];
}

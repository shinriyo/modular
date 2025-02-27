import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triple/triple.dart';

void main() {
  testWidgets('ModularApp', (tester) async {
    final modularKey = UniqueKey();
    final modularApp = ModularApp(
        key: modularKey, module: CustomModule(), child: const AppWidget());
    await tester.pumpWidget(modularApp);

    await tester.pump();
    expect(find.byKey(key), findsOneWidget);

    final state = tester.state<ModularAppState>(find.byKey(modularKey));
    final result = state.tripleResolverCallback<String>();
    state.reassemble();
    expect(result, 'test');

    await tester.pump();
    final notifier = state.tripleResolverCallback<ValueNotifier<int>>();
    notifier.value++;

    await tester.pump();

    expect(find.text('1'), findsOneWidget);

    final store = state.tripleResolverCallback<MyStore>();
    store.update(1);

    //  await tester.pump();
  });
}

final key = UniqueKey();

class CustomModule extends Module {
  @override
  List<Bind> get binds => [
        Bind.factory((i) => 'test'),
        Bind.singleton((i) => ValueNotifier<int>(0)),
        Bind.singleton((i) => Stream<int>.value(0).asBroadcastStream()),
        Bind.singleton((i) => MyStore()),
      ];

  @override
  List<ModularRoute> get routes => [
        ChildRoute('/', child: (_, __) => const Home()),
      ];
}

class AppWidget extends StatelessWidget {
  const AppWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    context.read<String>();

    return const MaterialApp().modular();
  }
}

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ValueNotifier>();
    final stream = context.watch<Stream>();
    final store = context.watch<MyStore>();

    return Container(
      key: key,
      child: Column(
        children: [
          Text('${notifier.value}'),
          StreamBuilder(
            stream: stream,
            builder: (context, snapshot) {
              return Text('${snapshot.data}');
            },
          ),
          StreamBuilder<Object>(
              stream: null,
              builder: (context, snapshot) {
                return Text('${store.state}');
              }),
        ],
      ),
    );
  }
}

class MyStore extends Store<Exception, int> {
  MyStore() : super(0);

  @override
  Future destroy() async {}

  late final void Function(int state)? fnState;
  late final void Function(bool state)? fnLoading;
  late final void Function(Exception state)? fnError;

  @override
  void update(int newState, {bool force = false}) {
    fnState?.call(newState);
    fnError?.call(Exception());
    fnLoading?.call(true);
  }

  @override
  Disposer observer(
      {void Function(int state)? onState,
      void Function(bool isLoading)? onLoading,
      void Function(Exception error)? onError}) {
    fnState = onState;
    fnLoading = onLoading;
    fnError = onError;
    return () => Future.value();
  }
}

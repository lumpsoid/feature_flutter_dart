import 'package:feature_core/feature_core.dart';
import 'package:feature_flutter/feature_flutter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

//  Fakes & mocks

typedef _Ctrl = FeatureController<int, String, Never, String>;

class _MockController extends Mock implements _Ctrl {}

//  Widgets under test

/// Minimal widget using [FeaturePageMixin] with raw setState storage.
class _RawPage extends StatefulWidget {
  const _RawPage({required this.controller, this.initAction});
  final _Ctrl controller;
  final String? initAction;
  @override
  State<_RawPage> createState() => _RawPageState();
}

class _RawPageState extends State<_RawPage>
    with FeaturePageMixin<_RawPage, int, String, Never, String> {
  int _state = 0;
  final List<String> effects = [];

  @override
  _Ctrl get controller => widget.controller;

  @override
  int get currentState => _state;

  @override
  String? get initAction => widget.initAction;

  @override
  void updateState(int next) => setState(() => _state = next);

  @override
  Future<void> handleEffect(String effect) async => effects.add(effect);

  @override
  Widget build(BuildContext context) => Text('$_state');
}

/// Widget using [ValueNotifierPageState].
class _NotifierPage extends StatefulWidget {
  const _NotifierPage({required this.controller});
  final _Ctrl controller;
  @override
  State<_NotifierPage> createState() => _NotifierPageState();
}

class _NotifierPageState
    extends ValueNotifierPageState<_NotifierPage, int, String, Never, String> {
  @override
  _Ctrl get controller => widget.controller;

  @override
  int get initialState => 42;

  @override
  Future<void> handleEffect(String effect) async {}

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: stateNotifier,
      builder: (_, value, _) => Text('$value'),
    );
  }
}

//  Helpers

/// Captures the callbacks passed to [FeatureController.onViewAttach].
class _AttachCapture {
  StateGetter<int>? getter;
  StateUpdater<int>? updater;
  EffectPusher<String>? pusher;
}

extension on _MockController {
  _AttachCapture captureAttach() {
    final cap = _AttachCapture();
    when(
      () => onViewAttach(
        getter: any(named: 'getter'),
        updater: any(named: 'updater'),
        pusher: any(named: 'pusher'),
      ),
    ).thenAnswer((inv) {
      cap.getter = inv.namedArguments[#getter] as StateGetter<int>;
      cap.updater = inv.namedArguments[#updater] as StateUpdater<int>;
      cap.pusher = inv.namedArguments[#pusher] as EffectPusher<String>;
    });
    return cap;
  }
}

//  Tests

void main() {
  late _MockController ctrl;

  setUp(() {
    ctrl = _MockController();
    when(() => ctrl.onViewDetach()).thenReturn(null);
    when(() => ctrl.dispatch(any())).thenReturn(null);
  });

  group('FeaturePageMixin', () {
    testWidgets('calls onViewAttach on init', (tester) async {
      final cap = ctrl.captureAttach();

      await tester.pumpWidget(
        _RawPage(controller: ctrl),
      );

      verify(
        () => ctrl.onViewAttach(
          getter: any(named: 'getter'),
          updater: any(named: 'updater'),
          pusher: any(named: 'pusher'),
        ),
      ).called(1);

      expect(cap.getter, isNotNull);
      expect(cap.updater, isNotNull);
      expect(cap.pusher, isNotNull);
    });

    testWidgets('getter returns currentState', (tester) async {
      final cap = ctrl.captureAttach();

      await tester.pumpWidget(_RawPage(controller: ctrl));

      expect(cap.getter!(), 0);
    });

    testWidgets('updater triggers rebuild', (tester) async {
      final cap = ctrl.captureAttach();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _RawPage(controller: ctrl),
        ),
      );

      cap.updater!(99);
      await tester.pump();

      expect(find.text('99'), findsOneWidget);
    });

    testWidgets('dispatches initAction when provided', (tester) async {
      ctrl.captureAttach();

      await tester.pumpWidget(
        _RawPage(controller: ctrl, initAction: 'boot'),
      );

      verify(() => ctrl.dispatch('boot')).called(1);
    });

    testWidgets('does NOT dispatch when initAction is null', (tester) async {
      ctrl.captureAttach();

      await tester.pumpWidget(_RawPage(controller: ctrl));

      verifyNever(() => ctrl.dispatch(any()));
    });

    testWidgets('calls onViewDetach on dispose', (tester) async {
      ctrl.captureAttach();

      await tester.pumpWidget(_RawPage(controller: ctrl));
      await tester.pumpWidget(const SizedBox.shrink()); // dispose

      verify(() => ctrl.onViewDetach()).called(1);
    });
  });

  group('ValueNotifierPageState', () {
    testWidgets('initialises stateNotifier with initialState', (tester) async {
      ctrl.captureAttach();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _NotifierPage(controller: ctrl),
        ),
      );

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('updateState changes notifier value', (tester) async {
      final cap = ctrl.captureAttach();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _NotifierPage(controller: ctrl),
        ),
      );

      cap.updater!(7);
      await tester.pump();

      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('currentState reflects notifier value', (tester) async {
      final cap = ctrl.captureAttach();

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: _NotifierPage(controller: ctrl),
        ),
      );

      cap.updater!(55);
      await tester.pump();

      expect(cap.getter!(), 55);
    });

    testWidgets('disposes notifier without error', (tester) async {
      ctrl.captureAttach();

      await tester.pumpWidget(_NotifierPage(controller: ctrl));
      await tester.pumpWidget(const SizedBox.shrink()); // dispose

      // No exception → notifier was disposed cleanly.
      verify(() => ctrl.onViewDetach()).called(1);
    });
  });
}

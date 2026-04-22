# feature_flutter

Flutter bindings for [`feature_core`](https://github.com/lumpsoid/feature_core_dart).

Provides two drop-in building blocks that wire a `FeatureController` to the
`StatefulWidget` lifecycle with zero boilerplate.

---

## Installation

```yaml
dependencies:
  feature_core: ^1.0.0
  feature_flutter: ^0.1.0
```

---

## What's inside

| Type | When to use |
|------|-------------|
| `FeaturePageMixin` | You want full control over state storage (raw `setState`, streams, `ChangeNotifier`, …) |
| `ValueNotifierPageState` | You want a ready-made `ValueNotifier<S>` wired up for you |

---

## `ValueNotifierPageState` — quickstart

The most common choice. Extend it, supply a controller and an initial state,
and you get a `stateNotifier` ready to feed into `ValueListenableBuilder`.

```dart
class CounterPage extends StatefulWidget {
  const CounterPage({super.key});
  @override
  State<CounterPage> createState() => _CounterPageState();
}

class _CounterPageState
    extends ValueNotifierPageState<CounterPage, CounterState, CounterAction, Never, CounterEffect> {

  // 1. Supply the controller (usually from a Scope / InheritedWidget)
  @override
  FeatureController<CounterState, CounterAction, Never, CounterEffect> get controller =>
      CounterScope.of(context);

  // 2. Supply the initial state
  @override
  CounterState get initialState => const CounterState(count: 0);

  // 3. Handle UI effects
  @override
  Future<void> handleEffect(CounterEffect effect) async {
    switch (effect) {
      case CounterEffect.showSnackbar:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Limit reached!')),
        );
    }
  }

  // 4. Build — stateNotifier is ready here
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CounterState>(
      valueListenable: stateNotifier,
      builder: (context, state, _) {
        return Column(
          children: [
            Text('Count: ${state.count}'),
            ElevatedButton(
              onPressed: () => controller.dispatch(CounterAction.increment),
              child: const Text('+'),
            ),
          ],
        );
      },
    );
  }
}
```

---

## `FeaturePageMixin` — bring your own storage

Use the mixin directly when you need a different state-storage strategy
(e.g. `setState`, a `StreamSubscription`, or a custom `ChangeNotifier`).

```dart
class _CounterPageState extends State<CounterPage>
    with FeaturePageMixin<CounterPage, CounterState, CounterAction, Never, CounterEffect> {

  late CounterState _state;

  @override
  FeatureController<CounterState, CounterAction, Never, CounterEffect> get controller =>
      CounterScope.of(context);

  @override
  CounterState get currentState => _state;

  @override
  void updateState(CounterState next) => setState(() => _state = next);

  @override
  Future<void> handleEffect(CounterEffect effect) async { /* … */ }

  // initialise _state here — NOT in initState
  @override
  void initStateHolder() {
    _state = const CounterState(count: 0);
  }

  @override
  Widget build(BuildContext context) => Text('${_state.count}');
}
```

---

## Lifecycle order

Both building blocks follow the same strict order:

```
super.initState()          // Flutter — always first
initStateHolder()          // safe to create ValueNotifiers / subscriptions
controller.onViewAttach(…) // controller is wired
controller.dispatch(boot)  // optional initAction, if non-null
```

On dispose:

```
controller.onViewDetach()  // controller is unwired
super.dispose()            // Flutter teardown
```

---

## Optional boot action

Override `initAction` to dispatch an action immediately after attaching:

```dart
@override
CounterAction? get initAction => CounterAction.load;
```

---

## Running the tests

```bash
flutter test
```

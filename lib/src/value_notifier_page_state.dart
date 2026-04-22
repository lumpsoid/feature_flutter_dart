import 'package:feature_flutter/src/feature_page_mixin.dart';
import 'package:flutter/widgets.dart';

/// A [State] base class backed by a [ValueNotifier].
///
/// Provides [stateNotifier] for use with [ValueListenableBuilder] or any
/// [Listenable]-aware widget.
///
/// [stateNotifier] is guaranteed to be initialised before the controller
/// attaches because [initStateHolder] — called by [FeaturePageMixin] between
/// `super.initState()` and `controller.onViewAttach` — is where the notifier
/// is created.
///
/// The [build] method is intentionally left abstract: layout and widget tree
/// are entirely up to the subclass.
///
/// ### Example
///
/// ```dart
/// class _CounterPageState
///     extends ValueNotifierPageState<CounterPage, CounterState, CounterAction,
///     Never, Never> {
///
///   @override
///   FeatureController<CounterState, CounterAction, Never, Never> get
///   controller => CounterScope.of(context);
///
///   @override
///   CounterState get initialState => const CounterState(count: 0);
///
///   @override
///   Future<void> handleEffect(Never effect) async {}
///
///   @override
///   Widget build(BuildContext context) {
///     return ValueListenableBuilder<CounterState>(
///       valueListenable: stateNotifier,
///       builder: (context, state, _) => Text('${state.count}'),
///     );
///   }
/// }
/// ```
///
/// ### Type parameters
/// | Symbol | Meaning |
/// |--------|---------|
/// | [W]    | The [StatefulWidget] this [State] belongs to |
/// | [S]    | State type |
/// | [A]    | Action type |
/// | [SE]   | Shell-effect type |
/// | [E]    | UI-effect type |
abstract class ValueNotifierPageState<W extends StatefulWidget, S, A, SE, E>
    extends State<W>
    with FeaturePageMixin<W, S, A, SE, E> {
  /// The state used to initialise [stateNotifier].
  ///
  /// Called once during [initStateHolder]; the value is not cached separately —
  /// all subsequent reads go through [stateNotifier].
  S get initialState;

  /// Notifier holding the current feature state.
  ///
  /// Safe to read as soon as [initState] completes (i.e. inside [build]).
  late final ValueNotifier<S> stateNotifier;

  // FeaturePageMixin contract

  /// Initialises [stateNotifier] at the correct point in the lifecycle —
  /// after `super.initState()` but before `controller.onViewAttach`.
  @override
  void initStateHolder() {
    stateNotifier = ValueNotifier<S>(initialState);
  }

  @override
  S get currentState => stateNotifier.value;

  @override
  void updateState(S next) => stateNotifier.value = next;

  // Lifecycle

  @override
  void dispose() {
    stateNotifier.dispose();
    super.dispose(); // calls FeaturePageMixin.dispose → controller.onViewDetach
  }
}

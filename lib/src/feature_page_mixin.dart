import 'package:feature_core/feature_core.dart';
import 'package:flutter/widgets.dart';

/// Wires a [FeatureController] to a [State]'s lifecycle.
///
/// This mixin owns exactly three things:
/// - attaching/detaching the controller on init/dispose
/// - exposing [initStateHolder] for subclasses to initialise any state-holder
///   before the controller is wired up
/// - exposing [initAction] for an optional boot action
///
/// State storage, build method, and UI structure are entirely up to the user.
///
/// **Execution order inside [initState]:**
/// ```dart
/// super.initState()            // Flutter lifecycle — always first
/// initStateHolder()            // initialise your ValueNotifier / stream / etc.
/// controller.onViewAttach(…)   // wire the controller
/// controller.dispatch(initAction)
/// ```
///
/// ### Minimal example
///
/// ```dart
/// class _CounterPageState extends State<CounterPage>
///     with FeaturePageMixin<CounterPage, CounterState, CounterAction, Never,
///     Never> {
///
///   late CounterState _state;
///
///   @override
///   FeatureController<CounterState, CounterAction, Never, Never> get
///   controller => CounterScope.of(context);
///
///   @override
///   CounterState get currentState => _state;
///
///   @override
///   void updateState(CounterState next) => setState(() => _state = next);
///
///   @override
///   Future<void> handleEffect(Never effect) async {}
///
///   @override
///   void initStateHolder() {
///     _state = const CounterState(count: 0);
///   }
///
///   @override
///   Widget build(BuildContext context) => Text('${_state.count}');
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
mixin FeaturePageMixin<W extends StatefulWidget, S, A, SE, E> on State<W> {
  /// The controller for this feature (typically read from a Scope).
  FeatureController<S, A, SE, E> get controller;

  /// Current state snapshot — read by the controller via [StateGetter].
  S get currentState;

  /// Called by the controller to push a new state.
  void updateState(S next);

  /// Called by the controller to push a UI side-effect.
  Future<void> handleEffect(E effect);

  /// Optional action dispatched once on first attach.
  ///
  /// Return a non-null value to trigger a boot action immediately after
  /// the controller is wired up. The default is `null` (no boot action).
  A? get initAction => null;

  /// Called after [super.initState] but **before** the controller is wired up.
  ///
  /// Override this — not [initState] — to initialise any state-holder (e.g. a
  /// [ValueNotifier], stream subscription, or [AnimationController]) that must
  /// exist before [FeatureController.onViewAttach] is invoked.
  ///
  /// The default implementation is a no-op; there is no need to call
  /// `super.initStateHolder()`.
  ///
  /// ```dart
  /// @override
  /// void initStateHolder() {
  ///   stateNotifier = ValueNotifier(initialState);
  /// }
  /// ```
  @protected
  void initStateHolder() {}

  @override
  void initState() {
    super.initState(); // Flutter rule: always first
    initStateHolder(); // state-holder setup before wiring
    controller.onViewAttach(
      getter: () => currentState,
      updater: updateState,
      pusher: handleEffect,
    );
    final boot = initAction;
    if (boot != null) controller.dispatch(boot);
  }

  @override
  void dispose() {
    controller.onViewDetach();
    super.dispose();
  }
}

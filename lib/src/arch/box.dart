import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, T state);

typedef ProducerWidgetBuilder<T> = Widget Function(
    BuildContext context, Dispatcher<T> dispatcher);

typedef RebuildActionDecider<T> = Future<RebuildAction> Function(
    BuildContext context, T oldState, T newState);

typedef NotifyListener<T> = Future<bool> Function(T oldState, T newState);

class Producer<T> extends StatelessWidget {
  final ProducerWidgetBuilder builder;

  const Producer({Key key, @required this.builder}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final box = Provider.of<T>(context);
    return builder(context, box);
  }
}

class Consumer<T> extends StatefulWidget {
  final ConsumerWidgetBuilder<T> builder;
  final RebuildActionDecider<T> flow;
  final Widget child;

  const Consumer({Key key, this.builder, this.flow, this.child})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ConsumerState<T>();
  }
}

class _ConsumerState<T> extends State<Consumer<T>> {
  Box<T> model;
  @override
  void initState() {
    super.initState();
    model = Provider.of<T>(context);
    model._add(_onUpdate);
  }

  @override
  void dispose() {
    super.dispose();
    model._remove(_onUpdate);
  }

  Future<bool> _onUpdate(T oldState, T newState) async {
    final flow = await widget?.flow?.call(context, oldState, newState) ??
        RebuildAction.rebuild;
    switch (flow) {
      case RebuildAction.rebuild:
        setState(() {});
        return true;
      case RebuildAction.skip:
        return true;
      case RebuildAction.stop:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget?.builder?.call(context, model.state) ?? widget.child;
  }
}

class Provider extends InheritedWidget {
  final Map<Type, dynamic Function()> providers;
  final Map<Type, Box> _models = Map();
  Provider({this.providers, Widget child}) : super(child: child);

  static Box<T> of<T>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<Provider>();
    var model = provider._models[T];
    if (model == null) {
      model = Box<T>(provider.providers[T]());
      provider._models[T] = model;
    }
    return model;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }
}

class Box<S> with Notify, Dispatcher<S> {
  Box(this._state);
  S _state;
  S get state => _state;
  set state(S state) {
    _state = state;
  }

  @override
  void dispatch({Future<S> Function(S) action, bool notify = true}) async {
    final oldState = _state;
    final newState = action != null ? await action(_state) : _state;
    _state = newState;
    if (notify) _notify(oldState, newState);
  }

  @override
  void dispatchMultiple(
      {List<Future<S> Function(S)> actions, bool notify = true}) async {
    final oldState = _state;
    var newState = _state;
    for (final action in (actions ?? [])) {
      newState = await action(newState);
    }
    _state = newState;
    if (notify) _notify(oldState, newState);
  }
}

mixin Dispatcher<S> {
  void dispatch({Future<S> Function(S) action, bool notify = true});
  void dispatchMultiple(
      {List<Future<S> Function(S)> actions, bool notify = true});
}

mixin Notify<T> {
  final ObserverList<NotifyListener<T>> _listeners = ObserverList();

  void _add(NotifyListener<T> listener) {
    _listeners.add(listener);
  }

  void _remove(NotifyListener<T> listener) {
    _listeners.remove(listener);
  }

  void _notify(T oldState, T newState) async {
    for (final listener in _listeners) {
      if (!(await listener.call(oldState, newState))) break;
    }
  }
}

enum RebuildAction { rebuild, skip, stop }

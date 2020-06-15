import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, Model<T> model);

typedef UpdateFlowDecider<T> = Future<UpdateFlow> Function(
    BuildContext context, T oldState, T newState);

class Consumer<T> extends StatefulWidget {
  final ConsumerWidgetBuilder<T> builder;
  final UpdateFlowDecider<T> flow;
  final Widget child;

  const Consumer({Key key, this.builder, this.flow, this.child})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ConsumerState<T>();
  }
}

class _ConsumerState<T> extends State<Consumer<T>> {
  Model<T> model;
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

  Future<bool> _onUpdate(T old) async {
    final flow = await widget?.flow?.call(context, old, model.state) ??
        UpdateFlow.propogate;
    switch (flow) {
      case UpdateFlow.propogate:
        setState(() {});
        return true;
      case UpdateFlow.skip:
        return true;
      case UpdateFlow.stop:
        return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return widget?.builder?.call(context, model) ?? widget.child;
  }
}

class Provider extends InheritedWidget {
  final Map<Type, dynamic Function()> providers;
  final Map<Type, Model> _models = Map();
  Provider({this.providers, Widget child}) : super(child: child);

  static Model<T> of<T>(BuildContext context) {
    final provider = context.findAncestorWidgetOfExactType<Provider>();
    var model = provider._models[T];
    if (model == null) {
      model = Model<T>(provider.providers[T]());
      provider._models[T] = model;
    }
    return model;
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) {
    return true;
  }
}

typedef NotifyListener<S> = Future<bool> Function(S old);

class Model<S> with Notify {
  Model(this._state);
  S _state;
  S get state => _state;
  void setState(S state, {bool notify = true}) {
    final old = _state;
    _state = state;
    if (notify) _notify(old);
  }

  void dispatch(Future<S> Function(S) action, {bool notify = true}) async {
    final oldState = _state;
    final newState = await action(_state);
    _state = newState;
    if (notify) _notify(oldState);
  }
}

mixin Notify<S> {
  final ObserverList<NotifyListener<S>> _listeners = ObserverList();

  void _add(NotifyListener<S> listener) {
    _listeners.add(listener);
  }

  void _remove(NotifyListener<S> listener) {
    _listeners.remove(listener);
  }

  void _notify(S old) async {
    for (final listener in _listeners) {
      if (!(await listener.call(old))) break;
    }
  }
}

enum UpdateFlow { propogate, skip, stop }

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'functional.dart';

typedef ConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, T state);

typedef ProducerWidgetBuilder<T> = Widget Function(
    BuildContext context, Dispatcher<T> dispatcher);

typedef ProducingConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, Dispatcher<T> dispatcher, T state);

typedef RebuildActionDecider<T> = FutureOr<RebuildAction> Function(
    BuildContext context, T oldState, T newState);

typedef NotifyListener<T> = Future<bool> Function(T oldState, T newState);

class Producer<T> extends StatelessWidget {
  final ProducerWidgetBuilder<T> builder;

  const Producer({Key key, @required this.builder}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final box = Provider.of<T>(context);
    return builder(context, box);
  }
}

class Consumer<T> extends StatefulWidget {
  final ConsumerWidgetBuilder<T> builder;
  final RebuildActionDecider<T> rebuild;
  final Widget child;

  const Consumer({Key key, this.builder, this.rebuild, this.child})
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
    final rebuild = await widget?.rebuild?.call(context, oldState, newState) ??
        RebuildAction.rebuild;
    switch (rebuild) {
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

class ProducingConsumer<T> extends StatefulWidget {
  final ProducingConsumerWidgetBuilder<T> builder;
  final RebuildActionDecider<T> rebuild;
  final Widget child;

  const ProducingConsumer({Key key, this.builder, this.rebuild, this.child})
      : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ProducingConsumerState<T>();
  }
}

class _ProducingConsumerState<T> extends State<ProducingConsumer<T>> {
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
    final rebuild = await widget?.rebuild?.call(context, oldState, newState) ??
        RebuildAction.rebuild;
    switch (rebuild) {
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
    return widget?.builder?.call(context, model, model.state) ?? widget.child;
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

class Box<T> with Notify, Dispatcher<T> {
  Box(this.state);
  T state;

  @override
  T mutate(Reducer<T> mutation) {
    state = mutation(state);
    return state;
  }

  @override
  Future<T> mutateAsync(AsyncReducer<T> mutation) async {
    state = await mutation(state);
    return state;
  }

  @override
  T dispatch(Reducer<T> action) {
    _notify(state, mutate(action));
    return state;
  }

  @override
  Future<T> dispatchAsync(AsyncReducer<T> action) async {
    _notify(state, await mutateAsync(action));
    return state;
  }
}

mixin Dispatcher<T> {
  T mutate(Reducer<T> mutation);
  Future<T> mutateAsync(AsyncReducer<T> mutation);
  T dispatch(Reducer<T> action);
  Future<T> dispatchAsync(AsyncReducer<T> action);
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

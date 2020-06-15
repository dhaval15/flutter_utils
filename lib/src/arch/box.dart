import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef ConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, T state);

typedef ProducerWidgetBuilder<T> = Widget Function(
    BuildContext context, Dispatcher<T> dispatcher);

typedef ProducingConsumerWidgetBuilder<T> = Widget Function(
    BuildContext context, Dispatcher<T> dispatcher, T state);

typedef RebuildActionDecider<T> = FutureOr<RebuildAction> Function(
    BuildContext context, T oldState, T newState);

typedef NotifyListener<T> = Future<bool> Function(T oldState, T newState);

typedef Reducer<T> = FutureOr<T> Function(T data);

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

class Box<S> with Notify, Dispatcher<S> {
  Box(this.state);
  S state;

  @override
  void mutate(Reducer mutation) {
    state = mutation(state);
  }

  @override
  void mutateMultiple(List<Reducer> mutations) {
    for (final mutation in mutations) {
      mutate(mutation);
    }
  }

  @override
  void dispatch(Reducer action) async {
    final oldState = state;
    final newState = action != null ? await action(state) : state;
    state = newState;
    _notify(oldState, newState);
  }

  @override
  void dispatchMultiple(List<Reducer> actions) async {
    final oldState = state;
    var newState = state;
    for (final action in (actions ?? [])) {
      newState = await action(newState);
    }
    state = newState;
    _notify(oldState, newState);
  }
}

mixin Dispatcher<S> {
  void mutate(Reducer mutation);
  void mutateMultiple(List<Reducer> mutations);
  void dispatch(Reducer action);
  void dispatchMultiple(List<Reducer> actions);
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

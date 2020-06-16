import 'dart:async';
import 'package:flutter/material.dart';

class FunctionalWidget extends StatefulWidget {
  final WidgetBuilder build;
  final Function(BuildContext) init, dispose;
  final Function(BuildContext context, dynamic effect) onEffect;

  const FunctionalWidget({this.build, this.init, this.dispose, this.onEffect});

  @override
  _FunctionalWidgetState createState() => _FunctionalWidgetState();
}

class _FunctionalWidgetState extends State<FunctionalWidget> {
  @override
  void initState() {
    super.initState();
    widget?.init?.call(context);
  }

  @override
  Widget build(BuildContext context) {
    return widget.build(context);
  }

  @override
  void dispose() {
    super.dispose();
    widget?.dispose?.call(context);
  }
}

typedef Reducer<T> = T Function(T data);

typedef AsyncReducer<T> = FutureOr<T> Function(T data);

class CombinedReducer<T> {
  final List<Reducer<T>> _reducers;

  CombinedReducer(this._reducers);
  T call(T data) {
    T newData = data;
    for (final reducer in _reducers) {
      newData = reducer(newData);
    }
    return newData;
  }
}

class CombinedAsyncReducer<T> {
  final List<AsyncReducer<T>> _reducers;

  CombinedAsyncReducer(this._reducers);
  FutureOr<T> call(T data) async {
    var newData = data;
    for (final reducer in _reducers) {
      newData = await reducer(newData);
    }
    return newData;
  }
}

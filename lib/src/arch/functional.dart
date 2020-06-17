import 'dart:async';

typedef Reducer<T> = T Function(T data);

typedef AsyncReducer<T> = FutureOr<T> Function(T data);

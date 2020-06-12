mixin Dynamic {
  final Map<String, dynamic> _data = Map();
  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.isSetter) {
      _data[_stringify(invocation.memberName)] =
          invocation.positionalArguments[0];
      return;
    } else if (invocation.isGetter) {
      return _data[_stringify(invocation.memberName)];
    }
    return super.noSuchMethod(invocation);
  }
}

String _stringify(Symbol symbol) =>
    symbol.toString().substring(8).split('=')[0].split('"')[0];


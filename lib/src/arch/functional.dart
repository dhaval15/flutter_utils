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


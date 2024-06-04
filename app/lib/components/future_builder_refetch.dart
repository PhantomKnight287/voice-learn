import 'package:flutter/material.dart';

typedef CustomAsyncWidgetBuilder<T> = Widget Function(
  BuildContext context,
  AsyncSnapshot<T> snapshot,
  VoidCallback refreshInBackground,
);

class FutureBuilderRefetch<T> extends StatefulWidget {
  final Future<T> Function() future;
  final CustomAsyncWidgetBuilder<T> builder;

  const FutureBuilderRefetch({
    super.key,
    required this.future,
    required this.builder,
  });

  @override
  State<FutureBuilderRefetch<T>> createState() => _FutureBuilderRefetchState<T>();
}

class _FutureBuilderRefetchState<T> extends State<FutureBuilderRefetch<T>> {
  late Future<T> _future;
  late T _lastData;
  bool _hasData = false;

  @override
  void initState() {
    super.initState();
    _future = widget.future();
  }

  void _refreshInBackground() {
    widget.future().then((value) {
      setState(() {
        _lastData = value;
        _hasData = true;
      });
    }).catchError((error) {
      // Handle error if needed
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          _lastData = snapshot.data!;
          _hasData = true;
        }
        return widget.builder(
          context,
          _hasData ? AsyncSnapshot.withData(ConnectionState.done, _lastData) : snapshot,
          _refreshInBackground,
        );
      },
    );
  }
}

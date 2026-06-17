import 'package:flutter/widgets.dart';

/// Adds `BlocStateMixin`: blocs get a synchronous `state.valueOrNull` helper.
mixin BlocStateMixin<T> {
  T? get valueOrNull => (this as dynamic).state as T?;
}

/// Disposes a list of controllers/closables.
mixin DisposableMixin<T extends StatefulWidget> on State<T> {
  final List<VoidCallback> _disposers = [];

  void registerDispose(VoidCallback callback) => _disposers.add(callback);

  @override
  void dispose() {
    for (final dispose in _disposers) {
      dispose();
    }
    super.dispose();
  }
}

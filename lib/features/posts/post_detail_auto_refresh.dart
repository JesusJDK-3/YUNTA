import 'dart:async';

import 'package:flutter/material.dart';

VoidCallback startPostDetailAutoRefresh(
  Future<void>? Function() refreshIfReady,
) {
  final timer = Timer.periodic(const Duration(seconds: 15), (_) {
    final refresh = refreshIfReady();
    if (refresh != null) unawaited(refresh);
  });
  return timer.cancel;
}

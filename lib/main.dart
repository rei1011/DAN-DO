import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rolodex',
      home: Scaffold(appBar: AppBar(), body: AutoSaveView()),
    );
  }
}

class AutoSaveView extends HookWidget {
  const AutoSaveView({super.key});

  @override
  Widget build(BuildContext context) {
    useOnAppLifecycleStateChange(
      (prev, current) => debugPrint("prev: $prev, current: $current"),
    );
    return const Placeholder();
  }
}

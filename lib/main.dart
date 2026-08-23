import 'package:flutter/material.dart';

import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part "main.g.dart";

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(appBar: AppBar(), body: const UserNameSwitcherView()),
    );
  }
}

@riverpod
Future<String> userName(Ref ref, int userId) async {
  ref.onDispose(() => debugPrint('disposed: userId=$userId'));
  await Future<void>.delayed(const Duration(milliseconds: 100));
  return 'User#$userId';
}

class UserNameSwitcherView extends ConsumerStatefulWidget {
  const UserNameSwitcherView({super.key});

  @override
  ConsumerState<UserNameSwitcherView> createState() =>
      _UserNameSwitcherViewState();
}

class _UserNameSwitcherViewState extends ConsumerState<UserNameSwitcherView> {
  int selectedUserId = 1;

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(userNameProvider(selectedUserId));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        switch (name) {
          AsyncValue(:final value?) => Text(value),
          AsyncValue(error: != null) => const Text('Error'),
          AsyncValue() => const CircularProgressIndicator(),
        },
        ElevatedButton(
          onPressed: () => setState(() => selectedUserId = 1),
          child: const Text('userId: 1'),
        ),
        ElevatedButton(
          onPressed: () => setState(() => selectedUserId = 2),
          child: const Text('userId: 2'),
        ),
      ],
    );
  }
}

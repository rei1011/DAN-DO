import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      title: 'Rolodex',
      theme: CupertinoThemeData(
        barBackgroundColor: CupertinoDynamicColor.withBrightness(
          color: Color(0xFFF9F9F9),
          darkColor: Color(0xFF1D1D1D),
        ),
      ),
      home: Center(child: ScoreChangeView()),
    );
  }
}

class ScoreChangeView extends HookWidget {
  const ScoreChangeView({super.key});

  @override
  Widget build(BuildContext context) {
    final score = useState(1);
    final diff = useValueChanged(
      score.value,
      (oldScore, _) => score.value - oldScore,
    );
    final controller = useTextEditingController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('score: ${score.value}'),
        CupertinoTextField(
          controller: controller,
          keyboardType: TextInputType.number,
        ),
        CupertinoButton(
          onPressed: () {
            final parsed = int.tryParse(controller.text);
            if (parsed != null) {
              score.value = parsed;
            }
          },
          child: const Text('更新'),
        ),
        Text('${diff ?? "差分なし"}'),
      ],
    );
  }
}

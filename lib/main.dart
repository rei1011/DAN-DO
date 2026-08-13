import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:rxdart/rxdart.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      title: 'Rolodex',
      theme: CupertinoThemeData(
        barBackgroundColor: CupertinoDynamicColor.withBrightness(
          color: Color(0xFFF9F9F9),
          darkColor: Color(0xFF1D1D1D),
        ),
      ),
      home: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [FadeInView()]),
      ),
    );
  }
}

class FadeInView extends HookWidget {
  const FadeInView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController(
      duration: const Duration(seconds: 10),
    );

    useEffect(() {
      controller.toggle();
      return null;
    });

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: controller.value,
        child: const FlutterLogo(size: 100),
      ),
    );
  }
}

class FadeInViewStateful extends StatefulWidget {
  const FadeInViewStateful({super.key});

  @override
  State<FadeInViewStateful> createState() => _FadeInViewStatefulState();
}

class _FadeInViewStatefulState extends State<FadeInViewStateful>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    controller.toggle();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: controller.value,
        child: const FlutterLogo(size: 100),
      ),
    );
  }
}

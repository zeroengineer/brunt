import 'package:flutter/material.dart';

import '../../design/design.dart';
import 'brand.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GlowBackground(centerGlow: true, child: Center(child: BruntMark()));
  }
}

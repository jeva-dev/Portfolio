import 'package:flutter/material.dart';

import 'data/portfolio_data.dart';
import 'frame_cap.dart';
import 'home_page.dart';
import 'theme.dart';

void main() {
  FrameCappedBinding();
  runApp(const PortfolioApp());
}

class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '$fullName | Systems Developer',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const HomePage(),
    );
  }
}

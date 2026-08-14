import 'package:flutter/material.dart';

import 'navigation.dart';
import 'theme.dart';

class PersonalBookkeepingApp extends StatelessWidget {
  const PersonalBookkeepingApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '个人记账',
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    home: const AppShell(),
  );
}

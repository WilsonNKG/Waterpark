import 'package:flutter/material.dart';
import 'package:waterpark/core/waterpark_brand.dart';
import 'package:waterpark/dashboard/waterpark_dashboard.dart';

class WaterparkApp extends StatelessWidget {
  const WaterparkApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: WaterparkBrand.primaryBlue,
          brightness: Brightness.light,
        ).copyWith(
          primary: WaterparkBrand.primaryBlue,
          secondary: WaterparkBrand.accentRed,
          tertiary: WaterparkBrand.aqua,
          surface: WaterparkBrand.surface,
        );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Puri Nirwana Waterpark',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: WaterparkBrand.background,
      ),
      home: const WaterparkDashboard(),
    );
  }
}

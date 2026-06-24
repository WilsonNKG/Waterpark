import 'dart:convert';

import 'package:flutter/services.dart';

class AppConfig {
  const AppConfig._();

  static String _supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
  static String _supabaseAnonKey = const String.fromEnvironment(
    'SUPABASE_ANON_KEY',
  );

  static String get supabaseUrl => _supabaseUrl;
  static String get supabaseAnonKey => _supabaseAnonKey;

  static bool get hasSupabase =>
      _supabaseUrl.isNotEmpty && _supabaseAnonKey.isNotEmpty;

  static Future<void> load() async {
    if (hasSupabase) {
      return;
    }

    try {
      final jsonString = await rootBundle.loadString('env/supabase.local.json');
      final config = jsonDecode(jsonString) as Map<String, dynamic>;
      _supabaseUrl = (config['SUPABASE_URL'] as String? ?? '').trim();
      _supabaseAnonKey = (config['SUPABASE_ANON_KEY'] as String? ?? '').trim();
    } catch (_) {
      // Keep Dart define values when no local asset file is available.
    }
  }
}

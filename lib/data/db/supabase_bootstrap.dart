import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:waterpark/core/config/app_config.dart';

class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static Future<void> initialize() async {
    if (!AppConfig.hasSupabase) {
      return;
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabaseAnonKey,
    );
  }
}

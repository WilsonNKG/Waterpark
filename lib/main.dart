import 'package:flutter/material.dart';
import 'package:waterpark/core/supabase_bootstrap.dart';
import 'package:waterpark/waterpark_app.dart';

export 'package:waterpark/waterpark_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const WaterparkApp());
}

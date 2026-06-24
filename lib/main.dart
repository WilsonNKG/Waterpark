import 'package:flutter/material.dart';
import 'package:waterpark/app/app.dart';
import 'package:waterpark/data/db/supabase_bootstrap.dart';

export 'package:waterpark/app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseBootstrap.initialize();
  runApp(const WaterparkApp());
}

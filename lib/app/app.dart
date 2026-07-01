import 'package:flutter/material.dart';
import 'package:waterpark/app/shell/waterpark_dashboard_shell.dart';
import 'package:waterpark/core/config/app_config.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/ticketing/data/ticket_repository.dart';
import 'package:waterpark/features/ticketing/domain/ticket_inventory.dart';

class WaterparkApp extends StatefulWidget {
  const WaterparkApp({super.key});

  @override
  State<WaterparkApp> createState() => _WaterparkAppState();
}

class _WaterparkAppState extends State<WaterparkApp> {
  late final TicketInventory _ticketInventory;

  @override
  void initState() {
    super.initState();
    _ticketInventory = TicketInventory(
      repository: AppConfig.hasSupabase ? createTicketRepository() : null,
    );
    _ticketInventory.loadBatches();
  }

  @override
  void dispose() {
    _ticketInventory.dispose();
    super.dispose();
  }

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

    return TicketInventoryScope(
      inventory: _ticketInventory,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Puri Nirwana Waterpark',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: scheme,
          scaffoldBackgroundColor: WaterparkBrand.background,
        ),
        home: const WaterparkDashboardShell(),
      ),
    );
  }
}

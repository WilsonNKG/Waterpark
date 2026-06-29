import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:waterpark/core/config/app_config.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/staff_access/data/staff_repository.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';
import 'package:waterpark/features/staff_access/presentation/utils/qr_download.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

class StaffAccessPage extends StatefulWidget {
  const StaffAccessPage({super.key});

  @override
  State<StaffAccessPage> createState() => _StaffAccessPageState();
}

enum StaffRosterFilter { all, official, canteen, stand }

class _StaffAccessPageState extends State<StaffAccessPage> {
  StaffRepository? _repository;
  List<StaffMember> _staffMembers = const [];
  List<String> _roleOptions = buildStaffRoleOptions(const []);
  StaffRosterFilter _activeFilter = StaffRosterFilter.all;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _rosterScrollController = ScrollController();
  String _searchQuery = '';
  double? _rosterCardHeight;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      _repository = StaffRepository.create();
    } catch (error) {
      _errorMessage = '$error';
      _isLoading = false;
    }
    _loadStaff();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _rosterScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visibleMembers = _buildVisibleMembers();

    return LayoutBuilder(
      builder: (context, constraints) {
        final compactHeight = constraints.maxHeight < 720;
        final compactWidth = constraints.maxWidth < 1500;
        final minRosterHeight = compactHeight ? 420.0 : 540.0;
        final maxRosterHeight = compactHeight ? 920.0 : 1280.0;
        final defaultRosterHeight = compactHeight ? 520.0 : 680.0;
        final rosterCardHeight = ((_rosterCardHeight ?? defaultRosterHeight)
                .clamp(minRosterHeight, maxRosterHeight))
            as double;

        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Staff Access',
                  style: TextStyle(
                    color: WaterparkBrand.deepBlue,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppConfig.hasSupabase
                      ? 'Your staff list is connected to Supabase. Add staff, open their QR, remove a QR only, or delete the full staff record.'
                      : 'Supabase is required for the staff module. If the database is not configured, this page stays empty and shows an error instead of sample data.',
                  style: const TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: compactHeight ? 10 : 12),
                StaffTopBar(
                  total: _staffMembers.length,
                  readyQr: _staffMembers.where((member) => member.hasQr).length,
                  missingQr: _staffMembers.where((member) => !member.hasQr).length,
                  isConnectedToSupabase: AppConfig.hasSupabase,
                  onAddStaff: AppConfig.hasSupabase && !_isSaving
                      ? _handleAddStaff
                      : null,
                ),
                if (!AppConfig.hasSupabase) ...[
                  SizedBox(height: compactHeight ? 10 : 12),
                  const SupabaseSetupNotice(),
                ],
                SizedBox(height: compactHeight ? 10 : 12),
                if (_errorMessage != null) ...[
                  ErrorBanner(message: _errorMessage!, onRetry: _loadStaff),
                  SizedBox(height: compactHeight ? 10 : 12),
                ],
                if (_isLoading)
                  const BrandSurface(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        height: 320,
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                  )
                else if (compactWidth || compactHeight) ...[
                  SizedBox(
                    height: rosterCardHeight,
                    child: StaffRosterCard(
                      members: visibleMembers,
                      allMembers: _staffMembers,
                      isSaving: _isSaving,
                      activeFilter: _activeFilter,
                      searchController: _searchController,
                      scrollController: _rosterScrollController,
                      onResize: (delta) {
                        setState(() {
                          final nextHeight = rosterCardHeight + delta;
                          _rosterCardHeight = nextHeight.clamp(
                            minRosterHeight,
                            maxRosterHeight,
                          );
                        });
                      },
                      onFilterChanged: (filter) {
                        setState(() {
                          _activeFilter = filter;
                        });
                      },
                      onSearchChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      onAddStaff: _handleAddStaff,
                      onOpenQr: _showQrDialog,
                      onDeleteQr: _deleteQr,
                      onDeleteStaff: _confirmDeleteStaff,
                    ),
                  ),
                  SizedBox(height: compactHeight ? 8 : 10),
                  StaffRoleBreakdown(
                    members: _staffMembers,
                    availableRoles: _roleOptions,
                    initiallyExpanded: false,
                  ),
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: rosterCardHeight,
                          child: StaffRosterCard(
                            members: visibleMembers,
                            allMembers: _staffMembers,
                            isSaving: _isSaving,
                            activeFilter: _activeFilter,
                            searchController: _searchController,
                            scrollController: _rosterScrollController,
                            onResize: (delta) {
                              setState(() {
                                final nextHeight = rosterCardHeight + delta;
                                _rosterCardHeight = nextHeight.clamp(
                                  minRosterHeight,
                                  maxRosterHeight,
                                );
                              });
                            },
                            onFilterChanged: (filter) {
                              setState(() {
                                _activeFilter = filter;
                              });
                            },
                            onSearchChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            onAddStaff: _handleAddStaff,
                            onOpenQr: _showQrDialog,
                            onDeleteQr: _deleteQr,
                            onDeleteStaff: _confirmDeleteStaff,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      SizedBox(
                        width: 320,
                        child: StaffRoleBreakdown(
                          members: _staffMembers,
                          availableRoles: _roleOptions,
                          initiallyExpanded: true,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<StaffMember> _buildVisibleMembers() {
    final members = [..._staffMembers];
    members.sort(_compareStaffMembers);

    return switch (_activeFilter) {
      StaffRosterFilter.all => members,
      StaffRosterFilter.official => members
          .where((member) => member.staffType == StaffType.officialStaff)
          .toList(),
      StaffRosterFilter.canteen => members
          .where((member) => member.staffType == StaffType.canteenTenant)
          .toList(),
      StaffRosterFilter.stand => members
          .where((member) => member.staffType == StaffType.standTenant)
          .toList(),
    }.where(_matchesSearch).toList();
  }

  bool _matchesSearch(StaffMember member) {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return true;
    }

    final content = [
      member.staffCode,
      member.name,
      member.groupLabel,
      member.assignmentLabel,
      member.role,
      member.shortDescriptor,
      if (member.unitNumber != null) member.unitNumber.toString(),
    ].join(' ').toLowerCase();

    return content.contains(query);
  }

  int _compareStaffMembers(StaffMember a, StaffMember b) {
    final typeOrder = _sortOrderForType(a.staffType)
        .compareTo(_sortOrderForType(b.staffType));
    if (typeOrder != 0) {
      return typeOrder;
    }

    final unitOrder = (a.unitNumber ?? 0).compareTo(b.unitNumber ?? 0);
    if (unitOrder != 0) {
      return unitOrder;
    }

    return a.staffCode.compareTo(b.staffCode);
  }

  int _sortOrderForType(StaffType type) {
    return switch (type) {
      StaffType.canteenTenant => 0,
      StaffType.standTenant => 1,
      StaffType.officialStaff => 2,
    };
  }

  Future<void> _loadStaff() async {
    if (_repository == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final roles = await _repository!.fetchRoles();
      final staff = await _repository!.fetchStaff();
      if (!mounted) {
        return;
      }
      setState(() {
        _staffMembers = staff;
        _roleOptions = buildStaffRoleOptions([
          ...roles,
          ...staff.map((member) => member.role),
        ]);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load staff list. $error';
      });
    }
  }

  Future<void> _handleAddStaff() async {
    final draft = await showDialog<StaffDraft>(
      context: context,
      builder: (context) => AddStaffDialog(
        availableRoles: _roleOptions,
        lockedRoles: _staffMembers
            .where((member) => member.staffType == StaffType.officialStaff)
            .map((member) => member.role)
            .toSet(),
        onCreateRole: _createRole,
        onDeleteRole: _deleteRoleOption,
      ),
    );

    if (draft == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await _repository!.createStaff(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _staffMembers = [..._staffMembers, created];
        _roleOptions = buildStaffRoleOptions([..._roleOptions, created.role]);
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not create staff. $error';
      });
    }
  }

  Future<void> _confirmDeleteStaff(StaffMember member) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete staff'),
          content: Text(
            'Remove ${member.name} from the staff list? This also removes the QR tied to ${member.staffCode}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: WaterparkBrand.accentRed,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _repository!.deleteStaff(member.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _staffMembers = _staffMembers
            .where((entry) => entry.id != member.id)
            .toList();
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not delete staff. $error';
      });
    }
  }

  Future<String> _createRole(String role) async {
    final createdRole = await _repository!.createRole(role);
    if (!mounted) {
      return createdRole;
    }

    setState(() {
      _roleOptions = buildStaffRoleOptions([..._roleOptions, createdRole]);
    });

    return createdRole;
  }

  Future<void> _deleteRoleOption(String role) async {
    await _repository!.deleteRole(role);
    if (!mounted) {
      return;
    }

    setState(() {
      _roleOptions = _roleOptions.where((entry) => entry != role).toList();
    });
  }

  Future<void> _deleteQr(StaffMember member) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _repository!.deleteQr(member.id);
      if (!mounted) {
        return;
      }
      _replaceMember(updated);
      setState(() {
        _isSaving = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = 'Could not delete QR. $error';
      });
    }
  }

  Future<void> _showQrDialog(StaffMember member) async {
    final action = await showDialog<QrDialogAction>(
      context: context,
      builder: (context) => StaffQrDialog(
        member: member,
        onDownloadQr: member.hasQr ? () => _downloadQr(member) : null,
      ),
    );

    if (action == null) {
      return;
    }

    if (action == QrDialogAction.generate) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      try {
        final payload = _buildQrPayload(member);
        final updated = await _repository!.saveQr(member.id, payload);
        if (!mounted) {
          return;
        }
        _replaceMember(updated);
        setState(() {
          _isSaving = false;
        });
        await _showQrDialog(updated);
      } catch (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          _isSaving = false;
          _errorMessage = 'Could not generate QR. $error';
        });
      }
      return;
    }

    if (action == QrDialogAction.delete) {
      await _deleteQr(member);
    }
  }

  String _buildQrPayload(StaffMember member) {
    return 'STAFF|${member.staffCode}|${member.name}|${member.staffType.dbValue}|${member.role}|${member.qrUnitValue}';
  }

  Future<void> _downloadQr(StaffMember member) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final painter = QrPainter(
        data: member.qrPayload!,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );
      final imageData = await painter.toImageData(1200);
      final bytes = imageData?.buffer.asUint8List();

      if (bytes == null) {
        throw StateError('QR image data could not be created.');
      }

      final fileName = '${member.staffCode.toLowerCase()}_qr.png';
      await downloadQrImage(bytes: bytes, fileName: fileName);

      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Downloaded QR for ${member.name}.')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Could not download QR. $error')),
      );
    }
  }

  void _replaceMember(StaffMember updated) {
    _staffMembers = _staffMembers
        .map((member) => member.id == updated.id ? updated : member)
        .toList();
  }
}

class StaffTopBar extends StatelessWidget {
  const StaffTopBar({
    required this.total,
    required this.readyQr,
    required this.missingQr,
    required this.isConnectedToSupabase,
    required this.onAddStaff,
    super.key,
  });

  final int total;
  final int readyQr;
  final int missingQr;
  final bool isConnectedToSupabase;
  final VoidCallback? onAddStaff;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1280;

          return compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SummaryPill(
                          label: 'Total Staff',
                          value: '$total',
                          color: WaterparkBrand.primaryBlue,
                        ),
                        SummaryPill(
                          label: 'QR Ready',
                          value: '$readyQr',
                          color: WaterparkBrand.success,
                        ),
                        SummaryPill(
                          label: 'Missing QR',
                          value: '$missingQr',
                          color: WaterparkBrand.warning,
                        ),
                        SummaryPill(
                          label: 'Database',
                          value: isConnectedToSupabase ? 'Supabase' : 'Missing',
                          color: isConnectedToSupabase
                              ? WaterparkBrand.aqua
                              : WaterparkBrand.accentRed,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: onAddStaff,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add Staff'),
                    ),
                  ],
                )
              : Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          SummaryPill(
                            label: 'Total Staff',
                            value: '$total',
                            color: WaterparkBrand.primaryBlue,
                          ),
                          SummaryPill(
                            label: 'QR Ready',
                            value: '$readyQr',
                            color: WaterparkBrand.success,
                          ),
                          SummaryPill(
                            label: 'Missing QR',
                            value: '$missingQr',
                            color: WaterparkBrand.warning,
                          ),
                          SummaryPill(
                            label: 'Database',
                            value: isConnectedToSupabase
                                ? 'Supabase'
                                : 'Missing',
                            color: isConnectedToSupabase
                                ? WaterparkBrand.aqua
                                : WaterparkBrand.accentRed,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton.icon(
                      onPressed: onAddStaff,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add Staff'),
                    ),
                  ],
                );
        },
      ),
    );
  }
}

class SummaryPill extends StatelessWidget {
  const SummaryPill({
    required this.label,
    required this.value,
    required this.color,
    super.key,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: WaterparkBrand.gray,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SupabaseSetupNotice extends StatelessWidget {
  const SupabaseSetupNotice({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Supabase Setup Needed',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'This staff module only works with Supabase now. Start the app with SUPABASE_URL and SUPABASE_ANON_KEY so the roster can load from the database.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.45),
          ),
          SizedBox(height: 10),
          Text(
            'SQL file: db/staff_members.sql',
            style: TextStyle(
              color: WaterparkBrand.primaryBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({required this.message, required this.onRetry, super.key});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Row(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: WaterparkBrand.accentRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: WaterparkBrand.deepBlue,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class StaffRosterCard extends StatelessWidget {
  const StaffRosterCard({
    required this.members,
    required this.allMembers,
    required this.isSaving,
    required this.activeFilter,
    required this.searchController,
    required this.scrollController,
    required this.onResize,
    required this.onFilterChanged,
    required this.onSearchChanged,
    required this.onAddStaff,
    required this.onOpenQr,
    required this.onDeleteQr,
    required this.onDeleteStaff,
    super.key,
  });

  final List<StaffMember> members;
  final List<StaffMember> allMembers;
  final bool isSaving;
  final StaffRosterFilter activeFilter;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<double> onResize;
  final ValueChanged<StaffRosterFilter> onFilterChanged;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onAddStaff;
  final ValueChanged<StaffMember> onOpenQr;
  final ValueChanged<StaffMember> onDeleteQr;
  final ValueChanged<StaffMember> onDeleteStaff;

  @override
  Widget build(BuildContext context) {
    final officialCount = allMembers
        .where((member) => member.staffType == StaffType.officialStaff)
        .length;
    final canteenCount = allMembers
        .where((member) => member.staffType == StaffType.canteenTenant)
        .length;
    final standCount = allMembers
        .where((member) => member.staffType == StaffType.standTenant)
        .length;

    return BrandSurface(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactWidth = constraints.maxWidth < 1500;
          final compactHeight = constraints.maxHeight < 500;
          final contentWidth = compactWidth
              ? constraints.maxWidth
              : constraints.maxWidth > 1540
                  ? constraints.maxWidth
                  : 1540.0;

          return SizedBox.expand(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compactWidth) ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Roster',
                        style: TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Browse everyone by category, then open QR, delete only the QR, or remove the full staff record.',
                        style: TextStyle(
                          color: WaterparkBrand.gray,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : onAddStaff,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Staff'),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Staff Roster',
                              style: TextStyle(
                                color: WaterparkBrand.deepBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Browse everyone by category, then open QR, delete only the QR, or remove the full staff record.',
                              style: TextStyle(
                                color: WaterparkBrand.gray,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: isSaving ? null : onAddStaff,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('New Staff'),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: compactHeight ? 10 : 14),
                Wrap(
                  spacing: 10,
                  runSpacing: compactHeight ? 8 : 10,
                  children: [
                    _RosterFilterChip(
                      label: 'All',
                      count: allMembers.length,
                      selected: activeFilter == StaffRosterFilter.all,
                      onTap: () => onFilterChanged(StaffRosterFilter.all),
                    ),
                    _RosterFilterChip(
                      label: 'Canteen',
                      count: canteenCount,
                      selected: activeFilter == StaffRosterFilter.canteen,
                      onTap: () => onFilterChanged(StaffRosterFilter.canteen),
                    ),
                    _RosterFilterChip(
                      label: 'Stand',
                      count: standCount,
                      selected: activeFilter == StaffRosterFilter.stand,
                      onTap: () => onFilterChanged(StaffRosterFilter.stand),
                    ),
                    _RosterFilterChip(
                      label: 'Official',
                      count: officialCount,
                      selected: activeFilter == StaffRosterFilter.official,
                      onTap: () => onFilterChanged(StaffRosterFilter.official),
                    ),
                  ],
                ),
                SizedBox(height: compactHeight ? 8 : 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: searchController,
                        onChanged: onSearchChanged,
                        decoration: InputDecoration(
                          hintText:
                              'Search code, name, category, assignment, or role',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF8FBFF),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCEAF7),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFFDCEAF7),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (searchController.text.trim().isNotEmpty) ...[
                      const SizedBox(width: 10),
                      TextButton.icon(
                        onPressed: () {
                          searchController.clear();
                          onSearchChanged('');
                        },
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Clear'),
                      ),
                    ],
                  ],
                ),
                SizedBox(height: compactHeight ? 4 : 6),
                Text(
                  '${members.length} staff shown',
                  style: const TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: compactHeight ? 8 : 10),
                Expanded(
                  child: Column(
                    children: [
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: contentWidth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [Color(0xFFF4FAFF), Color(0xFFEAF6FF)],
                              ),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Row(
                              children: [
                                Expanded(flex: 2, child: StaffHeaderCell('Code')),
                                Expanded(flex: 2, child: StaffHeaderCell('Name')),
                                Expanded(flex: 2, child: StaffHeaderCell('Group')),
                                Expanded(
                                  flex: 2,
                                  child: StaffHeaderCell('Assignment'),
                                ),
                                Expanded(child: StaffHeaderCell('Status')),
                                Expanded(
                                  flex: 3,
                                  child: StaffHeaderCell('Actions'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: compactHeight ? 4 : 6),
                      Expanded(
                        child: members.isEmpty
                            ? EmptyRosterCard(filter: activeFilter)
                            : Scrollbar(
                                controller: scrollController,
                                thumbVisibility: true,
                                child: ListView.separated(
                                  controller: scrollController,
                                  itemCount: members.length,
                                  separatorBuilder: (_, _) =>
                                      const SizedBox(height: 6),
                                  itemBuilder: (context, index) {
                                    final member = members[index];
                                    return SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: SizedBox(
                                        width: contentWidth,
                                        child: StaffRow(
                                          member: member,
                                          isSaving: isSaving,
                                          onOpenQr: () => onOpenQr(member),
                                          onDeleteQr: member.hasQr
                                              ? () => onDeleteQr(member)
                                              : null,
                                          onDeleteStaff: () =>
                                              onDeleteStaff(member),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ),
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.resizeUpDown,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onVerticalDragUpdate: (details) {
                            onResize(details.delta.dy);
                          },
                          child: Center(
                            child: Container(
                              width: 120,
                              height: 18,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF2F7FD),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFD7E7F6),
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.drag_handle_rounded,
                                  size: 16,
                                  color: WaterparkBrand.primaryBlue,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class EmptyRosterCard extends StatelessWidget {
  const EmptyRosterCard({required this.filter, super.key});

  final StaffRosterFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      StaffRosterFilter.all =>
        'No staff yet. Add your first staff member to begin assigning access.',
      StaffRosterFilter.canteen =>
        'No canteen tenants yet. Add one to link them to a canteen number.',
      StaffRosterFilter.stand =>
        'No stand tenants yet. Add one to link them to a stand number.',
      StaffRosterFilter.official =>
        'No official staff yet. Add internal staff roles to start managing access.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF8)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: WaterparkBrand.gray, fontSize: 14),
      ),
    );
  }
}

class StaffRow extends StatelessWidget {
  const StaffRow({
    required this.member,
    required this.isSaving,
    required this.onOpenQr,
    required this.onDeleteQr,
    required this.onDeleteStaff,
    super.key,
  });

  final StaffMember member;
  final bool isSaving;
  final VoidCallback onOpenQr;
  final VoidCallback? onDeleteQr;
  final VoidCallback onDeleteStaff;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFDDEBF8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A002B45),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: StaffBodyCell(
              member.staffCode,
              emphasis: true,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                StaffBodyCell(member.name, emphasis: true),
                const SizedBox(height: 4),
                Text(
                  member.shortDescriptor,
                  style: const TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: TypeChip(label: member.groupLabel),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RoleChip(role: member.assignmentLabel),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: StaffStatusBadge(status: member.status),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ActionChipButton(
                  tooltip: member.hasQr ? 'View QR' : 'Generate QR',
                  icon: member.hasQr
                      ? Icons.qr_code_2_rounded
                      : Icons.add_circle_outline_rounded,
                  color: WaterparkBrand.primaryBlue,
                  onPressed: isSaving ? null : onOpenQr,
                ),
                const SizedBox(width: 8),
                ActionChipButton(
                  tooltip: 'Delete QR',
                  icon: Icons.delete_outline_rounded,
                  color: WaterparkBrand.warning,
                  onPressed: isSaving ? null : onDeleteQr,
                ),
                const SizedBox(width: 8),
                ActionChipButton(
                  tooltip: 'Delete Staff',
                  icon: Icons.person_remove_alt_1_rounded,
                  color: WaterparkBrand.accentRed,
                  onPressed: isSaving ? null : onDeleteStaff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ActionChipButton extends StatelessWidget {
  const ActionChipButton({
    required this.tooltip,
    required this.icon,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String tooltip;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: onPressed == null
                ? const Color(0xFFF3F5F8)
                : color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: onPressed == null
                  ? const Color(0xFFE3EAF1)
                  : color.withValues(alpha: 0.15),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: onPressed == null ? WaterparkBrand.gray : color,
          ),
        ),
      ),
    );
  }
}

class StaffRoleBreakdown extends StatelessWidget {
  const StaffRoleBreakdown({
    required this.members,
    required this.availableRoles,
    this.initiallyExpanded = true,
    super.key,
  });

  final List<StaffMember> members;
  final List<String> availableRoles;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final officialCount = members
        .where((member) => member.staffType == StaffType.officialStaff)
        .length;
    final canteenCount = members
        .where((member) => member.staffType == StaffType.canteenTenant)
        .length;
    final standCount = members
        .where((member) => member.staffType == StaffType.standTenant)
        .length;
    final officialRoles = buildOfficialRoleOptions(availableRoles);

    return BrandSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          title: const Text(
            'Staff Structure',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: const Padding(
            padding: EdgeInsets.only(top: 4),
            child: Text(
              'Open if you want to review category and role totals.',
              style: TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
          children: [
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _BreakdownChip(label: 'Official Staff', count: officialCount),
                _BreakdownChip(label: 'Canteen Tenant', count: canteenCount),
                _BreakdownChip(label: 'Stand Tenant', count: standCount),
              ],
            ),
            if (officialRoles.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'Official Roles',
                style: TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final role in officialRoles)
                    _BreakdownChip(
                      label: role,
                      count: members.where((member) => member.role == role).length,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AddStaffDialog extends StatefulWidget {
  const AddStaffDialog({
    required this.availableRoles,
    required this.lockedRoles,
    required this.onCreateRole,
    required this.onDeleteRole,
    super.key,
  });

  final List<String> availableRoles;
  final Set<String> lockedRoles;
  final Future<String> Function(String role) onCreateRole;
  final Future<void> Function(String role) onDeleteRole;

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _newRoleController = TextEditingController();
  final _unitNumberController = TextEditingController();
  late List<String> _officialRoles;
  late String _selectedRole;
  StaffType _selectedType = StaffType.officialStaff;
  bool _isManagingRoles = false;
  bool _isUpdatingRoles = false;
  String? _roleErrorMessage;

  @override
  void initState() {
    super.initState();
    _officialRoles = buildOfficialRoleOptions(widget.availableRoles);
    _selectedRole = _officialRoles.isEmpty ? 'Manager' : _officialRoles.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newRoleController.dispose();
    _unitNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff'),
      content: SizedBox(
        width: 440,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Enter the staff name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FBFF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE3EEF8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Staff Group',
                        style: TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final type in StaffType.values)
                            ChoiceChip(
                              label: Text(type.label),
                              selected: _selectedType == type,
                              onSelected: (_) {
                                setState(() {
                                  _selectedType = type;
                                  _roleErrorMessage = null;
                                });
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (_selectedType == StaffType.officialStaff)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: WaterparkBrand.lightBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7EAFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Role',
                            style: TextStyle(
                              color: WaterparkBrand.deepBlue,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _isUpdatingRoles
                                ? null
                                : () {
                              setState(() {
                                _isManagingRoles = !_isManagingRoles;
                              });
                            },
                            icon: Icon(
                              _isManagingRoles
                                  ? Icons.tune_rounded
                                  : Icons.edit_rounded,
                              size: 18,
                            ),
                            label: Text(
                              _isManagingRoles ? 'Done' : 'Manage roles',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Selected: $_selectedRole',
                        style: const TextStyle(
                          color: WaterparkBrand.primaryBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final role in _officialRoles)
                            ChoiceChip(
                              label: Text(role),
                              selected: role == _selectedRole,
                              onSelected: (_) {
                                setState(() {
                                  _selectedRole = role;
                                });
                              },
                              selectedColor: WaterparkBrand.primaryBlue
                                  .withValues(alpha: 0.15),
                              labelStyle: TextStyle(
                                color: role == _selectedRole
                                    ? WaterparkBrand.primaryBlue
                                    : WaterparkBrand.deepBlue,
                                fontWeight: FontWeight.w700,
                              ),
                              side: BorderSide(
                                color: role == _selectedRole
                                    ? WaterparkBrand.primaryBlue
                                    : const Color(0xFFD7EAFE),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_selectedType != StaffType.officialStaff) ...[
                  TextFormField(
                    controller: _unitNumberController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: _selectedType.unitLabel,
                      hintText: _selectedType == StaffType.canteenTenant
                          ? 'Example: 3'
                          : 'Example: 12',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_selectedType.requiresUnitNumber) {
                        return null;
                      }
                      final number = int.tryParse((value ?? '').trim());
                      if (number == null || number <= 0) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                ],
                if (_selectedType == StaffType.officialStaff && _isManagingRoles) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE3EEF8)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Manage Roles',
                          style: TextStyle(
                            color: WaterparkBrand.deepBlue,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Add a new role or remove one that is not being used yet.',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: WaterparkBrand.gray,
                                height: 1.4,
                              ),
                        ),
                        if (_roleErrorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            _roleErrorMessage!,
                            style: const TextStyle(
                              color: WaterparkBrand.accentRed,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _newRoleController,
                                enabled: !_isUpdatingRoles,
                                decoration: const InputDecoration(
                                  labelText: 'New role',
                                  border: OutlineInputBorder(),
                                ),
                                onFieldSubmitted: (_) => _handleAddRole(),
                              ),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.icon(
                              onPressed: _isUpdatingRoles
                                  ? null
                                  : _handleAddRole,
                              icon: const Icon(Icons.add_rounded),
                              label: Text(_isUpdatingRoles ? 'Saving' : 'Add'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final role in _officialRoles)
                              InputChip(
                                label: Text(role),
                                avatar: widget.lockedRoles.contains(role)
                                    ? const Icon(
                                        Icons.lock_rounded,
                                        size: 16,
                                        color: WaterparkBrand.gray,
                                      )
                                    : null,
                                onPressed: () {
                                  setState(() {
                                    _selectedRole = role;
                                  });
                                },
                                onDeleted:
                                    _isUpdatingRoles || !_canDeleteRole(role)
                                    ? null
                                    : () => _handleDeleteRole(role),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isUpdatingRoles
              ? null
              : () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            final unitNumber = _selectedType.requiresUnitNumber
                ? int.tryParse(_unitNumberController.text.trim())
                : null;
            Navigator.of(context).pop(
              StaffDraft(
                name: _nameController.text.trim(),
                staffType: _selectedType,
                role: _selectedType == StaffType.officialStaff
                    ? _selectedRole
                    : _selectedType.fixedRole,
                unitNumber: unitNumber,
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _handleAddRole() async {
    final role = _newRoleController.text.trim();
    if (role.isEmpty) {
      return;
    }

    final exists = _officialRoles.any(
      (existingRole) => existingRole.toLowerCase() == role.toLowerCase(),
    );

    if (exists) {
      setState(() {
        _roleErrorMessage = null;
        _selectedRole = _officialRoles.firstWhere(
          (existingRole) => existingRole.toLowerCase() == role.toLowerCase(),
        );
      });
      _newRoleController.clear();
      return;
    }

    setState(() {
      _isUpdatingRoles = true;
      _roleErrorMessage = null;
    });

    try {
      final createdRole = await widget.onCreateRole(role);
      if (!mounted) {
        return;
      }

      setState(() {
        _officialRoles = buildOfficialRoleOptions([..._officialRoles, createdRole]);
        _selectedRole = createdRole;
        _newRoleController.clear();
        _isUpdatingRoles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingRoles = false;
        _roleErrorMessage = 'Could not save role. $error';
      });
    }
  }

  bool _canDeleteRole(String role) {
    return _officialRoles.length > 1 &&
        !widget.lockedRoles.contains(role) &&
        role != _selectedRole;
  }

  Future<void> _handleDeleteRole(String role) async {
    if (!_canDeleteRole(role)) {
      return;
    }

    setState(() {
      _isUpdatingRoles = true;
      _roleErrorMessage = null;
    });

    try {
      await widget.onDeleteRole(role);
      if (!mounted) {
        return;
      }

      setState(() {
        _officialRoles = _officialRoles.where((entry) => entry != role).toList();
        if (_selectedRole == role && _officialRoles.isNotEmpty) {
          _selectedRole = _officialRoles.first;
        }
        _isUpdatingRoles = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isUpdatingRoles = false;
        _roleErrorMessage = 'Could not delete role. $error';
      });
    }
  }
}

enum QrDialogAction { generate, delete }

class StaffQrDialog extends StatefulWidget {
  const StaffQrDialog({
    required this.member,
    required this.onDownloadQr,
    super.key,
  });

  final StaffMember member;
  final Future<void> Function()? onDownloadQr;

  @override
  State<StaffQrDialog> createState() => _StaffQrDialogState();
}

class _StaffQrDialogState extends State<StaffQrDialog> {
  bool _isDownloading = false;

  Future<void> _confirmDeleteQr() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete QR'),
          content: Text(
            'Delete the QR code for ${widget.member.name}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: WaterparkBrand.accentRed,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldDelete != true) {
      return;
    }

    Navigator.of(context).pop(QrDialogAction.delete);
  }

  @override
  Widget build(BuildContext context) {
    final member = widget.member;
    final hasQr = member.hasQr;

    return AlertDialog(
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${member.name} QR',
                          style: const TextStyle(
                            color: WaterparkBrand.deepBlue,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${member.staffCode} • ${member.shortDescriptor}',
                          style: const TextStyle(
                            color: WaterparkBrand.gray,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (hasQr)
                  IconButton(
                    tooltip: 'Download QR',
                    onPressed: _isDownloading
                        ? null
                        : () async {
                            if (widget.onDownloadQr == null) {
                              return;
                            }
                            setState(() {
                              _isDownloading = true;
                            });
                            await widget.onDownloadQr!.call();
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _isDownloading = false;
                            });
                          },
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                  )
                else
                  const SizedBox(width: 48),
              ],
            ),
            const SizedBox(height: 12),
            if (hasQr) ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE3EEF8)),
                  ),
                  child: QrImageView(
                    data: member.qrPayload!,
                    size: 220,
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'QR payload',
                style: TextStyle(
                  color: WaterparkBrand.deepBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                member.qrPayload!,
                style: const TextStyle(
                  color: WaterparkBrand.gray,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ] else ...[
              const Text(
                'This staff member does not have a QR yet.',
                style: TextStyle(
                  color: WaterparkBrand.gray,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4FAFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE3EEF8)),
                ),
                child: const Text(
                  'Choose Generate QR to create a unique code for this person now.',
                  style: TextStyle(
                    color: WaterparkBrand.deepBlue,
                    height: 1.45,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                if (hasQr)
                  IconButton(
                    tooltip: 'Delete QR',
                    onPressed: _confirmDeleteQr,
                    icon: const Icon(Icons.delete_outline_rounded),
                  )
                else
                  IconButton(
                    tooltip: 'Generate QR',
                    onPressed: () =>
                        Navigator.of(context).pop(QrDialogAction.generate),
                    icon: const Icon(Icons.add_circle_outline_rounded),
                  ),
                const Spacer(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RoleChip extends StatelessWidget {
  const RoleChip({required this.role, super.key});

  final String role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: WaterparkBrand.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        role,
        style: const TextStyle(
          color: WaterparkBrand.primaryBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class TypeChip extends StatelessWidget {
  const TypeChip({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF7FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: WaterparkBrand.deepBlue,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BreakdownChip extends StatelessWidget {
  const _BreakdownChip({required this.label, required this.count});

  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: WaterparkBrand.lightBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.badge_outlined,
            color: WaterparkBrand.primaryBlue,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: WaterparkBrand.deepBlue,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$count',
            style: const TextStyle(
              color: WaterparkBrand.primaryBlue,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterFilterChip extends StatelessWidget {
  const _RosterFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? WaterparkBrand.primaryBlue : const Color(0xFFF4FAFF),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? WaterparkBrand.primaryBlue
                : const Color(0xFFDCEAF7),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : WaterparkBrand.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: selected
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: selected ? Colors.white : WaterparkBrand.primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge({required this.status, super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      'QR Ready' => (const Color(0xFFE7FAF0), WaterparkBrand.success),
      _ => (const Color(0xFFFFF4DA), WaterparkBrand.warning),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class StaffHeaderCell extends StatelessWidget {
  const StaffHeaderCell(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF6B829B),
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class StaffBodyCell extends StatelessWidget {
  const StaffBodyCell(this.text, {this.emphasis = false, super.key});

  final String text;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: WaterparkBrand.deepBlue,
        fontSize: emphasis ? 14 : 13,
        fontWeight: emphasis ? FontWeight.w700 : FontWeight.w500,
        height: 1.35,
      ),
    );
  }
}

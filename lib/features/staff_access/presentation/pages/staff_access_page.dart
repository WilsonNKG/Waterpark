import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:waterpark/core/config/app_config.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/staff_access/data/staff_repository.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

class StaffAccessPage extends StatefulWidget {
  const StaffAccessPage({super.key});

  @override
  State<StaffAccessPage> createState() => _StaffAccessPageState();
}

class _StaffAccessPageState extends State<StaffAccessPage> {
  StaffRepository? _repository;
  List<StaffMember> _staffMembers = const [];
  List<String> _roleOptions = buildStaffRoleOptions(const []);
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
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          const SupabaseSetupNotice(),
        ],
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          ErrorBanner(message: _errorMessage!, onRetry: _loadStaff),
          const SizedBox(height: 16),
        ],
        if (_isLoading)
          const BrandSurface(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: Center(child: CircularProgressIndicator()),
            ),
          )
        else ...[
          StaffRosterCard(
            members: _staffMembers,
            isSaving: _isSaving,
            onAddStaff: _handleAddStaff,
            onOpenQr: _showQrDialog,
            onDeleteQr: _deleteQr,
            onDeleteStaff: _confirmDeleteStaff,
          ),
          const SizedBox(height: 16),
          StaffRoleBreakdown(
            members: _staffMembers,
            availableRoles: _roleOptions,
          ),
        ],
      ],
    );
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
        lockedRoles: _staffMembers.map((member) => member.role).toSet(),
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
      builder: (context) => StaffQrDialog(member: member),
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
    return 'STAFF|${member.staffCode}|${member.name}|${member.role}';
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
          final compact = constraints.maxWidth < 900;

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
    required this.isSaving,
    required this.onAddStaff,
    required this.onOpenQr,
    required this.onDeleteQr,
    required this.onDeleteStaff,
    super.key,
  });

  final List<StaffMember> members;
  final bool isSaving;
  final VoidCallback onAddStaff;
  final ValueChanged<StaffMember> onOpenQr;
  final ValueChanged<StaffMember> onDeleteQr;
  final ValueChanged<StaffMember> onDeleteStaff;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'The main actions are here: add staff, view QR, delete QR only, or delete the staff record.',
                      style: TextStyle(color: WaterparkBrand.gray, height: 1.4),
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
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: 1120,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4FAFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Expanded(flex: 2, child: StaffHeaderCell('Code')),
                        Expanded(flex: 2, child: StaffHeaderCell('Name')),
                        Expanded(flex: 2, child: StaffHeaderCell('Role')),
                        Expanded(child: StaffHeaderCell('Status')),
                        Expanded(flex: 2, child: StaffHeaderCell('Actions')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (members.isEmpty)
                    const EmptyRosterCard()
                  else
                    for (final member in members) ...[
                      StaffRow(
                        member: member,
                        isSaving: isSaving,
                        onOpenQr: () => onOpenQr(member),
                        onDeleteQr: member.hasQr
                            ? () => onDeleteQr(member)
                            : null,
                        onDeleteStaff: () => onDeleteStaff(member),
                      ),
                      const SizedBox(height: 10),
                    ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyRosterCard extends StatelessWidget {
  const EmptyRosterCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF8)),
      ),
      child: const Text(
        'No staff yet. Add your first staff member to begin assigning access.',
        style: TextStyle(color: WaterparkBrand.gray, fontSize: 14),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE3EEF8)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: StaffBodyCell(member.staffCode)),
          Expanded(flex: 2, child: StaffBodyCell(member.name)),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: RoleChip(role: member.role),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: StaffStatusBadge(status: member.status),
            ),
          ),
          Expanded(
            flex: 2,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChipButton(
                  label: member.hasQr ? 'View QR' : 'Generate QR',
                  color: WaterparkBrand.primaryBlue,
                  onPressed: isSaving ? null : onOpenQr,
                ),
                ActionChipButton(
                  label: 'Delete QR',
                  color: WaterparkBrand.warning,
                  onPressed: isSaving ? null : onDeleteQr,
                ),
                ActionChipButton(
                  label: 'Delete Staff',
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
    required this.label,
    required this.color,
    required this.onPressed,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: onPressed == null
              ? const Color(0xFFF3F5F8)
              : color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: onPressed == null ? WaterparkBrand.gray : color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
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
    super.key,
  });

  final List<StaffMember> members;
  final List<String> availableRoles;

  @override
  Widget build(BuildContext context) {
    final knownRoles = buildStaffRoleOptions([
      ...availableRoles,
      ...members.map((member) => member.role),
    ]);

    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Role Breakdown',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compact totals so the table stays the main focus.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.4),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final role in knownRoles)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
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
                        role,
                        style: const TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${members.where((member) => member.role == role).length}',
                        style: const TextStyle(
                          color: WaterparkBrand.primaryBlue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
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
  late List<String> _roles;
  late String _selectedRole;
  bool _isManagingRoles = false;
  bool _isUpdatingRoles = false;
  String? _roleErrorMessage;

  @override
  void initState() {
    super.initState();
    _roles = buildStaffRoleOptions(widget.availableRoles);
    _selectedRole = _roles.first;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _newRoleController.dispose();
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
                          for (final role in _roles)
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
                if (_isManagingRoles) ...[
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
                            for (final role in _roles)
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
            Navigator.of(context).pop(
              StaffDraft(
                name: _nameController.text.trim(),
                role: _selectedRole,
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

    final exists = _roles.any(
      (existingRole) => existingRole.toLowerCase() == role.toLowerCase(),
    );

    if (exists) {
      setState(() {
        _roleErrorMessage = null;
        _selectedRole = _roles.firstWhere(
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
        _roles = buildStaffRoleOptions([..._roles, createdRole]);
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
    return _roles.length > 1 &&
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
        _roles = _roles.where((entry) => entry != role).toList();
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

class StaffQrDialog extends StatelessWidget {
  const StaffQrDialog({required this.member, super.key});

  final StaffMember member;

  @override
  Widget build(BuildContext context) {
    final hasQr = member.hasQr;

    return AlertDialog(
      title: Text('${member.name} QR'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${member.staffCode} • ${member.role}',
              style: const TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (hasQr)
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(QrDialogAction.delete),
            child: const Text('Delete QR'),
          )
        else
          FilledButton(
            onPressed: () => Navigator.of(context).pop(QrDialogAction.generate),
            child: const Text('Generate QR'),
          ),
      ],
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
  const StaffBodyCell(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: WaterparkBrand.deepBlue,
        fontSize: 13,
        height: 1.35,
      ),
    );
  }
}

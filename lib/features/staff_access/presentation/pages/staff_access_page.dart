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
  late final StaffRepository _repository = StaffRepository.create();
  List<StaffMember> _staffMembers = const [];
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
              : 'Supabase is not connected yet, so this page is using local sample data. The database setup files are ready below.',
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
          onAddStaff: _isSaving ? null : _handleAddStaff,
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
          StaffCategoryBreakdown(members: _staffMembers),
        ],
      ],
    );
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final staff = await _repository.fetchStaff();
      if (!mounted) {
        return;
      }
      setState(() {
        _staffMembers = staff;
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
      builder: (context) => const AddStaffDialog(),
    );

    if (draft == null) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final created = await _repository.createStaff(draft);
      if (!mounted) {
        return;
      }
      setState(() {
        _staffMembers = [..._staffMembers, created];
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
      await _repository.deleteStaff(member.id);
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

  Future<void> _deleteQr(StaffMember member) async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final updated = await _repository.deleteQr(member.id);
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
        final updated = await _repository.saveQr(member.id, payload);
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
    return 'STAFF|${member.staffCode}|${member.name}|${member.category.key}|${member.shift}';
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
                          value: isConnectedToSupabase ? 'Supabase' : 'Local',
                          color: isConnectedToSupabase
                              ? WaterparkBrand.aqua
                              : WaterparkBrand.gray,
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
                            value: isConnectedToSupabase ? 'Supabase' : 'Local',
                            color: isConnectedToSupabase
                                ? WaterparkBrand.aqua
                                : WaterparkBrand.gray,
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
            'This app is ready for Supabase, but you still need to create the table and run the app with SUPABASE_URL and SUPABASE_ANON_KEY.',
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
                        Expanded(child: StaffHeaderCell('Category')),
                        Expanded(child: StaffHeaderCell('Shift')),
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
          Expanded(flex: 2, child: StaffBodyCell(member.role)),
          Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: CategoryChip(category: member.category),
            ),
          ),
          Expanded(child: StaffBodyCell(member.shift)),
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

class StaffCategoryBreakdown extends StatelessWidget {
  const StaffCategoryBreakdown({required this.members, super.key});

  final List<StaffMember> members;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Category Breakdown',
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
              for (final category in StaffCategory.values)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(category.icon, color: category.color, size: 18),
                      const SizedBox(width: 10),
                      Text(
                        category.label,
                        style: const TextStyle(
                          color: WaterparkBrand.deepBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${members.where((member) => member.category == category).length}',
                        style: TextStyle(
                          color: category.color,
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
  const AddStaffDialog({super.key});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _roleController = TextEditingController();
  final _shiftController = TextEditingController(text: 'Morning');
  StaffCategory _selectedCategory = StaffCategory.operations;

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _shiftController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Staff'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _roleController,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the staff role';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<StaffCategory>(
                initialValue: _selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: StaffCategory.values
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() {
                    _selectedCategory = value;
                  });
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shiftController,
                decoration: const InputDecoration(
                  labelText: 'Shift',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter the shift';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) {
              return;
            }
            Navigator.of(context).pop(
              StaffDraft(
                name: _nameController.text.trim(),
                role: _roleController.text.trim(),
                category: _selectedCategory,
                shift: _shiftController.text.trim(),
              ),
            );
          },
          child: const Text('Create'),
        ),
      ],
    );
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
              '${member.staffCode} • ${member.category.label}',
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

class CategoryChip extends StatelessWidget {
  const CategoryChip({required this.category, super.key});

  final StaffCategory category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        category.label,
        style: TextStyle(
          color: category.color,
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

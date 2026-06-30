import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:waterpark/core/config/app_config.dart';
import 'package:waterpark/core/theme/waterpark_brand.dart';
import 'package:waterpark/features/qr_scan/domain/qr_scan_result.dart';
import 'package:waterpark/features/qr_scan/domain/staff_qr_validator.dart';
import 'package:waterpark/features/staff_access/data/staff_repository.dart';
import 'package:waterpark/features/staff_access/domain/staff_member.dart';
import 'package:waterpark/shared/widgets/brand_surface.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> {
  final StaffQrValidator _validator = const StaffQrValidator();
  final AudioPlayer _audioPlayer = AudioPlayer()..setReleaseMode(ReleaseMode.stop);
  final MobileScannerController _scannerController = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  final FocusNode _scannerInputFocusNode = FocusNode();

  StaffRepository? _repository;
  List<StaffMember> _staffMembers = const [];
  QrScanResult _result = const QrScanResult.idle();
  bool _isLoading = true;
  bool _isScannerActive = false;
  bool _isProcessingInput = false;
  String? _errorMessage;
  final StringBuffer _scannerBuffer = StringBuffer();
  DateTime? _lastScannerKeyAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scannerInputFocusNode.requestFocus();
      }
    });
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
    _scannerInputFocusNode.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'QR Scan',
          style: TextStyle(
            color: WaterparkBrand.deepBlue,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConfig.hasSupabase
              ? 'Scan a staff QR code using the device camera or a Bluetooth scanner in keyboard mode. The system verifies the QR payload against the staff database and flags invalid codes.'
              : 'Supabase is required for QR scanning. Configure the database first so the scanner can verify staff records.',
          style: const TextStyle(
            color: WaterparkBrand.gray,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ScanSummaryBar(
          staffCount: _staffMembers.length,
          isConnectedToSupabase: AppConfig.hasSupabase,
          scanStatus: _result.status,
        ),
        const SizedBox(height: 16),
        if (_errorMessage != null) ...[
          QrScanErrorBanner(message: _errorMessage!, onRetry: _loadStaff),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 980;
            final scannerCard = ScanCameraCard(
              isLoading: _isLoading,
              isScannerActive: _isScannerActive,
              scannerInputFocusNode: _scannerInputFocusNode,
              isProcessingInput: _isProcessingInput,
              onStartScan: _startScanner,
              onScanAgain: _restartScanner,
              onScannerKeyEvent: _handleScannerKeyEvent,
              onDetect: _handleDetection,
              controller: _scannerController,
            );
            final resultCard = ScanResultCard(
              result: _result,
              isLoading: _isLoading,
              onScanAgain: _restartScanner,
            );

            if (stacked) {
              return Column(
                children: [scannerCard, const SizedBox(height: 16), resultCard],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: scannerCard),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: resultCard),
              ],
            );
          },
        ),
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
      final staff = await _repository!.fetchStaff();
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
        _errorMessage = 'Could not load staff for QR validation. $error';
      });
    }
  }

  Future<void> _startScanner() async {
    if (_isLoading || _repository == null) {
      return;
    }

    setState(() {
      _result = const QrScanResult.idle();
      _errorMessage = null;
      _isScannerActive = true;
    });

    await _scannerController.start();
  }

  Future<void> _restartScanner() async {
    await _scannerController.stop();
    _scannerBuffer.clear();
    await _startScanner();
  }

  Future<void> _handleDetection(BarcodeCapture capture) async {
    if (!_isScannerActive) {
      return;
    }

    final firstCode = capture.barcodes.isEmpty
        ? null
        : capture.barcodes.first.rawValue;

    if (firstCode == null || firstCode.trim().isEmpty) {
      return;
    }

    await _scannerController.stop();
    await _processRawScan(firstCode.trim());
  }

  KeyEventResult _handleScannerKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isLoading || _isProcessingInput) {
      return KeyEventResult.ignored;
    }

    final now = DateTime.now();
    final elapsed = _lastScannerKeyAt == null
        ? null
        : now.difference(_lastScannerKeyAt!);
    _lastScannerKeyAt = now;

    if (elapsed != null && elapsed.inMilliseconds > 250) {
      _scannerBuffer.clear();
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final rawValue = _scannerBuffer.toString().trim();
      _scannerBuffer.clear();
      if (rawValue.isNotEmpty) {
        _scannerController.stop();
        _processRawScan(rawValue).whenComplete(() {
          if (mounted) {
            _scannerInputFocusNode.requestFocus();
          }
        });
      }
      return KeyEventResult.handled;
    }

    final character = event.character;
    if (character != null &&
        character.isNotEmpty &&
        !_isControlCharacter(character)) {
      _scannerBuffer.write(character);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  Future<void> _processRawScan(String rawValue) async {
    setState(() {
      _isProcessingInput = true;
    });

    final result = _validator.validate(
      rawValue: rawValue,
      staffMembers: _staffMembers,
    );

    await _playScanSound(result.status);

    if (!mounted) {
      return;
    }

    setState(() {
      _isScannerActive = false;
      _isProcessingInput = false;
      _result = result;
    });
  }

  Future<void> _playScanSound(QrScanStatus status) async {
    final assetPath = switch (status) {
      QrScanStatus.idle => null,
      QrScanStatus.validStaff => 'audio/qr_success.wav',
      QrScanStatus.unknownStaff ||
      QrScanStatus.invalidFormat ||
      QrScanStatus.tamperedData => 'audio/qr_failure.wav',
    };

    if (assetPath == null) {
      return;
    }

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(assetPath));
    } catch (_) {
      // Keep QR validation usable even if sound playback fails on a platform.
    }
  }
}

class ScanSummaryBar extends StatelessWidget {
  const ScanSummaryBar({
    required this.staffCount,
    required this.isConnectedToSupabase,
    required this.scanStatus,
    super.key,
  });

  final int staffCount;
  final bool isConnectedToSupabase;
  final QrScanStatus scanStatus;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          ScanPill(
            label: 'Database',
            value: isConnectedToSupabase ? 'Supabase' : 'Missing',
            color: isConnectedToSupabase
                ? WaterparkBrand.aqua
                : WaterparkBrand.accentRed,
          ),
          ScanPill(
            label: 'Staff Records',
            value: '$staffCount',
            color: WaterparkBrand.primaryBlue,
          ),
          ScanPill(
            label: 'Last Result',
            value: _labelForStatus(scanStatus),
            color: _colorForStatus(scanStatus),
          ),
        ],
      ),
    );
  }

  static String _labelForStatus(QrScanStatus status) {
    return switch (status) {
      QrScanStatus.idle => 'Waiting',
      QrScanStatus.validStaff => 'Valid',
      QrScanStatus.unknownStaff => 'Unknown',
      QrScanStatus.invalidFormat => 'Invalid',
      QrScanStatus.tamperedData => 'Mismatch',
    };
  }

  static Color _colorForStatus(QrScanStatus status) {
    return switch (status) {
      QrScanStatus.idle => WaterparkBrand.gray,
      QrScanStatus.validStaff => WaterparkBrand.success,
      QrScanStatus.unknownStaff => WaterparkBrand.warning,
      QrScanStatus.invalidFormat => WaterparkBrand.accentRed,
      QrScanStatus.tamperedData => WaterparkBrand.accentRed,
    };
  }
}

class ScanPill extends StatelessWidget {
  const ScanPill({
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

class ScanCameraCard extends StatelessWidget {
  const ScanCameraCard({
    required this.isLoading,
    required this.isScannerActive,
    required this.scannerInputFocusNode,
    required this.isProcessingInput,
    required this.onStartScan,
    required this.onScanAgain,
    required this.onScannerKeyEvent,
    required this.onDetect,
    required this.controller,
    super.key,
  });

  final bool isLoading;
  final bool isScannerActive;
  final FocusNode scannerInputFocusNode;
  final bool isProcessingInput;
  final Future<void> Function() onStartScan;
  final Future<void> Function() onScanAgain;
  final KeyEventResult Function(FocusNode node, KeyEvent event)
      onScannerKeyEvent;
  final void Function(BarcodeCapture capture) onDetect;
  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scanner Camera',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Use the system camera or a Bluetooth scanner to scan a staff QR. Camera scanning stops after detection so the result can be reviewed clearly.',
            style: TextStyle(color: WaterparkBrand.gray, height: 1.4),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FBFF),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE3EEF8)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Scanner Input',
                  style: TextStyle(
                    color: WaterparkBrand.deepBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Bluetooth scanner mode is armed here. Click once if needed, then scan. Input stays hidden and verifies immediately after Enter.',
                  style: TextStyle(
                    color: WaterparkBrand.gray,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Focus(
                  focusNode: scannerInputFocusNode,
                  onKeyEvent: onScannerKeyEvent,
                  child: ListenableBuilder(
                    listenable: scannerInputFocusNode,
                    builder: (context, _) {
                      final hasFocus = scannerInputFocusNode.hasFocus;
                      return InkWell(
                        onTap: () => scannerInputFocusNode.requestFocus(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: hasFocus
                                  ? WaterparkBrand.primaryBlue
                                  : const Color(0xFFDCEAF7),
                              width: hasFocus ? 1.6 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.qr_code_scanner_rounded),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  isProcessingInput
                                      ? 'Verifying scan...'
                                      : hasFocus
                                          ? 'Scanner ready. Scan now.'
                                          : 'Click here once to arm the Bluetooth scanner.',
                                  style: const TextStyle(
                                    color: WaterparkBrand.deepBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              if (isProcessingInput)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Icon(
                                  hasFocus
                                      ? Icons.radio_button_checked_rounded
                                      : Icons.center_focus_strong_rounded,
                                  color: hasFocus
                                      ? WaterparkBrand.success
                                      : WaterparkBrand.primaryBlue,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AspectRatio(
            aspectRatio: 16 / 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Container(
                color: const Color(0xFF0B2236),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (isScannerActive)
                      MobileScanner(controller: controller, onDetect: onDetect)
                    else
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0xFF0F3756), Color(0xFF071A29)],
                          ),
                        ),
                      ),
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Center(
                          child: Container(
                            width: 240,
                            height: 240,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.85),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!isScannerActive)
                      Positioned.fill(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.qr_code_scanner_rounded,
                                color: Colors.white,
                                size: 56,
                              ),
                              const SizedBox(height: 14),
                              Text(
                                isLoading
                                    ? 'Loading staff database...'
                                    : 'Camera is ready for staff scanning',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isLoading || isScannerActive ? null : onStartScan,
                icon: const Icon(Icons.videocam_rounded),
                label: const Text('Start Scan'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : onScanAgain,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Scan Again'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _isControlCharacter(String value) {
  return value.codeUnits.any((unit) => unit < 32 || unit == 127);
}

class ScanResultCard extends StatelessWidget {
  const ScanResultCard({
    required this.result,
    required this.isLoading,
    required this.onScanAgain,
    super.key,
  });

  final QrScanResult result;
  final bool isLoading;
  final Future<void> Function() onScanAgain;

  @override
  Widget build(BuildContext context) {
    final color = switch (result.status) {
      QrScanStatus.idle => WaterparkBrand.gray,
      QrScanStatus.validStaff => WaterparkBrand.success,
      QrScanStatus.unknownStaff => WaterparkBrand.warning,
      QrScanStatus.invalidFormat => WaterparkBrand.accentRed,
      QrScanStatus.tamperedData => WaterparkBrand.accentRed,
    };

    return BrandSurface(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Result',
            style: TextStyle(
              color: WaterparkBrand.deepBlue,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.title,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            style: const TextStyle(color: WaterparkBrand.gray, height: 1.45),
          ),
          if (result.staffMember != null) ...[
            const SizedBox(height: 16),
            ScanResultDetail(
              label: 'Staff Code',
              value: result.staffMember!.staffCode,
            ),
            ScanResultDetail(label: 'Name', value: result.staffMember!.name),
            ScanResultDetail(
              label: 'Group',
              value: result.staffMember!.groupLabel,
            ),
            ScanResultDetail(
              label: 'Assignment',
              value: result.staffMember!.assignmentLabel,
            ),
          ],
          if (result.rawValue != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Raw QR payload',
              style: TextStyle(
                color: WaterparkBrand.deepBlue,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            SelectableText(
              result.rawValue!,
              style: const TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: isLoading ? null : onScanAgain,
            icon: const Icon(Icons.center_focus_strong_rounded),
            label: const Text('Scan Another QR'),
          ),
        ],
      ),
    );
  }
}

class ScanResultDetail extends StatelessWidget {
  const ScanResultDetail({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            child: Text(
              label,
              style: const TextStyle(
                color: WaterparkBrand.gray,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: WaterparkBrand.deepBlue,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QrScanErrorBanner extends StatelessWidget {
  const QrScanErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

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

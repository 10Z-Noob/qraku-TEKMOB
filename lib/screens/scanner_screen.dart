import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/qr_history_item.dart';
import '../services/history_service.dart';
import '../theme.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with TickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController();
  bool _isScanning = true;
  String? _lastScanned;
  bool _torchOn = false;
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scanLineController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) async {
    if (!_isScanning) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    setState(() {
      _isScanning = false;
      _lastScanned = barcode!.rawValue;
    });

    HapticFeedback.mediumImpact();
    await _controller.stop();

    final item = QRHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _lastScanned!,
      type: QRType.scanned,
      createdAt: DateTime.now(),
      label: 'Scan',
    );
    await HistoryService().addItem(item);
  }

  void _reset() async {
    setState(() {
      _isScanning = true;
      _lastScanned = null;
    });
    await _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Scanner
          if (_isScanning) ...[
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            _ScanOverlay(scanLineController: _scanLineController),
            // Top bar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text('Scanner QR',
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                    ),
                    GestureDetector(
                      onTap: () async {
                        await _controller.toggleTorch();
                        setState(() => _torchOn = !_torchOn);
                      },
                      child: AnimatedContainer(
                        duration: 200.ms,
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _torchOn
                              ? AppTheme.accent.withValues(alpha: 0.9)
                              : const Color.fromARGB(255, 255, 255, 255).withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Icon(
                          _torchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Bottom hint
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text('Arahkan kamera ke QR code',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
                ),
              ),
            ),
          ],

          // Result panel
          if (!_isScanning && _lastScanned != null)
            _ResultPanel(
              scannedData: _lastScanned!,
              onRescan: _reset,
            ).animate().slideY(begin: 1, duration: 400.ms, curve: Curves.easeOut),
        ],
      ),
    );
  }
}

class _ScanOverlay extends StatelessWidget {
  final AnimationController scanLineController;

  const _ScanOverlay({required this.scanLineController});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const boxSize = 260.0;
        final left = (constraints.maxWidth - boxSize) / 2;
        final top = (constraints.maxHeight - boxSize) / 2 - 40;
        final right = left;
        final bottom = constraints.maxHeight - top - boxSize;
        const overlayColor = Color(0xAA000000);

        return Stack(
          children: [
            // Top panel
            Positioned(
              top: 0, left: 0, right: 0,
              height: top,
              child: const ColoredBox(color: overlayColor),
            ),
            // Bottom panel
            Positioned(
              bottom: 0, left: 0, right: 0,
              height: bottom,
              child: const ColoredBox(color: overlayColor),
            ),
            // Left panel (middle strip)
            Positioned(
              top: top, left: 0,
              width: left,
              height: boxSize,
              child: const ColoredBox(color: overlayColor),
            ),
            // Right panel (middle strip)
            Positioned(
              top: top, right: 0,
              width: right,
              height: boxSize,
              child: const ColoredBox(color: overlayColor),
            ),
            // Corner brackets
            Positioned(
              left: left,
              top: top,
              child: const _CornerBrackets(size: boxSize),
            ),
            // Scan line
            Positioned(
              left: left + 16,
              top: top,
              width: boxSize - 32,
              height: boxSize,
              child: AnimatedBuilder(
                animation: scanLineController,
                builder: (context, child) {
                  return Align(
                    alignment: Alignment(0, scanLineController.value * 2 - 1),
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppTheme.accent.withValues(alpha: 0),
                            AppTheme.accent,
                            AppTheme.accentLight,
                            AppTheme.accent,
                            AppTheme.accent.withValues(alpha: 0),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CornerBrackets extends StatelessWidget {
  final double size;
  const _CornerBrackets({required this.size});

  @override
  Widget build(BuildContext context) {
    const cornerSize = 28.0;
    const strokeWidth = 3.0;
    return SizedBox(
      width: size,
      height: size,
      child: const Stack(
        children: [
          // Top-left
          Positioned(
            top: 0,
            left: 0,
            child: _Corner(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
              top: true,
              left: true,
              size: cornerSize,
              stroke: strokeWidth,
            ),
          ),
          // Top-right
          Positioned(
            top: 0,
            right: 0,
            child: _Corner(
              borderRadius: BorderRadius.only(topRight: Radius.circular(10)),
              top: true,
              left: false,
              size: cornerSize,
              stroke: strokeWidth,
            ),
          ),
          // Bottom-left
          Positioned(
            bottom: 0,
            left: 0,
            child: _Corner(
              borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10)),
              top: false,
              left: true,
              size: cornerSize,
              stroke: strokeWidth,
            ),
          ),
          // Bottom-right
          Positioned(
            bottom: 0,
            right: 0,
            child: _Corner(
              borderRadius: BorderRadius.only(bottomRight: Radius.circular(10)),
              top: false,
              left: false,
              size: cornerSize,
              stroke: strokeWidth,
            ),
          ),
        ],
      ),
    );
  }
}

class _Corner extends StatelessWidget {
  final BorderRadius borderRadius;
  final bool top;
  final bool left;
  final double size;
  final double stroke;

  const _Corner({
    required this.borderRadius,
    required this.top,
    required this.left,
    required this.size,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border(
          top: top ? BorderSide(color: AppTheme.accentLight, width: stroke) : BorderSide.none,
          bottom: !top ? BorderSide(color: AppTheme.accentLight, width: stroke) : BorderSide.none,
          left: left ? BorderSide(color: AppTheme.accentLight, width: stroke) : BorderSide.none,
          right: !left ? BorderSide(color: AppTheme.accentLight, width: stroke) : BorderSide.none,
        ),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final String scannedData;
  final VoidCallback onRescan;

  const _ResultPanel({required this.scannedData, required this.onRescan});

  bool get _isUrl => scannedData.startsWith('http') || scannedData.startsWith('https');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.mint.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppTheme.mint, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('QR Berhasil Dipindai!',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 20,
                          )),
                      Text('Tersimpan ke riwayat',
                          style: GoogleFonts.inter(color: AppTheme.mint, fontSize: 13)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hasil Scan',
                        style: GoogleFonts.inter(
                            color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text(scannedData,
                        style: GoogleFonts.firaCode(
                          color: AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.5,
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.copy_rounded,
                      label: 'Salin',
                      color: AppTheme.card,
                      textColor: AppTheme.textPrimary,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: scannedData));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Disalin ke clipboard!', style: GoogleFonts.inter()),
                            backgroundColor: AppTheme.surface,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  if (_isUrl)
                    Expanded(
                      child: _ActionButton(
                        icon: Icons.open_in_browser_rounded,
                        label: 'Buka URL',
                        color: AppTheme.accent,
                        textColor: Colors.white,
                        onTap: () {},
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: onRescan,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accent, Color(0xFF5B21B6)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 20),
                        const SizedBox(width: 10),
                        Text('Scan Lagi',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 18),
            const SizedBox(width: 8),
            Text(label, style: GoogleFonts.inter(color: textColor, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

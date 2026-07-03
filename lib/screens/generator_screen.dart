import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/qr_history_item.dart';
import '../services/history_service.dart';
import '../theme.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _labelController = TextEditingController();
  String _qrData = '';
  String _selectedType = 'Text';
  bool _saved = false;

  final List<Map<String, dynamic>> _types = [
    {'label': 'Text', 'icon': Icons.text_fields_rounded, 'hint': 'Masukkan teks apapun'},
    {'label': 'URL', 'icon': Icons.link_rounded, 'hint': 'https://example.com'},
    {'label': 'Email', 'icon': Icons.email_rounded, 'hint': 'email@example.com'},
    {'label': 'Telepon', 'icon': Icons.phone_rounded, 'hint': '+628123456789'},
    {'label': 'WiFi', 'icon': Icons.wifi_rounded, 'hint': 'SSID:Password'},
  ];

  String _buildQRContent(String input) {
    switch (_selectedType) {
      case 'URL':
        if (!input.startsWith('http')) return 'https://$input';
        return input;
      case 'Email':
        return 'mailto:$input';
      case 'Telepon':
        return 'tel:$input';
      case 'WiFi':
        final parts = input.split(':');
        if (parts.length >= 2) {
          return 'WIFI:S:${parts[0]};T:WPA;P:${parts.sublist(1).join(':')};';
        }
        return input;
      default:
        return input;
    }
  }

  Future<void> _saveToHistory() async {
    if (_qrData.isEmpty) return;
    final item = QRHistoryItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _qrData,
      type: QRType.generated,
      createdAt: DateTime.now(),
      label: _labelController.text.isEmpty ? _selectedType : _labelController.text,
    );
    await HistoryService().addItem(item);
    setState(() => _saved = true);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tersimpan ke riwayat!', style: GoogleFonts.inter()),
          backgroundColor: AppTheme.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('Generator QR',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  )).animate().fadeIn(duration: 400.ms).slideY(begin: -0.2),
              const SizedBox(height: 4),
              Text('Buat QR code dari berbagai jenis konten',
                  style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 24),

              // Type selector
              SizedBox(
                height: 48,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _types.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = _types[i];
                    final selected = _selectedType == t['label'];
                    return GestureDetector(
                      onTap: () => setState(() {
                        _selectedType = t['label'];
                        _controller.clear();
                        _qrData = '';
                        _saved = false;
                      }),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent : AppTheme.card,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: selected ? AppTheme.accent : AppTheme.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(t['icon'] as IconData,
                                size: 16,
                                color: selected ? Colors.white : AppTheme.textSecondary),
                            const SizedBox(width: 6),
                            Text(t['label'],
                                style: GoogleFonts.inter(
                                  color: selected ? Colors.white : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                )),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 20),

              // Input fields
              _buildInputField(
                controller: _controller,
                hint: _types.firstWhere((t) => t['label'] == _selectedType)['hint'],
                icon: _types.firstWhere((t) => t['label'] == _selectedType)['icon'],
                onChanged: (v) => setState(() {
                  _qrData = v.isEmpty ? '' : _buildQRContent(v);
                  _saved = false;
                }),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 12),

              _buildInputField(
                controller: _labelController,
                hint: 'Label (opsional)',
                icon: Icons.label_outline_rounded,
                onChanged: (_) => setState(() => _saved = false),
              ).animate().fadeIn(delay: 250.ms),

              const SizedBox(height: 28),

              // QR Display
              if (_qrData.isNotEmpty)
                _QRDisplay(
                  data: _qrData,
                  saved: _saved,
                  onSave: _saveToHistory,
                ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.8, 0.8)),

              if (_qrData.isEmpty)
                _EmptyQRPlaceholder()
                    .animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ValueChanged<String> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
          prefixIcon: Icon(icon, color: AppTheme.accentLight, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _QRDisplay extends StatelessWidget {
  final String data;
  final bool saved;
  final VoidCallback onSave;

  const _QRDisplay({required this.data, required this.saved, required this.onSave});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.card,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.border),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accent.withValues(alpha: 0.15),
                blurRadius: 40,
                spreadRadius: -5,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: QrImageView(
                  data: data,
                  version: QrVersions.auto,
                  size: 200,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF0A0E1A),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF0A0E1A),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                data.length > 40 ? '${data.substring(0, 40)}...' : data,
                style: GoogleFonts.firaCode(
                  color: AppTheme.textSecondary,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: data));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Disalin!', style: GoogleFonts.inter()),
                      backgroundColor: AppTheme.surface,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.copy_rounded, color: AppTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Text('Salin', style: GoogleFonts.inter(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: saved ? null : onSave,
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: saved
                        ? const LinearGradient(colors: [AppTheme.mint, Color(0xFF059669)])
                        : const LinearGradient(colors: [AppTheme.accent, Color(0xFF5B21B6)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(saved ? Icons.check_rounded : Icons.bookmark_add_outlined,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(saved ? 'Tersimpan' : 'Simpan',
                          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmptyQRPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border, style: BorderStyle.solid),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.qr_code_2_rounded, color: AppTheme.accentLight, size: 40),
          ),
          const SizedBox(height: 16),
          Text('QR Code muncul di sini',
              style: GoogleFonts.spaceGrotesk(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              )),
          const SizedBox(height: 6),
          Text('Ketik sesuatu di atas untuk mulai',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}

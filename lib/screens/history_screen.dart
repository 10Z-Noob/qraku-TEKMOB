import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_history_item.dart';
import '../services/history_service.dart';
import '../theme.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<QRHistoryItem> _items = [];
  bool _loading = true;
  String _filter = 'Semua';
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await HistoryService().getHistory();
    setState(() => _loading = false);
  }

  List<QRHistoryItem> get _filtered {
    return _items.where((item) {
      final matchFilter = _filter == 'Semua' ||
          (_filter == 'Dibuat' && item.type == QRType.generated) ||
          (_filter == 'Dipindai' && item.type == QRType.scanned);
      final matchSearch = _search.isEmpty ||
          item.content.toLowerCase().contains(_search.toLowerCase()) ||
          (item.label?.toLowerCase().contains(_search.toLowerCase()) ?? false);
      return matchFilter && matchSearch;
    }).toList();
  }

  Future<void> _delete(String id) async {
    await HistoryService().deleteItem(id);
    _load();
  }

  Future<void> _clearAll() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Hapus Semua?',
            style: GoogleFonts.spaceGrotesk(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        content: Text('Semua riwayat akan dihapus secara permanen.',
            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: GoogleFonts.inter(color: AppTheme.error, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await HistoryService().clearHistory();
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Riwayat',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          )),
                      Text('${_items.length} item tersimpan',
                          style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                  if (_items.isNotEmpty)
                    GestureDetector(
                      onTap: _clearAll,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.error.withValues(alpha: 0.3)),
                        ),
                        child: Text('Hapus Semua',
                            style: GoogleFonts.inter(
                              color: AppTheme.error,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            )),
                      ),
                    ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            ),
            const SizedBox(height: 16),

            // Search
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _search = v),
                  style: GoogleFonts.inter(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Cari riwayat...',
                    hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary.withValues(alpha: 0.6)),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() => _search = '');
                            },
                            child: const Icon(Icons.close_rounded, color: AppTheme.textSecondary, size: 18),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),
            const SizedBox(height: 12),

            // Filter chips
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['Semua', 'Dibuat', 'Dipindai'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: 200.ms,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? AppTheme.accent : AppTheme.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? AppTheme.accent : AppTheme.border),
                        ),
                        child: Text(f,
                            style: GoogleFonts.inter(
                              color: selected ? Colors.white : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ),
                    ),
                  );
                }).toList(),
              ).animate().fadeIn(delay: 150.ms),
            ),
            const SizedBox(height: 16),

            // List
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                  : _filtered.isEmpty
                      ? _EmptyState(isSearch: _search.isNotEmpty)
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppTheme.accent,
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, i) {
                              return _HistoryCard(
                                item: _filtered[i],
                                onDelete: () => _delete(_filtered[i].id),
                                index: i,
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final QRHistoryItem item;
  final VoidCallback onDelete;
  final int index;

  const _HistoryCard({required this.item, required this.onDelete, required this.index});

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isGenerated = widget.item.type == QRType.generated;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: 300.ms,
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? AppTheme.accent.withValues(alpha: 0.4) : AppTheme.border,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isGenerated
                          ? AppTheme.accent.withValues(alpha: 0.12)
                          : AppTheme.mint.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isGenerated ? Icons.qr_code_rounded : Icons.qr_code_scanner_rounded,
                      color: isGenerated ? AppTheme.accentLight : AppTheme.mint,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isGenerated
                                    ? AppTheme.accent.withValues(alpha: 0.12)
                                    : AppTheme.mint.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isGenerated ? 'DIBUAT' : 'DIPINDAI',
                                style: GoogleFonts.inter(
                                  color: isGenerated ? AppTheme.accentLight : AppTheme.mint,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(widget.item.label ?? '',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.item.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.firaCode(
                              color: AppTheme.textPrimary, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(_timeAgo(widget.item.createdAt),
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary.withValues(alpha: 0.6), fontSize: 11)),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: AppTheme.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),

            // Expanded content
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  children: [
                    Container(
                      height: 1,
                      color: AppTheme.border,
                      margin: const EdgeInsets.only(bottom: 14),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Mini QR
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: QrImageView(
                            data: widget.item.content,
                            version: QrVersions.auto,
                            size: 80,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Konten:',
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary, fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(
                                widget.item.content,
                                style: GoogleFonts.firaCode(
                                    color: AppTheme.textPrimary, fontSize: 12, height: 1.4),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _MiniBtn(
                                    icon: Icons.copy_rounded,
                                    label: 'Salin',
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: widget.item.content));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Disalin!', style: GoogleFonts.inter()),
                                          backgroundColor: AppTheme.surface,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12)),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                  _MiniBtn(
                                    icon: Icons.delete_outline_rounded,
                                    label: 'Hapus',
                                    color: AppTheme.error.withValues(alpha: 0.12),
                                    textColor: AppTheme.error,
                                    onTap: widget.onDelete,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms),
          ],
        ),
      ),
    ).animate(delay: Duration(milliseconds: widget.index * 50)).fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class _MiniBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? textColor;

  const _MiniBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: color ?? AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: textColor ?? AppTheme.textSecondary),
            const SizedBox(width: 5),
            Text(label,
                style: GoogleFonts.inter(
                  color: textColor ?? AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                )),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isSearch;
  const _EmptyState({required this.isSearch});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.border),
            ),
            child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.history_rounded,
              color: AppTheme.textSecondary,
              size: 40,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            isSearch ? 'Tidak ditemukan' : 'Belum ada riwayat',
            style: GoogleFonts.spaceGrotesk(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearch ? 'Coba kata kunci lain' : 'Buat atau scan QR code\nuntuk mulai mencatat',
            style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn(duration: 400.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

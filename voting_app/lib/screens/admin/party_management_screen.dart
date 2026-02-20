import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class PartyManagementScreen extends StatefulWidget {
  const PartyManagementScreen({super.key});

  @override
  State<PartyManagementScreen> createState() => _PartyManagementScreenState();
}

class _PartyManagementScreenState extends State<PartyManagementScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _parties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadParties();
  }

  Future<void> _loadParties() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getParties();
      setState(() {
        _parties = result['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    File? symbolFile;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Add Party', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Symbol upload
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 400);
                      if (picked != null) {
                        setDialogState(() => symbolFile = File(picked.path));
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.dividerColor, width: 2),
                        image: symbolFile != null
                            ? DecorationImage(image: FileImage(symbolFile!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: symbolFile == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.image_rounded, color: AppTheme.textLight, size: 24),
                                const SizedBox(height: 4),
                                Text('Symbol', style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textLight)),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Party Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty) return;
                  try {
                    await _api.createParty(nameCtrl.text, descCtrl.text, symbol: symbolFile);
                    Navigator.pop(ctx);
                    _loadParties();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Party created successfully'),
                          backgroundColor: AppTheme.successColor,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
                    );
                  }
                },
                child: const Text('Create'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Party Management', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text('Add Party', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadParties,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _parties.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_rounded, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No parties added yet',
                            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _parties.length,
                    itemBuilder: (context, index) => _buildPartyCard(_parties[index]),
                  ),
      ),
    );
  }

  Widget _buildPartyCard(Map<String, dynamic> party) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              image: party['symbol'] != null
                  ? DecorationImage(
                      image: NetworkImage(_api.getImageUrl(party['symbol'])),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: party['symbol'] == null
                ? Icon(Icons.flag_rounded, color: AppTheme.primaryColor.withOpacity(0.5), size: 28)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  party['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (party['description'] != null && party['description'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    party['description'],
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 22),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Delete Party?'),
                  content: Text('Are you sure you want to delete "${party['name']}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Delete', style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await _api.deleteParty(party['id']);
                  _loadParties();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class CandidateManagementScreen extends StatefulWidget {
  final int electionId;
  final String electionName;

  const CandidateManagementScreen({
    super.key,
    required this.electionId,
    required this.electionName,
  });

  @override
  State<CandidateManagementScreen> createState() => _CandidateManagementScreenState();
}

class _CandidateManagementScreenState extends State<CandidateManagementScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _candidates = [];
  List<dynamic> _parties = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final candidatesResult = await _api.getCandidates(electionId: widget.electionId);
      final partiesResult = await _api.getParties();
      setState(() {
        _candidates = candidatesResult['results'] ?? [];
        _parties = partiesResult['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showAddCandidateDialog() {
    final nameCtrl = TextEditingController();
    final bioCtrl = TextEditingController();
    int? selectedPartyId;
    XFile? photoXFile;
    Uint8List? photoPreviewBytes;

    if (_parties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please add parties first'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Add Candidate', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Photo upload
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialogState(() {
                          photoXFile = picked;
                          photoPreviewBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.dividerColor, width: 2),
                      ),
                      child: photoPreviewBytes != null
                          ? ClipOval(
                              child: Image.memory(photoPreviewBytes!, fit: BoxFit.cover, width: 80, height: 80),
                            )
                          : const Icon(Icons.person_add_rounded, color: AppTheme.textLight, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Candidate Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Party'),
                    value: selectedPartyId,
                    items: _parties.map<DropdownMenuItem<int>>((party) {
                      return DropdownMenuItem<int>(
                        value: party['id'],
                        child: Text(party['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPartyId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    decoration: const InputDecoration(labelText: 'Bio (optional)'),
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
                  if (nameCtrl.text.isEmpty || selectedPartyId == null) return;
                  try {
                    final data = {
                      'name': nameCtrl.text,
                      'election': widget.electionId.toString(),
                      'party': selectedPartyId.toString(),
                      'bio': bioCtrl.text,
                    };
                    
                    if (kIsWeb && photoPreviewBytes != null) {
                      await _api.createCandidate(data,
                        photoBytes: photoPreviewBytes!.toList(),
                        photoName: photoXFile?.name ?? 'photo.jpg',
                      );
                    } else {
                      File? photoFile;
                      if (photoXFile != null) {
                        photoFile = File(photoXFile!.path);
                      }
                      await _api.createCandidate(data, photo: photoFile);
                    }
                    
                    Navigator.pop(ctx);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Candidate added successfully'),
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
                child: const Text('Add'),
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Candidates', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700)),
            Text(
              widget.electionName,
              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddCandidateDialog,
        icon: const Icon(Icons.person_add_rounded),
        label: Text('Add Candidate', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _candidates.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_off_rounded, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No candidates added yet',
                            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Text('Tap + to add candidates',
                            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textLight)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _candidates.length,
                    itemBuilder: (context, index) => _buildCandidateCard(_candidates[index]),
                  ),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
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
          // Candidate photo
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
              image: candidate['photo'] != null
                  ? DecorationImage(
                      image: NetworkImage(_api.getImageUrl(candidate['photo'])),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: candidate['photo'] == null
                ? Center(
                    child: Text(
                      (candidate['name'] ?? 'C')[0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  candidate['name'] ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Party symbol
                    if (candidate['party_symbol'] != null)
                      Container(
                        width: 20,
                        height: 20,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          image: DecorationImage(
                            image: NetworkImage(_api.getImageUrl(candidate['party_symbol'])),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    Text(
                      candidate['party_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.accentColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (candidate['bio'] != null && candidate['bio'].isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    candidate['bio'],
                    style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          Column(
            children: [
              Text(
                '${candidate['votes_count'] ?? 0}',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              ),
              Text(
                'votes',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textLight),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor, size: 20),
            onPressed: () => _showEditCandidateDialog(candidate),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Remove Candidate?'),
                  content: Text('Remove "${candidate['name']}" from this election?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Remove', style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                try {
                  await _api.deleteCandidate(candidate['id']);
                  _loadData();
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

  void _showEditCandidateDialog(Map<String, dynamic> candidate) {
    final nameCtrl = TextEditingController(text: candidate['name']);
    final bioCtrl = TextEditingController(text: candidate['bio']);
    int? selectedPartyId;
    
    if (candidate['party'] is Map) {
       selectedPartyId = candidate['party']['id'];
    } else {
       selectedPartyId = candidate['party'];
    }

    XFile? photoXFile;
    Uint8List? photoPreviewBytes;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Edit Candidate', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
                      if (picked != null) {
                        final bytes = await picked.readAsBytes();
                        setDialogState(() {
                          photoXFile = picked;
                          photoPreviewBytes = bytes;
                        });
                      }
                    },
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.dividerColor, width: 2),
                      ),
                      child: photoPreviewBytes != null
                          ? ClipOval(
                              child: Image.memory(photoPreviewBytes!, fit: BoxFit.cover, width: 80, height: 80),
                            )
                          : candidate['photo'] != null
                              ? ClipOval(
                                  child: Image.network(
                                    _api.getImageUrl(candidate['photo']),
                                    fit: BoxFit.cover, width: 80, height: 80,
                                  ),
                                )
                              : const Icon(Icons.person_outline_rounded, color: AppTheme.textLight, size: 28),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Candidate Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(labelText: 'Select Party'),
                    value: selectedPartyId,
                    items: _parties.map<DropdownMenuItem<int>>((party) {
                      return DropdownMenuItem<int>(
                        value: party['id'],
                        child: Text(party['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setDialogState(() => selectedPartyId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: bioCtrl,
                    decoration: const InputDecoration(labelText: 'Bio (optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.isEmpty || selectedPartyId == null) return;
                  try {
                    final data = {
                      'name': nameCtrl.text,
                      'election': widget.electionId.toString(),
                      'party': selectedPartyId.toString(),
                      'bio': bioCtrl.text,
                    };
                    
                    if (kIsWeb && photoPreviewBytes != null) {
                      await _api.updateCandidate(candidate['id'], data,
                        photoBytes: photoPreviewBytes!.toList(),
                        photoName: photoXFile?.name ?? 'photo.jpg',
                      );
                    } else {
                      File? photoFile;
                      if (photoXFile != null) {
                        photoFile = File(photoXFile!.path);
                      }
                      await _api.updateCandidate(candidate['id'], data, photo: photoFile);
                    }
                    
                    Navigator.pop(ctx);
                    _loadData();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Candidate updated successfully')),
                      );
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}

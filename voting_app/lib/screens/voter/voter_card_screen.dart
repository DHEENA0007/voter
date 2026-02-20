import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class VoterCardScreen extends StatefulWidget {
  const VoterCardScreen({super.key});

  @override
  State<VoterCardScreen> createState() => _VoterCardScreenState();
}

class _VoterCardScreenState extends State<VoterCardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _profile;
  List<dynamic> _corrections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _api.getVoterProfile();
      final corrections = await _api.getCorrections();
      setState(() {
        _profile = profile;
        _corrections = corrections['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showCorrectionDialog() {
    final nameCtrl = TextEditingController(text: _profile?['full_name']);
    final fatherCtrl = TextEditingController(text: _profile?['father_name']);
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                Icon(Icons.edit_note_rounded, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Text('Request Correction', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Submit the correct spelling below. An administrator will review and update your card.',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: fatherCtrl,
                  decoration: InputDecoration(
                    labelText: "Father's / Husband's Name",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: isSubmitting ? null : () async {
                  setDialogState(() => isSubmitting = true);
                  try {
                    await _api.submitCorrection({
                      'requested_full_name': nameCtrl.text.trim(),
                      'requested_father_name': fatherCtrl.text.trim(),
                    });
                    Navigator.pop(ctx);
                    _loadProfile();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Correction request submitted!')),
                    );
                  } catch (e) {
                    setDialogState(() => isSubmitting = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: isSubmitting 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Submit', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _downloadVoterCard() async {
    if (_profile == null) return;

    final pdf = pw.Document();

    // Fetch photo bytes if available
    Uint8List? photoBytes;
    if (_profile!['photo'] != null) {
      try {
        final response = await http.get(Uri.parse(_api.getImageUrl(_profile!['photo'])));
        if (response.statusCode == 200) {
          photoBytes = response.bodyBytes;
        }
      } catch (e) {
        print('Error fetching photo: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              width: 350,
              height: 220,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.black, width: 2),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                children: [
                  // Header
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(vertical: 5),
                    decoration: const pw.BoxDecoration(
                      color: PdfColors.blue900,
                      borderRadius: pw.BorderRadius.only(
                        topLeft: pw.Radius.circular(8),
                        topRight: pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Center(
                      child: pw.Text(
                        'ELECTION COMMISSION OF INDIA',
                        style: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(10),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // Photo
                          pw.Container(
                            width: 80,
                            height: 100,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey),
                            ),
                            child: photoBytes != null
                                ? pw.Image(pw.MemoryImage(photoBytes))
                                : pw.Center(child: pw.Text('PHOTO')),
                          ),
                          pw.SizedBox(width: 15),
                          // Details
                          pw.Expanded(
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                _pdfRow('EPIC NO:', _profile!['voter_id'] ?? 'N/A', bold: true),
                                pw.SizedBox(height: 5),
                                _pdfRow('Name:', _profile!['full_name'] ?? ''),
                                pw.SizedBox(height: 3),
                                _pdfRow('Father\'s Name:', _profile!['father_name'] ?? ''),
                                pw.SizedBox(height: 3),
                                _pdfRow('Gender:', _profile!['gender'] == 'M' ? 'Male' : (_profile!['gender'] == 'F' ? 'Female' : 'Other')),
                                pw.SizedBox(height: 3),
                                _pdfRow('D.O.B:', _profile!['date_of_birth'] ?? ''),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Footer / Address area
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    width: double.infinity,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    child: pw.Text(
                      'Address: ${_profile!['address'] ?? ''}',
                      style: const pw.TextStyle(fontSize: 8),
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }

  pw.Widget _pdfRow(String label, String value, {bool bold = false}) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 70,
          child: pw.Text(label, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Expanded(
          child: pw.Text(value, style: pw.TextStyle(fontSize: 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = _profile?['status'] ?? 'pending';
    final isApproved = status == 'approved';

    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('My Voter Card', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profile == null
              ? const Center(child: Text('Profile not found'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStatusBanner(status),
                      const SizedBox(height: 30),
                      
                      // Mock Voter Card Preview
                      if (isApproved)
                        _buildVoterCardPreview()
                      else
                        _buildPendingState(),

                      const SizedBox(height: 24),
                      
                      _buildCorrectionStatus(),

                      const SizedBox(height: 32),

                      if (isApproved)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: _downloadVoterCard,
                            icon: const Icon(Icons.download_rounded),
                            label: Text('Download Digital Voter Card', 
                              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      
                      const SizedBox(height: 20),
                      if (isApproved)
                        TextButton.icon(
                          onPressed: _showCorrectionDialog,
                          icon: const Icon(Icons.edit_note_rounded),
                          label: Text('Request Spelling Correction', 
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.primaryColor)),
                        ),
                      
                      const SizedBox(height: 20),
                      Text(
                        'This digital card can be used for verification purposes where applicable.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'approved':
        color = AppTheme.successColor;
        icon = Icons.check_circle_rounded;
        text = 'Verified Voter';
        break;
      case 'rejected':
        color = AppTheme.errorColor;
        icon = Icons.cancel_rounded;
        text = 'Application Rejected';
        break;
      case 'blocked':
        color = Colors.grey;
        icon = Icons.block_flipped;
        text = 'Account Blocked';
        break;
      default:
        color = Colors.orange;
        icon = Icons.pending_rounded;
        text = 'Verification Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.inter(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoterCardPreview() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: Colors.blue.shade900, width: 2),
      ),
      child: Column(
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: Colors.blue.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Center(
              child: Text(
                'ELECTION COMMISSION OF INDIA',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Photo
                Column(
                  children: [
                    Container(
                      width: 90,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey.shade300),
                        image: _profile!['photo'] != null
                            ? DecorationImage(
                                image: NetworkImage(_api.getImageUrl(_profile!['photo'])),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: _profile!['photo'] == null
                          ? const Icon(Icons.person_rounded, size: 40, color: Colors.grey)
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // EPIC Number / Voter ID
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        _profile!['voter_id'] ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Colors.blue.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // Voter Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardDetail('NAME', _profile!['full_name']),
                      _cardDetail('FATHER\'S NAME', _profile!['father_name']),
                      Row(
                        children: [
                          Expanded(child: _cardDetail('GENDER', _profile!['gender'] == 'M' ? 'Male' : (_profile!['gender'] == 'F' ? 'Female' : 'Other'))),
                          Expanded(child: _cardDetail('DOB', _profile!['date_of_birth'])),
                        ],
                      ),
                      _cardDetail('ADDRESS', _profile!['address'], isMultiLine: true),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Bottom Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DIGITAL VOTER CARD', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey)),
                    Text('SECURE BIOMETRIC SYSTEM', style: GoogleFonts.inter(fontSize: 8, color: Colors.grey)),
                  ],
                ),
                const Icon(Icons.qr_code_2_rounded, size: 32, color: Colors.black87),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cardDetail(String label, dynamic value, {bool isMultiLine = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value?.toString() ?? 'N/A',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
            maxLines: isMultiLine ? 2 : 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPendingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_empty_rounded, size: 64, color: Colors.orange.shade300),
          const SizedBox(height: 20),
          Text(
            'Under Review',
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          Text(
            'Your voter card application is currently being reviewed by the administration. You will be able to download your card once it is approved.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCorrectionStatus() {
    final pending = _corrections.where((c) => c['status'] == 'pending').toList();
    if (pending.isEmpty) return const SizedBox.shrink();

    final last = pending.first;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.update_rounded, color: Colors.amber.shade800, size: 20),
              const SizedBox(width: 8),
              Text(
                'Correction Request Pending',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  color: Colors.amber.shade900,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Requested: ${last['requested_full_name']}',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.amber.shade900),
          ),
          Text(
            'Wait for admin approval to see changes on your card.',
            style: GoogleFonts.inter(fontSize: 11, color: Colors.amber.shade700),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'package:intl/intl.dart';

class CorrectionManagementScreen extends StatefulWidget {
  const CorrectionManagementScreen({super.key});

  @override
  State<CorrectionManagementScreen> createState() => _CorrectionManagementScreenState();
}

class _CorrectionManagementScreenState extends State<CorrectionManagementScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _corrections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCorrections();
  }

  Future<void> _loadCorrections() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getCorrections();
      setState(() {
        _corrections = result['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(int id, String action) async {
    try {
      if (action == 'approve') {
        await _api.approveCorrection(id);
      } else {
        await _api.rejectCorrection(id);
      }
      _loadCorrections();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correction $action successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Correction Requests', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCorrections,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _corrections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rtl_rounded, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No pending correction requests',
                            style: GoogleFonts.inter(color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _corrections.length,
                    itemBuilder: (context, index) => _buildCorrectionCard(_corrections[index]),
                  ),
      ),
    );
  }

  Widget _buildCorrectionCard(Map<String, dynamic> correction) {
    final status = correction['status'];
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Voter ID: ${correction['voter_id']}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primaryColor),
              ),
              _statusChip(status),
            ],
          ),
          const Divider(height: 24),
          _detailRow('Current Name', correction['voter_name']),
          _detailRow('Requested Name', correction['requested_full_name'], highlight: true),
          const SizedBox(height: 8),
          _detailRow('Requested Father Name', correction['requested_father_name'] ?? 'N/A', highlight: true),
          
          if (isPending) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _handleAction(correction['id'], 'approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Approve & Apply'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _handleAction(correction['id'], 'reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                      side: const BorderSide(color: AppTheme.errorColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text('$label:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13, 
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                color: highlight ? AppTheme.accentColor : AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'approved': color = AppTheme.successColor; break;
      case 'rejected': color = AppTheme.errorColor; break;
      default: color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

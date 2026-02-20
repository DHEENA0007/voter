import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'add_voter_screen.dart';

class VoterManagementScreen extends StatefulWidget {
  const VoterManagementScreen({super.key});

  @override
  State<VoterManagementScreen> createState() => _VoterManagementScreenState();
}

class _VoterManagementScreenState extends State<VoterManagementScreen>
    with SingleTickerProviderStateMixin {
  final ApiService _api = ApiService();
  late TabController _tabController;
  List<dynamic> _voters = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _loadVoters();
      }
    });
    _loadVoters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String get _statusFilter {
    switch (_tabController.index) {
      case 0: return '';
      case 1: return 'pending';
      case 2: return 'approved';
      case 3: return 'blocked';
      default: return '';
    }
  }

  Future<void> _loadVoters() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getVoters(
        statusFilter: _statusFilter.isEmpty ? null : _statusFilter,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      setState(() {
        _voters = result['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    }
  }

  Future<void> _performAction(int id, String action) async {
    try {
      switch (action) {
        case 'approve':
          await _api.approveVoter(id);
          break;
        case 'reject':
          await _api.rejectVoter(id);
          break;
        case 'block':
          await _api.blockVoter(id);
          break;
        case 'unblock':
          await _api.unblockVoter(id);
          break;
      }
      _loadVoters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voter ${action}ed successfully'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  Color _statusColor(String status) {
    switch (status) {
      case 'approved': return AppTheme.successColor;
      case 'pending': return AppTheme.warningColor;
      case 'rejected': return AppTheme.errorColor;
      case 'blocked': return Colors.grey;
      default: return AppTheme.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Voter Management',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_rounded),
            tooltip: 'Remove Duplicates',
            onPressed: () async {
              try {
                final result = await _api.removeDuplicateVoters();
                _loadVoters();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(result['message'] ?? 'Done'),
                      backgroundColor: AppTheme.successColor,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => _loadVoters(),
                  style: GoogleFonts.inter(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name, ID, or mobile...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              TabBar(
                controller: _tabController,
                labelColor: AppTheme.primaryColor,
                unselectedLabelColor: AppTheme.textLight,
                labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                indicatorColor: AppTheme.primaryColor,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Approved'),
                  Tab(text: 'Blocked'),
                ],
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminAddVoterScreen()),
          );
          if (result == true) _loadVoters();
        },
        child: const Icon(Icons.person_add_rounded),
      ),
      body: RefreshIndicator(
        onRefresh: _loadVoters,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _voters.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text(
                          'No voters found',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _voters.length,
                    itemBuilder: (context, index) => _buildVoterCard(_voters[index]),
                  ),
      ),
    );
  }

  Widget _buildVoterCard(Map<String, dynamic> voter) {
    final status = voter['status'] ?? 'unknown';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                backgroundImage: voter['photo'] != null ? NetworkImage(_api.getImageUrl(voter['photo'])) : null,
                child: voter['photo'] == null
                    ? Text(
                        (voter['full_name'] ?? 'V')[0].toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
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
                      voter['full_name'] ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/O: ${voter['father_name'] ?? 'N/A'}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'ID: ${voter['voter_id']} • ${voter['mobile_number'] ?? ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: _statusColor(status).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (status == 'pending') ...[
                _actionButton('Approve', Icons.check_rounded, AppTheme.successColor,
                    () => _performAction(voter['id'], 'approve')),
                const SizedBox(width: 8),
                _actionButton('Reject', Icons.close_rounded, AppTheme.errorColor,
                    () => _performAction(voter['id'], 'reject')),
              ],
              if (status == 'approved')
                _actionButton('Block', Icons.block_rounded, Colors.grey,
                    () => _performAction(voter['id'], 'block')),
              if (status == 'blocked')
                _actionButton('Unblock', Icons.lock_open_rounded, AppTheme.successColor,
                    () => _performAction(voter['id'], 'unblock')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

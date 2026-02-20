import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import '../auth/login_screen.dart';
import 'voter_management_screen.dart';
import 'election_management_screen.dart';
import 'party_management_screen.dart';
import 'result_management_screen.dart';
import 'correction_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getDashboard();
      setState(() {
        _dashboardData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(color: AppTheme.primaryColor), // Yellow background for header area
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: RefreshIndicator(
                    onRefresh: _loadDashboard,
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildStatsGrid(),
                                const SizedBox(height: 28),
                                Text(
                                  'Management',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildMenuGrid(),
                              ],
                            ),
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

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: AppTheme.accentGradient,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.black, // Black text
                  ),
                ),
                Text(
                  'Manage elections & voters',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54, // Darker text
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            onPressed: _loadDashboard,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.black87),
            onPressed: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_dashboardData == null) return const SizedBox.shrink();
    
    final stats = [
      _StatItem('Total Voters', '${_dashboardData!['total_voters']}',
          Icons.people_rounded, const Color(0xFF3949AB), const Color(0xFF5C6BC0)),
      _StatItem('Approved', '${_dashboardData!['approved_voters']}',
          Icons.verified_rounded, const Color(0xFF00897B), const Color(0xFF26A69A)),
      _StatItem('Pending', '${_dashboardData!['pending_approvals']}',
          Icons.pending_rounded, const Color(0xFFEF6C00), const Color(0xFFFFA726)),
      _StatItem('Elections', '${_dashboardData!['total_elections']}',
          Icons.how_to_vote_rounded, const Color(0xFF6A1B9A), const Color(0xFFAB47BC)),
      _StatItem('Live Now', '${_dashboardData!['live_elections']}',
          Icons.sensors_rounded, const Color(0xFFC62828), const Color(0xFFEF5350)),
      _StatItem('Votes Cast', '${_dashboardData!['total_votes_cast']}',
          Icons.ballot_rounded, const Color(0xFF1565C0), const Color(0xFF42A5F5)),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.3, // Increased height
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [s.color1, s.color2],
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: s.color1.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(s.icon, color: Colors.white.withOpacity(0.8), size: 22),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      s.value,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      _MenuItem('Voter\nManagement', Icons.people_alt_rounded, AppTheme.primaryDark, () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const VoterManagementScreen()));
      }),
      _MenuItem('Election\nManagement', Icons.how_to_vote_rounded, const Color(0xFF6A1B9A), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ElectionManagementScreen()));
      }),
      _MenuItem('Party &\nCandidates', Icons.groups_rounded, const Color(0xFFEF6C00), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const PartyManagementScreen()));
      }),
      _MenuItem('Results &\nReports', Icons.analytics_rounded, const Color(0xFF00897B), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ResultManagementScreen()));
      }),
      _MenuItem('Correction\nRequests', Icons.edit_note_rounded, const Color(0xFFC62828), () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const CorrectionManagementScreen()));
      }),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05, // More vertical space
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return GestureDetector(
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // Reduced padding
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48, // Slightly smaller icon container
                  height: 48,
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(item.icon, color: item.color, size: 24),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: Text(
                    item.label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13, // Slightly smaller text
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color1;
  final Color color2;
  _StatItem(this.label, this.value, this.icon, this.color1, this.color2);
}

class _MenuItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _MenuItem(this.label, this.icon, this.color, this.onTap);
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class VoterResultsScreen extends StatefulWidget {
  final int electionId;
  final String electionName;

  const VoterResultsScreen({
    super.key,
    required this.electionId,
    required this.electionName,
  });

  @override
  State<VoterResultsScreen> createState() => _VoterResultsScreenState();
}

class _VoterResultsScreenState extends State<VoterResultsScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _resultData;
  bool _isLoading = true;

  final List<Color> _chartColors = const [
    Color(0xFF3949AB),
    Color(0xFF00897B),
    Color(0xFFEF6C00),
    Color(0xFFC62828),
    Color(0xFF6A1B9A),
    Color(0xFF1565C0),
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getVoterElectionResults(widget.electionId);
      setState(() {
        _resultData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Election Results',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.electionName,
                            style: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _resultData == null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.lock_clock_rounded, size: 64, color: AppTheme.textLight),
                                  const SizedBox(height: 16),
                                  Text('Results not available',
                                      style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                                ],
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildWinnerCard(),
                                  const SizedBox(height: 20),
                                  _buildTotalVotes(),
                                  const SizedBox(height: 20),
                                  _buildChart(),
                                  const SizedBox(height: 20),
                                  _buildResultList(),
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

  Widget _buildWinnerCard() {
    final winner = _resultData?['winner'];
    if (winner == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 40),
          const SizedBox(height: 12),
          Text(
            'WINNER',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.8),
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            winner['name'] ?? '',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${winner['party_name']} • ${winner['votes_count']} votes (${winner['vote_percentage']}%)',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalVotes() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.ballot_rounded, color: AppTheme.primaryColor, size: 24),
          const SizedBox(width: 12),
          Text(
            'Total Votes: ',
            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary),
          ),
          Text(
            '${_resultData?['total_votes'] ?? 0}',
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final candidates = _resultData?['candidates'] as List<dynamic>? ?? [];
    if (candidates.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Vote Distribution',
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: candidates.asMap().entries.map((entry) {
                  final i = entry.key;
                  final c = entry.value;
                  final color = _chartColors[i % _chartColors.length];
                  return PieChartSectionData(
                    value: (c['vote_percentage'] ?? 0).toDouble(),
                    color: color,
                    title: '${c['vote_percentage']}%',
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                    radius: 70,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 25,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: candidates.asMap().entries.map((entry) {
              final i = entry.key;
              final c = entry.value;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _chartColors[i % _chartColors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${c['name']}',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultList() {
    final candidates = _resultData?['candidates'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('All Candidates',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        ...candidates.asMap().entries.map((entry) {
          final index = entry.key;
          final c = entry.value;
          final color = _chartColors[index % _chartColors.length];
          final percentage = (c['vote_percentage'] ?? 0).toDouble();

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c['name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600)),
                          Text(c['party_name'] ?? '',
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Text(
                      '${c['votes_count'] ?? 0}',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: AppTheme.surfaceColor,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text('$percentage%',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class ResultManagementScreen extends StatefulWidget {
  const ResultManagementScreen({super.key});

  @override
  State<ResultManagementScreen> createState() => _ResultManagementScreenState();
}

class _ResultManagementScreenState extends State<ResultManagementScreen> {
  final ApiService _api = ApiService();
  List<dynamic> _elections = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadElections();
  }

  Future<void> _loadElections() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getElections();
      setState(() {
        _elections = (result['results'] ?? [])
            .where((e) => e['status'] == 'closed')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _showResults(Map<String, dynamic> election) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ElectionResultDetailScreen(electionId: election['id'], electionName: election['name']),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Results & Reports', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: RefreshIndicator(
        onRefresh: _loadElections,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _elections.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_outlined, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No closed elections yet',
                            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _elections.length,
                    itemBuilder: (context, index) {
                      final election = _elections[index];
                      return GestureDetector(
                        onTap: () => _showResults(election),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: AppTheme.softShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: election['result_published'] == true
                                      ? AppTheme.accentGradient
                                      : AppTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  election['result_published'] == true
                                      ? Icons.check_circle_rounded
                                      : Icons.analytics_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      election['name'] ?? '',
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      election['result_published'] == true
                                          ? 'Results Published'
                                          : 'Results Pending',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: election['result_published'] == true
                                            ? AppTheme.successColor
                                            : AppTheme.warningColor,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded, color: AppTheme.textLight),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}

// Election Result Detail Screen with Charts
class _ElectionResultDetailScreen extends StatefulWidget {
  final int electionId;
  final String electionName;

  const _ElectionResultDetailScreen({
    required this.electionId,
    required this.electionName,
  });

  @override
  State<_ElectionResultDetailScreen> createState() => _ElectionResultDetailScreenState();
}

class _ElectionResultDetailScreenState extends State<_ElectionResultDetailScreen> {
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
    Color(0xFF2E7D32),
    Color(0xFFD84315),
  ];

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      final data = await _api.getElectionResults(widget.electionId);
      setState(() {
        _resultData = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
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
                      child: Text(
                        widget.electionName,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (_resultData != null &&
                        _resultData!['election']?['result_published'] != true)
                      TextButton.icon(
                        onPressed: () async {
                          try {
                            await _api.publishResults(widget.electionId);
                            _loadResults();
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.publish_rounded, color: AppTheme.accentLight),
                        label: Text('Publish',
                            style: GoogleFonts.inter(color: AppTheme.accentLight, fontWeight: FontWeight.w600)),
                      ),

                    if (_resultData != null)
                      IconButton(
                        icon: const Icon(Icons.copy_all_rounded, color: Colors.white),
                        tooltip: 'Copy Summary',
                        onPressed: () {
                          final e = _resultData!['election'];
                          final w = _resultData!['winner'];
                          final summary = "Election Result: ${e['name']}\n"
                              "Total Votes: ${_resultData!['total_votes']}\n"
                              "Winner: ${w != null ? '${w['name']} (${w['party_name']})' : 'No Winner'}\n"
                              "Participation: ${_resultData!['participation_rate']}%\n";
                          Clipboard.setData(ClipboardData(text: summary));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Summary copied to clipboard')),
                          );
                        },
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
                          ? const Center(child: Text('Failed to load results'))
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                children: [
                                  _buildSummaryCards(),
                                  const SizedBox(height: 24),
                                  _buildWinnerBanner(),
                                  const SizedBox(height: 24),
                                  _buildPieChart(),
                                  const SizedBox(height: 24),
                                  _buildCandidateList(),
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

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard('Total Votes', '${_resultData!['total_votes'] ?? 0}',
              Icons.ballot_rounded, const Color(0xFF3949AB)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard('Participation', '${_resultData!['participation_rate'] ?? 0}%',
              Icons.people_rounded, const Color(0xFF00897B)),
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerBanner() {
    final winner = _resultData!['winner'];
    if (winner == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WINNER', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.8), letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(winner['name'] ?? '', style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                Text('${winner['party_name']} • ${winner['votes_count']} votes',
                  style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withOpacity(0.85))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    final candidates = _resultData!['candidates'] as List<dynamic>? ?? [];
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
          Text('Vote Distribution', style: GoogleFonts.inter(
            fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
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
                      fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white),
                    radius: 80,
                  );
                }).toList(),
                sectionsSpace: 3,
                centerSpaceRadius: 30,
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
                  Text('${c['name']}', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCandidateList() {
    final candidates = _resultData!['candidates'] as List<dynamic>? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Detailed Results', style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...candidates.asMap().entries.map((entry) {
          final index = entry.key;
          final c = entry.value;
          final color = _chartColors[index % _chartColors.length];
          final isWinner = index == 0 && (c['votes_count'] ?? 0) > 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isWinner ? Border.all(color: AppTheme.accentColor, width: 2) : null,
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '#${index + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c['name'] ?? '', style: GoogleFonts.inter(
                            fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                          if (isWinner) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.emoji_events_rounded, color: Color(0xFFFFD700), size: 18),
                          ],
                        ],
                      ),
                      Text(c['party_name'] ?? '', style: GoogleFonts.inter(
                        fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${c['votes_count'] ?? 0}', style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800, color: color)),
                    Text('${c['vote_percentage'] ?? 0}%', style: GoogleFonts.inter(
                      fontSize: 12, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

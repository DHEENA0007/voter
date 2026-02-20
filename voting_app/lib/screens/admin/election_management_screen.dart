import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';
import 'candidate_management_screen.dart';

class ElectionManagementScreen extends StatefulWidget {
  const ElectionManagementScreen({super.key});

  @override
  State<ElectionManagementScreen> createState() => _ElectionManagementScreenState();
}

class _ElectionManagementScreenState extends State<ElectionManagementScreen> {
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
        _elections = result['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'live': return AppTheme.errorColor;
      case 'upcoming': return AppTheme.accentColor;
      case 'closed': return AppTheme.textLight;
      default: return AppTheme.textSecondary;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'live': return Icons.sensors_rounded;
      case 'upcoming': return Icons.schedule_rounded;
      case 'closed': return Icons.check_circle_rounded;
      default: return Icons.info_rounded;
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? startDate;
    DateTime? endDate;
    final startCtrl = TextEditingController();
    final endCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Create Election',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Election Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            startDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            startCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(startDate!);
                          });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Start Date & Time',
                          suffixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startDate ?? DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            endDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            endCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(endDate!);
                          });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'End Date & Time',
                          suffixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                    ),
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
                  if (nameCtrl.text.isEmpty || startDate == null || endDate == null) return;
                  try {
                    await _api.createElection({
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'start_date': startDate!.toIso8601String(),
                      'end_date': endDate!.toIso8601String(),
                      'status': 'upcoming',
                    });
                    Navigator.pop(ctx);
                    _loadElections();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
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

  Future<void> _toggleElection(Map<String, dynamic> election) async {
    try {
      if (election['status'] == 'upcoming') {
        await _api.startElection(election['id']);
      } else if (election['status'] == 'live') {
        await _api.stopElection(election['id']);
      }
      _loadElections();
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
        title: Text('Election Management',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add_rounded),
        label: Text('New Election', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
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
                        Icon(Icons.how_to_vote_outlined, size: 64, color: AppTheme.textLight),
                        const SizedBox(height: 16),
                        Text('No elections yet',
                            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary)),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _elections.length,
                    itemBuilder: (context, index) => _buildElectionCard(_elections[index]),
                  ),
      ),
    );
  }

  Widget _buildElectionCard(Map<String, dynamic> election) {
    final status = election['status'] ?? 'upcoming';
    final color = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_statusIcon(status), color: color, size: 22),
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
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (election['description'] != null && election['description'].isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    election['description'],
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    _infoChip(Icons.people_rounded, '${election['candidates_count'] ?? 0} candidates'),
                    const SizedBox(width: 12),
                    _infoChip(Icons.ballot_rounded, '${election['total_votes_cast'] ?? 0} votes'),
                  ],
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                if (status != 'closed')
                  _cardAction(
                    status == 'upcoming' ? 'Start' : 'Stop',
                    status == 'upcoming' ? Icons.play_arrow_rounded : Icons.stop_rounded,
                    status == 'upcoming' ? AppTheme.successColor : AppTheme.errorColor,
                    () => _toggleElection(election),
                  ),
                _cardAction('Candidates', Icons.group_add_rounded, AppTheme.primaryColor, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CandidateManagementScreen(
                        electionId: election['id'],
                        electionName: election['name'],
                      ),
                    ),
                  );
                }),
                if (status == 'closed' && !(election['result_published'] ?? false))
                  _cardAction('Publish', Icons.publish_rounded, AppTheme.accentColor, () async {
                    try {
                      await _api.publishResults(election['id']);
                      _loadElections();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$e')),
                        );
                      }
                    }
                  }),
                // More Actions (Extend)
                if (status != 'closed')
                   Expanded(
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert_rounded, color: AppTheme.textLight),
                      onSelected: (value) {
                         if (value == 'extend') _showExtendDialog(election);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'extend',
                          child: Row(
                            children: [
                              Icon(Icons.update_rounded, size: 18, color: AppTheme.textPrimary),
                              SizedBox(width: 8),
                              Text('Extend Duration'),
                            ],
                          ),
                        ),
                      ],
                    ),
                   ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showExtendDialog(Map<String, dynamic> election) async {
    DateTime? newEndDate;
    final endCtrl = TextEditingController();
    
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Extend Election'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select a new end date and time.'),
                const SizedBox(height: 12),
                GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2030),
                      );
                      if (date != null) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (time != null) {
                          setDialogState(() {
                            newEndDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                            endCtrl.text = DateFormat('yyyy-MM-dd HH:mm').format(newEndDate!);
                          });
                        }
                      }
                    },
                    child: AbsorbPointer(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'New End Date',
                          suffixIcon: Icon(Icons.calendar_today_rounded),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                   if (newEndDate != null) {
                     try {
                       await _api.extendElection(election['id'], newEndDate!.toIso8601String());
                       Navigator.pop(ctx);
                       _loadElections();
                       if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Election extended successfully')),
                          );
                       }
                     } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
                     }
                   }
                },
                child: const Text('Extend'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 15, color: AppTheme.textLight),
        const SizedBox(width: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _cardAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
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

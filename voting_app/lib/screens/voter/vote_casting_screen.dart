import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class VoteCastingScreen extends StatefulWidget {
  final int electionId;
  final String electionName;

  const VoteCastingScreen({
    super.key,
    required this.electionId,
    required this.electionName,
  });

  @override
  State<VoteCastingScreen> createState() => _VoteCastingScreenState();
}

class _VoteCastingScreenState extends State<VoteCastingScreen> {
  final ApiService _api = ApiService();
  
  List<dynamic> _candidates = [];
  bool _isLoading = true;
  int? _selectedCandidateId;
  bool _isSubmitting = false;
  bool _biometricVerified = true;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
  }

  Future<void> _loadCandidates() async {
    setState(() => _isLoading = true);
    try {
      final result = await _api.getCandidates(electionId: widget.electionId);
      setState(() {
        _candidates = result['results'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }



  Future<void> _castVote() async {
    if (_selectedCandidateId == null) return;

    final selectedCandidate = _candidates.firstWhere((c) => c['id'] == _selectedCandidateId);

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        contentPadding: EdgeInsets.zero,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: AppTheme.accentColor.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Center(
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.how_to_vote_rounded, color: AppTheme.accentColor, size: 32),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Confirm Your Vote',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    'You are about to cast your vote for:',
                    style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accentColor.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            image: selectedCandidate['party_symbol'] != null
                                ? DecorationImage(
                                    image: NetworkImage(_api.getImageUrl(selectedCandidate['party_symbol'])),
                                    fit: BoxFit.contain,
                                  )
                                : null,
                          ),
                          child: selectedCandidate['party_symbol'] == null
                              ? const Icon(Icons.flag_rounded, color: AppTheme.textLight)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                selectedCandidate['name'] ?? '',
                                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                selectedCandidate['party_name'] ?? '',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.accentColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.errorColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Once submitted, this cannot be changed.',
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.errorColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Cancel', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text('Vote Now', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSubmitting = true);
    try {
      final result = await _api.castVote(widget.electionId, _selectedCandidateId!);
      
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            contentPadding: EdgeInsets.zero,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: AppTheme.accentGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.check_rounded, size: 44, color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Success!',
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your vote has been cast securely.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      if (result['vote_hash'] != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.dividerColor),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'TRANSACTION HASH',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.textLight,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              SelectableText(
                                result['vote_hash'] ?? '',
                                style: GoogleFonts.robotoMono(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: Text('Back to Home', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
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
    } finally {
      setState(() => _isSubmitting = false);
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
                            'Cast Your Vote',
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
                      : Column(
                          children: [
                            // Step indicator
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: _buildStepIndicator(),
                            ),
                            Expanded(
                              child: _buildCandidateSelection(),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, 'Select', _selectedCandidateId != null),
        Expanded(
          child: Container(
            height: 2,
            color: _selectedCandidateId != null ? AppTheme.accentColor : AppTheme.dividerColor,
          ),
        ),
        _stepDot(2, 'Submit', false),
      ],
    );
  }

  Widget _stepDot(int step, String label, bool completed) {
    final isActive = (step == 1 && _selectedCandidateId == null) ||
        (step == 2 && _selectedCandidateId != null);

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            gradient: completed
                ? AppTheme.accentGradient
                : isActive
                    ? AppTheme.primaryGradient
                    : null,
            color: (!completed && !isActive) ? AppTheme.dividerColor : null,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: completed
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isActive ? Colors.white : AppTheme.textLight,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: completed || isActive ? AppTheme.textPrimary : AppTheme.textLight,
          ),
        ),
      ],
    );
  }



  Widget _buildCandidateSelection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Text(
                'Select a Candidate',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${_candidates.length} candidates',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _candidates.length,
            itemBuilder: (context, index) {
              final candidate = _candidates[index];
              final isSelected = _selectedCandidateId == candidate['id'];

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedCandidateId = candidate['id']);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isSelected ? AppTheme.accentColor : Colors.transparent,
                      width: 2.5,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      // Party symbol
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceColor,
                          borderRadius: BorderRadius.circular(14),
                          image: candidate['party_symbol'] != null
                              ? DecorationImage(
                                  image: NetworkImage(_api.getImageUrl(candidate['party_symbol'])),
                                  fit: BoxFit.contain,
                                )
                              : null,
                        ),
                        child: candidate['party_symbol'] == null
                            ? Icon(Icons.flag_rounded,
                                color: AppTheme.textLight, size: 28)
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
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: isSelected ? AppTheme.accentGradient : null,
                          border: isSelected
                              ? null
                              : Border.all(color: AppTheme.dividerColor, width: 2),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                            : null,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        // Submit button
        if (_selectedCandidateId != null)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppTheme.accentGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _castVote,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : Text(
                        'Submit Vote',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ),
      ],
    );
  }
}

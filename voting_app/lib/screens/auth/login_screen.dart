import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../admin/admin_dashboard_screen.dart';
import '../voter/voter_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  bool _isAdminMode = false;
  bool _obscurePassword = true;
  
  // Admin fields
  final _adminUsernameController = TextEditingController();
  final _adminPasswordController = TextEditingController();
  
  // Voter fields
  final _voterIdController = TextEditingController();
  final _passcodeController = TextEditingController();
  
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  


  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _adminUsernameController.dispose();
    _adminPasswordController.dispose();
    _voterIdController.dispose();
    _passcodeController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isAdminMode = !_isAdminMode;
    });
    _animController.reset();
    _animController.forward();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    bool success;

    if (_isAdminMode) {
      success = await authProvider.adminLogin(
        _adminUsernameController.text.trim(),
        _adminPasswordController.text,
      );
    } else {
      success = await authProvider.voterLogin(
        _voterIdController.text.trim(),
        _passcodeController.text,
      );
    }

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => _isAdminMode
              ? const AdminDashboardScreen()
              : const VoterHomeScreen(),
        ),
      );
    } else if (mounted && authProvider.error != null) {
      _showError(authProvider.error!);
    }
  }


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(height: 40),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildModeToggle(),
                const SizedBox(height: 32),
                _buildLoginForm(),
                const SizedBox(height: 24),
                if (!_isAdminMode) _buildRegisterLink(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(Icons.how_to_vote_rounded, size: 40, color: Colors.black),
        ),
        const SizedBox(height: 20),
        Text(
          AppConstants.appName,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: Colors.black,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appTagline,
          style: GoogleFonts.inter(
            fontSize: 15,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildModeToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () { if (_isAdminMode) _toggleMode(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: !_isAdminMode ? AppTheme.accentGradient : null,
                  color: !_isAdminMode ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person_rounded,
                      size: 20,
                      color: !_isAdminMode ? Colors.white : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Voter',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: !_isAdminMode ? Colors.white : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () { if (!_isAdminMode) _toggleMode(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: _isAdminMode ? AppTheme.primaryGradient : null,
                  color: _isAdminMode ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.admin_panel_settings_rounded,
                      size: 20,
                      color: _isAdminMode ? Colors.black : Colors.grey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Admin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: _isAdminMode ? Colors.black : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _isAdminMode ? 'Admin Login' : 'Voter Login',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isAdminMode
                  ? 'Enter your admin credentials'
                  : 'Login with your Voter ID',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            if (_isAdminMode) ...[
              _buildTextField(
                controller: _adminUsernameController,
                label: 'Username',
                icon: Icons.person_outline_rounded,
                validator: (v) => v!.isEmpty ? 'Enter username' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _adminPasswordController,
                label: 'Password',
                icon: Icons.lock_outline_rounded,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textLight,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => v!.isEmpty ? 'Enter password' : null,
              ),
            ] else ...[
              _buildTextField(
                controller: _voterIdController,
                label: 'Voter ID',
                icon: Icons.badge_outlined,
                validator: (v) => v!.isEmpty ? 'Enter Voter ID' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passcodeController,
                label: 'Passcode',
                icon: Icons.pin_rounded,
                obscure: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: AppTheme.textLight,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (v) => v!.isEmpty ? 'Enter passcode' : null,
              ),
            ],
            const SizedBox(height: 24),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: _isAdminMode ? AppTheme.primaryGradient : AppTheme.accentGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (_isAdminMode ? AppTheme.primaryColor : AppTheme.accentColor)
                            .withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: auth.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: _isAdminMode ? Colors.black : Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            'Login',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _isAdminMode ? Colors.black : Colors.white,
                            ),
                          ),
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RegisterScreen()),
            );
          },
          child: Text(
            'Apply for Voter',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

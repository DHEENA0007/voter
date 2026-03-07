import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _addressController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passcodeController = TextEditingController();
  final _confirmPasscodeController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _fingerprintCaptured = false;

  String _gender = 'M';
  DateTime? _selectedDob;
  XFile? _pickedImage; // Use XFile instead of File for web compatibility
  bool _obscurePasscode = true;

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    _passcodeController.dispose();
    _confirmPasscodeController.dispose();
    _fatherNameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18+ years
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 800);
    if (pickedFile != null) {
      setState(() => _pickedImage = pickedFile);
    }
  }



  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo')),
      );
      return;
    }



    if (_passcodeController.text != _confirmPasscodeController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Passcodes do not match'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final data = {
      'full_name': _nameController.text.trim(),
      'father_name': _fatherNameController.text.trim(),
      'date_of_birth': _dobController.text,
      'gender': _gender,
      'address': _addressController.text.trim(),
      'email': _emailController.text.trim(),
      'mobile_number': _mobileController.text.trim(),
      'passcode': _passcodeController.text,
      'biometric_enabled': false,
    };

    final authProvider = context.read<AuthProvider>();
    
    // For web: pass XFile; for mobile: pass File
    File? photoFile;
    if (!kIsWeb && _pickedImage != null) {
      photoFile = File(_pickedImage!.path);
    }
    
    final success = await authProvider.voterRegister(
      data, 
      photo: photoFile,
      photoXFile: kIsWeb ? _pickedImage : null,
    );

    if (success && mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.accentGradient,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                'Application Submitted!',
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Text(
                'Your voter application has been submitted successfully. A confirmation email has been sent to your email address. Please wait for admin approval.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).pop();
              },
              child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    } else if (mounted && authProvider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.error!),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
              // Top bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Apply for Voter',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              // Form
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Photo upload
                          Center(
                            child: GestureDetector(
                              onTap: _pickPhoto,
                              child: FutureBuilder<Widget>(
                                future: _buildPhotoPreview(),
                                builder: (context, snapshot) {
                                  return Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surfaceColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: AppTheme.dividerColor, width: 2),
                                    ),
                                    child: snapshot.hasData 
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(18),
                                            child: snapshot.data!,
                                          )
                                        : Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              const Icon(Icons.camera_alt_rounded,
                                                  color: AppTheme.textLight, size: 28),
                                              const SizedBox(height: 4),
                                              Text(
                                                'Upload',
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  color: AppTheme.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                  );
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          _buildField(
                            controller: _nameController,
                            label: 'Full Name',
                            icon: Icons.person_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter full name' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _fatherNameController,
                            label: "Father's / Husband's Name",
                            icon: Icons.people_outline_rounded,
                            validator: (v) => v!.isEmpty ? 'Enter father/husband name' : null,
                          ),
                          const SizedBox(height: 16),

                          GestureDetector(
                            onTap: _pickDate,
                            child: AbsorbPointer(
                              child: _buildField(
                                controller: _dobController,
                                label: 'Date of Birth',
                                icon: Icons.calendar_today_rounded,
                                validator: (v) => v!.isEmpty ? 'Select date of birth' : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Gender selection
                          Text(
                            'Gender',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _genderChip('M', 'Male', Icons.male_rounded),
                              const SizedBox(width: 12),
                              _genderChip('F', 'Female', Icons.female_rounded),
                              const SizedBox(width: 12),
                              _genderChip('O', 'Other', Icons.transgender_rounded),
                            ],
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _addressController,
                            label: 'Address',
                            icon: Icons.location_on_outlined,
                            maxLines: 2,
                            validator: (v) => v!.isEmpty ? 'Enter address' : null,
                          ),
                          const SizedBox(height: 16),

                          // Email field
                          _buildField(
                            controller: _emailController,
                            label: 'Email Address',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Enter email address';
                              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                              if (!emailRegex.hasMatch(v)) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _mobileController,
                            label: 'Mobile Number',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (v) => v!.isEmpty ? 'Enter mobile number' : null,
                          ),
                          const SizedBox(height: 16),

                           _buildField(
                            controller: _passcodeController,
                            label: 'Create Passcode',
                            icon: Icons.pin_rounded,
                            obscure: _obscurePasscode,
                            validator: (v) => v!.length < 4 ? 'Minimum 4 characters' : null,
                          ),
                          const SizedBox(height: 16),

                          _buildField(
                            controller: _confirmPasscodeController,
                            label: 'Confirm Passcode',
                            icon: Icons.pin_rounded,
                            obscure: _obscurePasscode,
                            validator: (v) => v!.isEmpty ? 'Confirm passcode' : null,
                          ),
                          const SizedBox(height: 24),


                          const SizedBox(height: 28),

                          Consumer<AuthProvider>(
                            builder: (context, auth, _) {
                              return Container(
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
                                  onPressed: auth.isLoading ? null : _handleRegister,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: auth.isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : Text(
                                          'Submit Application',
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 20),
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

  /// Build the photo preview widget - handles both web and mobile
  Future<Widget> _buildPhotoPreview() async {
    if (_pickedImage == null) {
      return const SizedBox.shrink();
    }
    
    if (kIsWeb) {
      // For web, use bytes
      final bytes = await _pickedImage!.readAsBytes();
      return Image.memory(bytes, fit: BoxFit.cover, width: 100, height: 100);
    } else {
      // For mobile, use File
      return Image.file(File(_pickedImage!.path), fit: BoxFit.cover, width: 100, height: 100);
    }
  }

  Widget _genderChip(String value, String label, IconData icon) {
    final selected = _gender == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _gender = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: selected ? AppTheme.primaryGradient : null,
            color: selected ? null : AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Colors.transparent : AppTheme.dividerColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(fontSize: 15, color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 22),
      ),
    );
  }
}

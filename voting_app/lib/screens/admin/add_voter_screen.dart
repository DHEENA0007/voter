import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../utils/theme.dart';

class AdminAddVoterScreen extends StatefulWidget {
  const AdminAddVoterScreen({super.key});

  @override
  State<AdminAddVoterScreen> createState() => _AdminAddVoterScreenState();
}

class _AdminAddVoterScreenState extends State<AdminAddVoterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _voterIdCtrl = TextEditingController();
  final _mobileCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passcodeCtrl = TextEditingController();
  final _fatherNameCtrl = TextEditingController();
  


  
  DateTime? _dob;
  String _gender = 'Male';
  File? _photo;
  final _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600);
    if (picked != null) {
      setState(() => _photo = File(picked.path));
    }
  }



  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_photo == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo')),
      );
      return;
    }
    if (_dob == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Date of Birth')),
      );
      return;
    }


    setState(() => _isLoading = true);
    
    // Auto-generate or manual Voter ID? 
    // Requirement says "User must provide: ... Voter ID". So manual.
    
    final data = {
      'full_name': _nameCtrl.text,
      'father_name': _fatherNameCtrl.text,
      'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),

      'address': _addressCtrl.text,
      'mobile_number': _mobileCtrl.text,
      'voter_id': _voterIdCtrl.text,
      'passcode': _passcodeCtrl.text,
      'gender': _gender == 'Male' ? 'M' : (_gender == 'Female' ? 'F' : 'O'),
      'biometric_enabled': false,
    };

    try {
      await ApiService().createVoter(data, photo: _photo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voter created successfully')),
        );
        Navigator.pop(context, true); // Return true to refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceColor,
      appBar: AppBar(
        title: Text('Add New Voter', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2), width: 2),
                      image: _photo != null
                          ? DecorationImage(image: FileImage(_photo!), fit: BoxFit.cover)
                          : null,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: _photo == null
                        ? Icon(Icons.add_a_photo_rounded, size: 32, color: AppTheme.textLight)
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text('Tap to upload photo', 
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textLight)),
              ),
              const SizedBox(height: 24),

              _buildTextField('Full Name', _nameCtrl, Icons.person_outline_rounded),
              const SizedBox(height: 16),

              _buildTextField("Father's / Husband's Name", _fatherNameCtrl, Icons.people_outline_rounded),
              const SizedBox(height: 16),
              
              _buildTextField('Voter ID', _voterIdCtrl, Icons.badge_outlined),
              const SizedBox(height: 16),
              


              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime(2000),
                          firstDate: DateTime(1900),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) setState(() => _dob = date);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 20, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text(
                              _dob == null ? 'Date of Birth' : DateFormat('dd MMM yyyy').format(_dob!),
                              style: GoogleFonts.inter(
                                color: _dob == null ? AppTheme.textLight : AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.dividerColor),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _gender,
                          icon: Icon(Icons.arrow_drop_down_rounded, color: AppTheme.textSecondary),
                          items: ['Male', 'Female', 'Other']
                              .map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                          onChanged: (v) => setState(() => _gender = v!),
                          style: GoogleFonts.inter(color: AppTheme.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildTextField('Mobile Number', _mobileCtrl, Icons.phone_android_rounded, 
                  inputType: TextInputType.phone),
              const SizedBox(height: 16),

              _buildTextField('Address', _addressCtrl, Icons.home_outlined, maxLines: 2),
              const SizedBox(height: 16),

              _buildTextField('Set Passcode', _passcodeCtrl, Icons.lock_outline_rounded, 
                  isPassword: true, inputType: TextInputType.number),
              
              const SizedBox(height: 24),


              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text('Create Voter',
                          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, 
      {bool isPassword = false, TextInputType? inputType, int maxLines = 1}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPassword,
      keyboardType: inputType,
      maxLines: maxLines,
      validator: (val) => val == null || val.isEmpty ? '$label is required' : null,
      style: GoogleFonts.inter(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.dividerColor),
        ),
      ),
    );
  }
}

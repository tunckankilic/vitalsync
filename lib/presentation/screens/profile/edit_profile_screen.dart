import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vitalsync/core/auth/auth_provider.dart';
import 'package:vitalsync/core/enums/gender.dart';
import 'package:vitalsync/core/l10n/app_localizations.dart';
import 'package:vitalsync/domain/entities/shared/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _emergencyPhoneController;

  DateTime? _birthDate;
  Gender _gender = Gender.preferNotToSay;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emergencyContactController = TextEditingController();
    _emergencyPhoneController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emergencyContactController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  void _initializeWithUser(UserProfile user) {
    if (_nameController.text.isEmpty) {
      _nameController.text = user.name;
      _birthDate = user.birthDate;
      _gender = user.gender;
      _emergencyContactController.text = user.emergencyContact ?? '';
      _emergencyPhoneController.text = user.emergencyPhone ?? '';
    }
  }

  Future<void> _saveProfile(
    UserProfile currentUser,
    AppLocalizations l10n,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final updatedProfile = currentUser.copyWith(
        name: _nameController.text.trim(),
        birthDate: _birthDate,
        gender: _gender,
        emergencyContact: _emergencyContactController.text.trim().isEmpty
            ? null
            : _emergencyContactController.text.trim(),
        emergencyPhone: _emergencyPhoneController.text.trim().isEmpty
            ? null
            : _emergencyPhoneController.text.trim(),
        updatedAt: DateTime.now(),
      );

      await ref.read(userRepositoryProvider).updateProfile(updatedProfile);

      // Refresh the current user provider
      ref.invalidate(currentUserProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.profileUpdatedSuccess)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdateError(e)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) return Center(child: Text(l10n.userNotFound));
          _initializeWithUser(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionHeader(title: l10n.personalInformation),
                  const SizedBox(height: 16),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration(l10n.fullName, Icons.person),
                    validator: (value) => value == null || value.isEmpty
                        ? l10n.enterFullName
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Birth Date Field
                  InkWell(
                    onTap: () => _selectDate(context),
                    borderRadius: BorderRadius.circular(12),
                    child: InputDecorator(
                      decoration: _inputDecoration(
                        l10n.dateOfBirth,
                        Icons.calendar_today,
                      ),
                      child: Text(
                        _birthDate != null
                            ? DateFormat.yMMMd().format(_birthDate!)
                            : l10n.selectDate,
                        style: TextStyle(
                          color: _birthDate != null
                              ? Colors.black
                              : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  DropdownButtonFormField<Gender>(
                    initialValue: _gender,
                    decoration: _inputDecoration(l10n.gender, Icons.wc),
                    items: Gender.values.map((gender) {
                      return DropdownMenuItem(
                        value: gender,
                        child: Text(_formatGender(gender, l10n)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _gender = val);
                    },
                  ),

                  const SizedBox(height: 32),
                  _SectionHeader(title: l10n.emergencyContact),
                  const SizedBox(height: 16),

                  // Emergency Contact Name
                  TextFormField(
                    controller: _emergencyContactController,
                    decoration: _inputDecoration(
                      l10n.contactName,
                      Icons.contact_phone,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Emergency Phone
                  TextFormField(
                    controller: _emergencyPhoneController,
                    decoration: _inputDecoration(l10n.phoneNumber, Icons.phone),
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 48),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _saveProfile(user, l10n),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              l10n.saveChanges,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey[600]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  String _formatGender(Gender gender, AppLocalizations l10n) {
    switch (gender) {
      case Gender.male:
        return l10n.genderMale;
      case Gender.female:
        return l10n.genderFemale;
      case Gender.other:
        return l10n.genderOther;
      case Gender.preferNotToSay:
        return l10n.genderPreferNotToSay;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 2,
          width: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ],
    );
  }
}

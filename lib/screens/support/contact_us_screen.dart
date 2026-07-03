import 'package:flutter/material.dart';
import 'package:smartshopper_mobile/config/app_strings.dart';
import 'package:smartshopper_mobile/config/app_theme.dart';

import 'package:cloud_firestore/cloud_firestore.dart';

class ContactUsScreen extends StatefulWidget {
  final AppStrings s;
  const ContactUsScreen({super.key, required this.s});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _sending = true);
    try {
      await FirebaseFirestore.instance.collection('support_messages').add({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'resolved': false,
      });
      setState(() {
        _sending = false;
        _sent = true;
      });
    } catch (e) {
      setState(() => _sending = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBEB),
      appBar: AppBar(
        title: Text(s.contactUs),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0.5,
      ),
      body: _sent ? _SuccessView(s: s, onBack: () => Navigator.pop(context)) : _FormView(
        s: s,
        formKey: _formKey,
        nameController: _nameController,
        emailController: _emailController,
        subjectController: _subjectController,
        messageController: _messageController,
        sending: _sending,
        onSubmit: _submit,
      ),
    );
  }
}

// ── Contact form ───────────────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  final AppStrings s;
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController subjectController;
  final TextEditingController messageController;
  final bool sending;
  final VoidCallback onSubmit;

  const _FormView({
    required this.s,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.subjectController,
    required this.messageController,
    required this.sending,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // ── Hero ──────────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
          child: Column(
            children: [
              const Icon(Icons.support_agent_rounded, size: 48, color: Colors.white),
              const SizedBox(height: AppSpacing.md),
              Text(
                s.contactUs,
                style: AppTypography.headline2.copyWith(color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We\'d love to hear from you. Send us a message!',
                style: AppTypography.bodyMedium.copyWith(color: Colors.white70),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Quick contact chips ────────────────────────────────────────
        Row(
          children: [
            _QuickContact(
              icon: Icons.email_outlined,
              label: s.emailUs,
              detail: 'support@smartshopper.my',
              color: const Color(0xFF3B82F6),
            ),
            const SizedBox(width: AppSpacing.md),
            _QuickContact(
              icon: Icons.phone_outlined,
              label: s.callUs,
              detail: '+60 3-1234 5678',
              color: const Color(0xFF10B981),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),

        // ── Form ──────────────────────────────────────────────────────
        Text(
          s.sendMessage,
          style: AppTypography.headline3,
        ),
        const SizedBox(height: AppSpacing.lg),
        Form(
          key: formKey,
          child: Column(
            children: [
              _Field(
                controller: nameController,
                label: 'Full Name',
                hint: 'e.g. Ahmad bin Ali',
                icon: Icons.person_outline,
                validator: (v) => (v?.isEmpty ?? true) ? 'Please enter your name' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                controller: emailController,
                label: 'Email Address',
                hint: 'you@example.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Please enter your email';
                  if (!v!.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                controller: subjectController,
                label: 'Subject',
                hint: 'e.g. Price discrepancy',
                icon: Icons.subject_rounded,
                validator: (v) => (v?.isEmpty ?? true) ? 'Please enter a subject' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              _Field(
                controller: messageController,
                label: 'Message',
                hint: 'Describe your issue or question…',
                icon: Icons.message_outlined,
                maxLines: 5,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Please enter a message';
                  if (v!.length < 20) return 'Message must be at least 20 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: sending ? null : onSubmit,
                  icon: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(sending ? 'Sending…' : s.sendMessage),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    textStyle: AppTypography.labelLarge,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ── Success view ──────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  final AppStrings s;
  final VoidCallback onBack;
  const _SuccessView({required this.s, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD1FAE5),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 56,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Message Sent!',
              style: AppTypography.headline2,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Thank you for reaching out. Our team will get back to you within 1–2 business days.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppTheme.textSecondary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xxl),
            ElevatedButton(
              onPressed: onBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text('Back to Profile'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quick-contact card ─────────────────────────────────────────────────────────
class _QuickContact extends StatelessWidget {
  final IconData icon;
  final String label;
  final String detail;
  final Color color;
  const _QuickContact({
    required this.icon,
    required this.label,
    required this.detail,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(label, style: AppTypography.labelSmall.copyWith(color: AppTheme.textTertiary)),
            const SizedBox(height: 2),
            Text(
              detail,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Text field helper ─────────────────────────────────────────────────────────
class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

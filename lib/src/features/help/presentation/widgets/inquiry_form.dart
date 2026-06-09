import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vault_os/src/services/supabase_service.dart';
import 'package:vault_os/src/constants/app_colors.dart';
import 'package:vault_os/src/constants/app_sizes.dart';

class InquiryForm extends StatefulWidget {
  const InquiryForm({super.key});

  @override
  State<InquiryForm> createState() => _InquiryFormState();
}

class _InquiryFormState extends State<InquiryForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;
  bool _isSuccess = false;
  bool _termsAgreed = false;
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  int _charCount = 0;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(() {
      setState(() => _charCount = _messageController.text.length);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && _termsAgreed) {
      setState(() => _isSubmitting = true);
      
      try {
        final response = await SupabaseService.client.functions.invoke(
          'send-support-email',
          body: {
            'firstName': _firstNameController.text.trim(),
            'lastName': _lastNameController.text.trim(),
            'email': _emailController.text.trim(),
            'message': _messageController.text.trim(),
          },
        );

        if (response.status == 200) {
          if (mounted) {
            setState(() {
              _isSubmitting = false;
              _isSuccess = true;
            });
          }
        } else {
          throw Exception('Failed to send inquiry');
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please try again later. Failed to send inquiry.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessState();
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DIRECT INQUIRY',
              style: TextStyle(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.p20),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'FIRST NAME',
                    hint: 'John',
                    controller: _firstNameController,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
                const SizedBox(width: AppSizes.p16),
                Expanded(
                  child: _buildTextField(
                    label: 'LAST NAME',
                    hint: 'Doe',
                    controller: _lastNameController,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p16),
            _buildTextField(
              label: 'EMAIL ADDRESS',
              hint: 'john.doe@example.com',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Invalid email' : null,
            ),
            const SizedBox(height: AppSizes.p16),
            _buildTextField(
              label: 'YOUR MESSAGE',
              hint: 'How can we help you?',
              controller: _messageController,
              maxLines: 6,
              maxLength: 1000,
              validator: (v) => v!.isEmpty ? 'Message cannot be empty' : null,
            ),
            const SizedBox(height: AppSizes.p8),
            Row(
              children: [
                Theme(
                  data: theme.copyWith(unselectedWidgetColor: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5)),
                  child: Checkbox(
                    value: _termsAgreed,
                    activeColor: colorScheme.primary,
                    onChanged: (v) => setState(() => _termsAgreed = v!),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _termsAgreed = !_termsAgreed),
                    child: RichText(
                      text: TextSpan(
                        text: 'I agree to the ',
                        style: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7), fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Terms & Privacy Policy',
                            style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.p24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(LucideIcons.send, size: 20),
                label: Text(_isSubmitting ? 'PROCESSING...' : 'SUBMIT INQUIRY'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  disabledBackgroundColor: colorScheme.primary.withValues(alpha: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    TextEditingController? controller,
    int maxLines = 1,
    int? maxLength,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          keyboardType: keyboardType,
          validator: validator,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.2)),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
            counterText: maxLength != null ? '$_charCount / $maxLength' : '',
            counterStyle: TextStyle(color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.5), fontSize: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            errorStyle: const TextStyle(color: AppColors.error, fontSize: 11),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSizes.p32),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : colorScheme.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(LucideIcons.checkCircle2, size: 64, color: colorScheme.primary),
          const SizedBox(height: AppSizes.p24),
          Text(
            'Inquiry Received',
            style: TextStyle(
              color: theme.textTheme.headlineSmall?.color,
              fontSize: 22, 
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: AppSizes.p12),
          Text(
            'Our team has received your message and will get back to you within 24 hours.',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: AppSizes.p32),
          TextButton(
            onPressed: () => setState(() => _isSuccess = false),
            child: Text('Send another message', style: TextStyle(color: colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

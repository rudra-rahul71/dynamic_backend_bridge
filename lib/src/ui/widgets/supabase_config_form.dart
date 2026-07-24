import 'package:flutter/material.dart';
import 'wizard_text_field.dart';

class SupabaseConfigForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController urlCtrl;
  final TextEditingController anonKeyCtrl;
  final Color themeColor;

  const SupabaseConfigForm({
    super.key,
    required this.formKey,
    required this.urlCtrl,
    required this.anonKeyCtrl,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter the endpoint URL and Anon Key of your self-hosted Supabase instance.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          const SizedBox(height: 20),
          WizardTextField(
            controller: urlCtrl,
            label: 'Supabase Server URL',
            hint: 'e.g. http://192.168.1.50:54321 or https://xxx.supabase.co',
            themeColor: themeColor,
            validator: (value) {
              if (value == null || value.isEmpty)
                return 'Server URL is required';
              if (!Uri.parse(value).isAbsolute) return 'Enter a valid URL';
              return null;
            },
          ),
          const SizedBox(height: 16),
          WizardTextField(
            controller: anonKeyCtrl,
            label: 'Supabase Anon Key',
            hint: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
            themeColor: themeColor,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Anon Key is required';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

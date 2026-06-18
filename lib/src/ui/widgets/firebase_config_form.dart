import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'wizard_text_field.dart';
import 'firebase_help_sheet.dart';

class FirebaseConfigForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController apiKeyCtrl;
  final TextEditingController appIdCtrl;
  final TextEditingController projectIdCtrl;
  final TextEditingController senderIdCtrl;
  final Color themeColor;

  const FirebaseConfigForm({
    super.key,
    required this.formKey,
    required this.apiKeyCtrl,
    required this.appIdCtrl,
    required this.projectIdCtrl,
    required this.senderIdCtrl,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Firebase credentials are saved locally on your device.',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  foregroundColor: const Color(0xFFF59E0B),
                ),
                icon: const Icon(Icons.help_outline, size: 16),
                label: const Text('Help', style: TextStyle(fontSize: 13)),
                onPressed: () => showFirebaseHelp(context),
              ),
            ],
          ),
          const SizedBox(height: 20),
          WizardTextField(
            controller: apiKeyCtrl,
            label: 'API Key',
            themeColor: themeColor,
            validator: (value) => value!.isEmpty ? 'API Key is required' : null,
          ),
          const SizedBox(height: 16),
          WizardTextField(
            controller: appIdCtrl,
            label: 'Application ID (App ID)',
            themeColor: themeColor,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'App ID is required';
              }
              final isApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
              if (isApple && !value.contains(':ios:')) {
                return 'Requires iOS App ID (contains ":ios:") on Apple platforms';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          WizardTextField(
            controller: projectIdCtrl,
            label: 'Project ID',
            themeColor: themeColor,
            validator: (value) => value!.isEmpty ? 'Project ID is required' : null,
          ),
          const SizedBox(height: 16),
          WizardTextField(
            controller: senderIdCtrl,
            label: 'Messaging Sender ID',
            themeColor: themeColor,
            validator: (value) => value!.isEmpty ? 'Sender ID is required' : null,
          ),
        ],
      ),
    );
  }
}

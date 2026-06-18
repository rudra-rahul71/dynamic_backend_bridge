import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

void showFirebaseHelp(BuildContext context) {
  final isApple = defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS;
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF161920),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'How to get Firebase Keys',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white60),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildHelpStep('1', 'Go to the Firebase Console and select your project.'),
                if (isApple) ...[
                  _buildHelpStep('2', 'Click "Add App" -> select iOS (Apple icon).'),
                  _buildHelpStep('3', 'Enter your Bundle ID (e.g. "com.rudra-rahul.pocApp") and click "Register app".'),
                  _buildHelpStep('4', 'Download the "GoogleService-Info.plist" file. Instead of adding it to Xcode, open it in any text editor to copy the following values:'),
                  Padding(
                    padding: const EdgeInsets.only(left: 36.0, bottom: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('• API_KEY ➔ API Key', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('• GOOGLE_APP_ID ➔ Application ID (App ID)', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('• PROJECT_ID ➔ Project ID', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                        Text('• GCM_SENDER_ID ➔ Messaging Sender ID', style: TextStyle(color: Colors.amber, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ] else ...[
                  _buildHelpStep('2', 'Click "Add App" -> select Web (</>).'),
                  _buildHelpStep('3', 'Enter any nickname and click "Register app".'),
                  _buildHelpStep('4', 'Copy the keys from the displayed "firebaseConfig" object.'),
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.02),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isApple
                        ? 'Note: On iOS/macOS, the native Apple Firebase SDK requires an iOS App ID. Web App IDs (which contain ":web:") are not compatible and will crash the application.'
                        : 'Tip: Copy the apiKey, appId, projectId, and messagingSenderId directly from the config snippet.',
                    style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Widget _buildHelpStep(String stepNumber, String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 10,
          backgroundColor: const Color(0xFFF59E0B).withOpacity(0.2),
          child: Text(
            stepNumber,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    ),
  );
}

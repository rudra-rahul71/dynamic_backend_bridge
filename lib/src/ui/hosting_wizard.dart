import 'package:flutter/material.dart';
import '../models/app_config.dart';
import '../services/config_service.dart';
import 'widgets/firebase_config_form.dart';
import 'widgets/supabase_config_form.dart';

class HostingWizard extends StatefulWidget {
  final Future<String?> Function(AppConfig config) onValidate;
  final void Function(AppConfig config) onComplete;
  final ConfigService configService;
  final Color? themeColor;

  const HostingWizard({
    super.key,
    required this.onValidate,
    required this.onComplete,
    required this.configService,
    this.themeColor,
  });

  @override
  State<HostingWizard> createState() => _HostingWizardState();
}

class _HostingWizardState extends State<HostingWizard> {
  BackendType? _selectedType;
  int _currentStep = 0;
  bool _isValidating = false;

  // Controllers for BYO Firebase
  final _apiKeyCtrl = TextEditingController();
  final _appIdCtrl = TextEditingController();
  final _senderIdCtrl = TextEditingController();
  final _projectIdCtrl = TextEditingController();
  final _fbFormKey = GlobalKey<FormState>();

  // Controllers for Supabase
  final _sbUrlCtrl = TextEditingController(text: 'http://localhost:54321');
  final _sbAnonKeyCtrl = TextEditingController();
  final _sbFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _apiKeyCtrl.dispose();
    _appIdCtrl.dispose();
    _senderIdCtrl.dispose();
    _projectIdCtrl.dispose();
    _sbUrlCtrl.dispose();
    _sbAnonKeyCtrl.dispose();
    super.dispose();
  }

  void _selectType(BackendType type) {
    setState(() {
      _selectedType = type;
      _currentStep = 1;
    });
  }

  Future<void> _testAndSave() async {
    if (_selectedType == null) return;

    setState(() {
      _isValidating = true;
    });

    AppConfig config;

    if (_selectedType == BackendType.managed) {
      config = AppConfig(backendType: BackendType.managed);
    } else if (_selectedType == BackendType.byoFirebase) {
      if (!_fbFormKey.currentState!.validate()) {
        setState(() => _isValidating = false);
        return;
      }
      config = AppConfig(
        backendType: BackendType.byoFirebase,
        firebaseApiKey: _apiKeyCtrl.text.trim(),
        firebaseAppId: _appIdCtrl.text.trim(),
        firebaseMessagingSenderId: _senderIdCtrl.text.trim(),
        firebaseProjectId: _projectIdCtrl.text.trim(),
      );
    } else {
      if (!_sbFormKey.currentState!.validate()) {
        setState(() => _isValidating = false);
        return;
      }
      config = AppConfig(
        backendType: BackendType.supabase,
        supabaseUrl: _sbUrlCtrl.text.trim(),
        supabaseAnonKey: _sbAnonKeyCtrl.text.trim(),
      );
    }

    // Validate config with parent onValidate callback
    final errorMsg = await widget.onValidate(config);
    
    if (errorMsg == null) {
      // Save configuration only if validation succeeded!
      await widget.configService.saveConfig(config);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration saved successfully!'),
            backgroundColor: Colors.greenAccent,
          ),
        );
      }

      widget.onComplete(config);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Validation failed: $errorMsg'),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isValidating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          backgroundColor: const Color(0xFF121212),
          body: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _currentStep == 0 ? _buildSelectionStep() : _buildConfigStep(),
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_isValidating) ...[
          const ModalBarrier(
            dismissible: false,
            color: Colors.black54,
          ),
          Center(
            child: Material(
              type: MaterialType.transparency,
              child: Card(
                color: const Color(0xFF1E1E1E),
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withOpacity(0.08)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: _getThemeColor(),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _selectedType == BackendType.supabase
                            ? 'Validating Supabase Connection...'
                            : _selectedType == BackendType.byoFirebase
                                ? 'Validating Firebase Configuration...'
                                : 'Initializing Cloud Services...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectionStep() {
    return Column(
      key: const ValueKey('selection-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Data Storage',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Select where your application data will be stored. You can use our default servers or host it yourself to keep absolute ownership.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.6),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),
        _buildSelectionCard(
          type: BackendType.managed,
          title: 'Our Organization',
          subtitle: 'Google Cloud',
          description: 'Fully hosted and managed by us.',
          color: const Color(0xFF6366F1),
          difficulty: 'Easy',
          difficultyColor: const Color(0xFF34D399),
        ),
        const SizedBox(height: 12),
        _buildSelectionCard(
          type: BackendType.byoFirebase,
          title: 'Your Own Google Cloud',
          subtitle: 'Custom Firebase',
          description: 'Host on your private Google Cloud.',
          color: const Color(0xFFF59E0B),
          difficulty: 'Medium',
          difficultyColor: const Color(0xFFF59E0B),
        ),
        const SizedBox(height: 12),
        _buildSelectionCard(
          type: BackendType.supabase,
          title: 'Your Own Server',
          subtitle: 'Supabase / Docker',
          description: 'Host on your own VPS or server.',
          color: const Color(0xFF3ECF8E),
          difficulty: 'Advanced',
          difficultyColor: const Color(0xFFEF4444),
        ),
      ],
    );
  }

  Widget _buildSelectionCard({
    required BackendType type,
    required String title,
    required String subtitle,
    required String description,
    required Color color,
    required String difficulty,
    required Color difficultyColor,
  }) {
    return InkWell(
      onTap: () => _selectType(type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(color: color.withOpacity(0.3), width: 1.5),
              ),
              child: Icon(
                type == BackendType.managed
                    ? Icons.cloud_done_rounded
                    : type == BackendType.byoFirebase
                        ? Icons.local_fire_department_rounded
                        : Icons.dns_rounded,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: difficultyColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: difficultyColor.withOpacity(0.25), width: 1),
                        ),
                        child: Text(
                          difficulty,
                          style: TextStyle(
                            color: difficultyColor,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color.withOpacity(0.85),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        ' • ',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 11,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigStep() {
    return Column(
      key: const ValueKey('config-step'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () {
                setState(() {
                  _currentStep = 0;
                });
              },
            ),
            const Text(
              'Configure Backend',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (_selectedType == BackendType.byoFirebase)
          FirebaseConfigForm(
            formKey: _fbFormKey,
            apiKeyCtrl: _apiKeyCtrl,
            appIdCtrl: _appIdCtrl,
            projectIdCtrl: _projectIdCtrl,
            senderIdCtrl: _senderIdCtrl,
            themeColor: _getThemeColor(),
          ),
        if (_selectedType == BackendType.supabase)
          SupabaseConfigForm(
            formKey: _sbFormKey,
            urlCtrl: _sbUrlCtrl,
            anonKeyCtrl: _sbAnonKeyCtrl,
            themeColor: _getThemeColor(),
          ),
        if (_selectedType == BackendType.managed) _buildManagedConfirmation(),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _getThemeColor(),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            onPressed: _isValidating ? null : _testAndSave,
            child: Text(
              _selectedType == BackendType.managed
                  ? 'Confirm & Continue'
                  : 'Test & Save Configuration',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getThemeColor() {
    if (widget.themeColor != null) {
      return widget.themeColor!;
    }
    switch (_selectedType) {
      case BackendType.managed:
        return const Color(0xFF6366F1);
      case BackendType.byoFirebase:
        return const Color(0xFFF59E0B);
      case BackendType.supabase:
        return const Color(0xFF3ECF8E);
      default:
        return Colors.indigo;
    }
  }

  Widget _buildManagedConfirmation() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF818CF8)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'You have selected the fully managed cloud backend. No setup or external configuration is required.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

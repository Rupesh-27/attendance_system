import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/dashboard_screen.dart';
import 'services/api_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LanguageService.instance.init();
  runApp(const BrandHrmsApp());
}

class BrandHrmsApp extends StatelessWidget {
  const BrandHrmsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: LanguageService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'BrandHRMS',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F9D8A),
              primary: const Color(0xFF0F9D8A),
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: const Color(0xFFF8FAFC),
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.adaptivePlatformDensity,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
          ),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            // Safe sp clamping for Android accessibility text scaling
            final clampedScaler = mediaQuery.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.25,
            );
            return MediaQuery(
              data: mediaQuery.copyWith(textScaler: clampedScaler),
              child: child!,
            );
          },
          home: const LoginScreen(),
        );
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _prefRememberMe = 'remember_me';
  static const String _prefSavedIdentifier = 'saved_identifier';
  static const String _prefSavedPassword = 'saved_password';

  final employeeIdController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;
  bool rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isRemembered = prefs.getBool(_prefRememberMe) ?? false;
      if (isRemembered) {
        final savedIdentifier = prefs.getString(_prefSavedIdentifier) ?? '';
        final savedPassword = prefs.getString(_prefSavedPassword) ?? '';
        if (mounted) {
          setState(() {
            rememberMe = true;
            employeeIdController.text = savedIdentifier;
            passwordController.text = savedPassword;
          });
        }
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final identifier = employeeIdController.text.trim();
    final password = passwordController.text.trim();

    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr('enter_credentials_prompt'))),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await ApiService.login(identifier, password);

    if (!mounted) return;
    setState(() => isLoading = false);

    if (result['success'] == true) {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (rememberMe) {
          await prefs.setBool(_prefRememberMe, true);
          await prefs.setString(_prefSavedIdentifier, identifier);
          await prefs.setString(_prefSavedPassword, password);
        } else {
          await prefs.remove(_prefRememberMe);
          await prefs.remove(_prefSavedIdentifier);
          await prefs.remove(_prefSavedPassword);
        }
      } catch (_) {}

      if (!mounted) return;
      DashboardScreen.pickNewQuote();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] != null
              ? tr(result['message'] as String)
              : tr('login_failed')),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton.icon(
                  onPressed: () => LanguageService.showLanguagePickerModal(context),
                  icon: Text(
                    LanguageService.instance.currentLanguage.flag,
                    style: const TextStyle(fontSize: 18),
                  ),
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        LanguageService.instance.currentLanguage.nativeName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Image.asset('assets/images/brandcrock_logo.png', height: 100),

              const SizedBox(height: 40),

              Text(
                tr('welcome_to_brandhrms'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              Text(
                tr('employee_login'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),

              TextField(
                controller: employeeIdController,
                decoration: InputDecoration(
                  labelText: tr('employee_id_or_email'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),

              const SizedBox(height: 20),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  labelText: tr('password'),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: rememberMe,
                      activeColor: Theme.of(context).colorScheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      onChanged: (val) {
                        setState(() {
                          rememberMe = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        rememberMe = !rememberMe;
                      });
                    },
                    child: Text(
                      tr('remember_me'),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF374151),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: isLoading ? null : login,
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(tr('login'), style: const TextStyle(fontSize: 17)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

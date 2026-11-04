import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

/// Screen displayed if the 4th tab is embedded.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const BrandSideMenuDrawer(isEmbedded: true);
  }
}

/// The Slide-In Side Navigation Panel (EndDrawer):
/// - Slides in from right to left
/// - Uses the authentic BrandHR Logo Theme (Teal #0F9D8A, Lime Green #84B83C, Clean Light Surface)
/// - Fully reactive to language changes via LanguageService.instance
class BrandSideMenuDrawer extends StatelessWidget {
  final bool isEmbedded;
  const BrandSideMenuDrawer({super.key, this.isEmbedded = false});

  // Corporate Brand Theme Colors (from BrandHR logo)
  static const Color brandPrimary = Color(0xFF0F9D8A); // Deep Teal
  static const Color brandAccent = Color(0xFF84B83C); // Fresh Lime Green

  Widget _buildVerticalLetter(String char) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final emp = ApiService.currentEmployee;
        final initial = (emp != null && emp.fullName.isNotEmpty)
            ? emp.fullName[0].toUpperCase()
            : 'E';
        final name = (emp != null && emp.fullName.isNotEmpty)
            ? emp.fullName
            : tr('Employee');
        final roleName = tr(emp?.role ?? 'EMPLOYEE');

        final content = Row(
          children: [
            // LEFT COLUMN: Vertical B R A N D   C R O C K (Covers 100% full height top-to-bottom)
            Expanded(
              flex: 4,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F9D8A), // BrandHR Primary Teal
                      Color(0xFF0E8A79),
                      Color(0xFF84B83C), // BrandHR Fresh Lime Green
                    ],
                  ),
                  border: Border(
                    right: BorderSide(
                      color: Color(0xFFE2E8F0),
                      width: 1.5,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // B R A N D
                          _buildVerticalLetter('B'),
                          _buildVerticalLetter('R'),
                          _buildVerticalLetter('A'),
                          _buildVerticalLetter('N'),
                          _buildVerticalLetter('D'),

                          // Separator Dot
                          const SizedBox(height: 12),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white70,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // C R O C K
                          _buildVerticalLetter('C'),
                          _buildVerticalLetter('R'),
                          _buildVerticalLetter('O'),
                          _buildVerticalLetter('C'),
                          _buildVerticalLetter('K'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // RIGHT COLUMN: Clean Light Adaptable Menu List (Full Height)
            Expanded(
              flex: 6,
              child: Container(
                color: const Color(0xFFF8FAFC),
                child: SafeArea(
                  child: Column(
                    children: [
                      // Top bar with Close button (✕)
                      if (!isEmbedded)
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8, right: 8),
                            child: IconButton(
                              icon: const Icon(
                                Icons.close_rounded,
                                color: Color(0xFF475569),
                                size: 26,
                              ),
                              tooltip: tr('cancel'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),

                      // Adaptable Menu List (Supports future options seamlessly)
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          children: [
                            // 1. Primary Item: Profile Card (Light Logo Theme)
                            _buildProfileCard(
                              context,
                              initial: initial,
                              name: name,
                              roleName: roleName,
                              isEmbedded: isEmbedded,
                            ),

                            // Future menu options (like Settings, Help, etc.) can be plugged in here
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );

        if (isEmbedded) {
          return Scaffold(
            backgroundColor: const Color(0xFFF8FAFC),
            body: content,
          );
        }

        return Drawer(
          width: MediaQuery.of(context).size.width * 0.88,
          backgroundColor: const Color(0xFFF8FAFC),
          elevation: 16,
          child: content,
        );
      },
    );
  }

  Widget _buildProfileCard(
    BuildContext context, {
    required String initial,
    required String name,
    required String roleName,
    required bool isEmbedded,
  }) {
    return InkWell(
      onTap: () {
        if (!isEmbedded) {
          Navigator.of(context).pop(); // close endDrawer
        }
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const ProfileDetailsScreen(),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: brandPrimary.withValues(alpha: 0.16),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: brandPrimary.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Deep Teal Avatar Circle
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: brandPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x220F9D8A),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // Profile Title (Localized)
            Text(
              tr('profile'),
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 1),

            // Employee Name
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: brandPrimary,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3.5),

            // Role Badge with Logo Lime Green Accent (Localized)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: brandAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: brandAccent.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: brandAccent, // Logo Lime Green
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      roleName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF4D7C0F), // High contrast dark lime
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),

            // Details Button (Localized)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: brandPrimary,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: brandPrimary.withValues(alpha: 0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 1.5),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tr('details'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 11,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separate Page displaying complete employee profile details with a back button.
class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  static const Color primaryColor = Color(0xFF0F9D8A);
  static const Color accentColor = Color(0xFF84B83C);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        final emp = ApiService.currentEmployee;
        final office = ApiService.assignedOffice;

        final initial = (emp != null && emp.fullName.isNotEmpty)
            ? emp.fullName[0].toUpperCase()
            : 'E';
        final name = (emp != null && emp.fullName.isNotEmpty)
            ? emp.fullName
            : tr('Employee');
        final code = emp?.employeeCode ?? 'EMP1001';
        final email = (emp?.email != null && emp!.email!.isNotEmpty)
            ? emp.email!
            : '${code.toLowerCase()}@brandcrock.com';
        final officeName = (office?.name != null &&
                office!.name.isNotEmpty &&
                office.name != 'Assigned Office')
            ? office.name
            : tr('assigned_office');
        final roleName = tr(emp?.role ?? 'EMPLOYEE');

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: AppBar(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              tr('my_profile'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Avatar & Role Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Status & Role Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3.5,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  emp?.isActive == true
                                      ? tr('active')
                                      : tr('inactive'),
                                  style: const TextStyle(
                                    color: Color(0xFF4D7C0F),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            roleName,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Employee Information
                _sectionCard(
                  title: tr('employee_information'),
                  children: [
                    _profileItem(Icons.badge_outlined, tr('employee_id'), code),
                    _profileItem(
                      Icons.email_outlined,
                      tr('email'),
                      email,
                    ),
                    _profileItem(
                      Icons.phone_outlined,
                      tr('status'),
                      emp?.isActive == true ? tr('active') : tr('inactive'),
                    ),
                    _profileItem(
                      Icons.business_outlined,
                      tr('role'),
                      roleName,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Work Information (Time Zone removed)
                _sectionCard(
                  title: tr('work_information'),
                  children: [
                    _profileItem(
                      Icons.location_city_outlined,
                      tr('assigned_office'),
                      officeName,
                    ),
                    _profileItem(
                      Icons.location_on_outlined,
                      tr('work_address'),
                      '131, Lakeview Street, Vinayakarpuram East, Tambaram, Chennai, India',
                    ),
                    _profileItem(
                      Icons.work_outline,
                      tr('geofence_radius'),
                      '${LanguageService.formatDecimal(office?.radiusMeters ?? 10, fractionDigits: 0)} ${tr('meters')}',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // App Preferences / Language Selection
                _sectionCard(
                  title: tr('language_preferences'),
                  children: [
                    _languageSelectionTile(context),
                  ],
                ),

                const SizedBox(height: 16),

                // Logout Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await ApiService.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    icon: const Icon(Icons.logout),
                    label: Text(
                      tr('logout'),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _languageSelectionTile(BuildContext context) {
    final currentLang = LanguageService.instance.currentLanguage;

    return InkWell(
      onTap: () => _showLanguageSelector(context),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.translate_rounded,
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('language'),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currentLang.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${currentLang.name} (${currentLang.nativeName})',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    LanguageService.showLanguagePickerModal(context);
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _profileItem(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: primaryColor, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

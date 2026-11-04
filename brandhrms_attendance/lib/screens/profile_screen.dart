import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

/// Landing screen displayed under the bottom navigation's 4th tab.
/// Displays an AppBar with the Menu Bar icon, which opens the full-screen split panel.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryColor = Color(0xFF0F9D8A);

  void _openSplitMenu(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        fullscreenDialog: true,
        pageBuilder: (context, _, __) => const FullScreenSplitMenu(),
        transitionsBuilder: (context, animation, _, child) {
          final tween = Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeInOutCubic));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LanguageService.instance,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F7F9),
          appBar: AppBar(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            leading: IconButton(
              icon: const Icon(Icons.menu),
              tooltip: tr('menu'),
              onPressed: () => _openSplitMenu(context),
            ),
            title: Text(
              tr('menu'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_rounded,
                      size: 46,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    tr('menu'),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('my_profile'),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: 220,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _openSplitMenu(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.menu),
                      label: Text(
                        tr('menu'),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}

/// Full-Screen Split Navigation Panel:
/// - Left Half: BRAND CROCK vertically stacked one letter below the other
/// - Right Half: Only the Profile section alone
class FullScreenSplitMenu extends StatelessWidget {
  const FullScreenSplitMenu({super.key});

  static const Color brandPrimary = Color(0xFF0F9D8A);

  Widget _buildVerticalLetter(String char) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Text(
        char,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
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

        return Scaffold(
          backgroundColor: const Color(0xFF0F172A),
          body: SafeArea(
            child: Stack(
              children: [
                // Split Screen: Left Half (Brand Crock) & Right Half (Profile Section)
                Row(
                  children: [
                    // LEFT HALF: Vertical B R A N D   C R O C K
                    Expanded(
                      flex: 4,
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF0F9D8A),
                              Color(0xFF085F53),
                              Color(0xFF04342E),
                            ],
                          ),
                          border: Border(
                            right: BorderSide(
                              color: Color(0xFF1E293B),
                              width: 1.5,
                            ),
                          ),
                        ),
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

                                // Separator dot
                                const SizedBox(height: 12),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF5EEAD4),
                                    shape: BoxShape.circle,
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

                    // RIGHT HALF: Only the Profile Section Alone
                    Expanded(
                      flex: 6,
                      child: Container(
                        color: const Color(0xFF0F172A),
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ProfileDetailsScreen(),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 24,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    brandPrimary.withValues(alpha: 0.22),
                                    brandPrimary.withValues(alpha: 0.08),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: brandPrimary.withValues(alpha: 0.5),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: brandPrimary.withValues(alpha: 0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    decoration: const BoxDecoration(
                                      color: brandPrimary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    tr('profile'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Color(0xFF5EEAD4),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    roleName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 11,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: brandPrimary.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Details',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Top Right Close (✕) Button
                Positioned(
                  top: 10,
                  right: 12,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    tooltip: tr('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Separate Page displaying complete employee profile details with a back button.
class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});

  static const Color primaryColor = Color(0xFF0F9D8A);

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
                      const SizedBox(height: 5),
                      Text(
                        roleName,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
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

                // Work Information (Time Zone removed per previous request)
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

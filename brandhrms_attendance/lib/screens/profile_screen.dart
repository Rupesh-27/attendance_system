import 'dart:io';

import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/avatar_service.dart';
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
      listenable: Listenable.merge([
        LanguageService.instance,
        AvatarService.instance,
      ]),
      builder: (context, _) {
        final emp = ApiService.currentEmployee;
        final initial = (emp != null && emp.fullName.isNotEmpty)
            ? emp.fullName[0].toUpperCase()
            : 'E';
        final brandPart1 = tr('brand_crock_part1').isNotEmpty && tr('brand_crock_part1') != 'brand_crock_part1'
            ? tr('brand_crock_part1').toUpperCase()
            : 'BRAND';
        final brandPart2 = tr('brand_crock_part2').isNotEmpty && tr('brand_crock_part2') != 'brand_crock_part2'
            ? tr('brand_crock_part2').toUpperCase()
            : 'CROCK';

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
                          // Brand Part 1 (e.g., B R A N D / Б Р Э Н Д)
                          for (final ch in brandPart1.characters)
                            _buildVerticalLetter(ch),

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

                          // Brand Part 2 (e.g., C R O C K / К Р О К)
                          for (final ch in brandPart2.characters)
                            _buildVerticalLetter(ch),
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
          vertical: 12,
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
            // Avatar Circle (Custom Photo or Deep Teal Initial)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: brandPrimary,
                shape: BoxShape.circle,
                image: AvatarService.instance.hasCustomAvatar
                    ? DecorationImage(
                        image: FileImage(File(AvatarService.instance.avatarPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x220F9D8A),
                    blurRadius: 4,
                    offset: Offset(0, 1.5),
                  ),
                ],
              ),
              child: AvatarService.instance.hasCustomAvatar
                  ? null
                  : Center(
                      child: Text(
                        initial,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 8),

            // Profile Title and Arrow Mark (Option B)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  tr('profile'),
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: brandPrimary,
                  size: 15,
                ),
              ],
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
      listenable: Listenable.merge([
        LanguageService.instance,
        AvatarService.instance,
      ]),
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
                      // Interactive Avatar with Camera Badge
                      Stack(
                        children: [
                          InkWell(
                            onTap: () => _showAvatarOptionsModal(context, emp?.id),
                            borderRadius: BorderRadius.circular(45),
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                shape: BoxShape.circle,
                                image: AvatarService.instance.hasCustomAvatar
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(AvatarService.instance.avatarPath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x330F9D8A),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: AvatarService.instance.hasCustomAvatar
                                  ? null
                                  : Center(
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
                          ),
                          // Edit Floating Camera Badge Button
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showAvatarOptionsModal(context, emp?.id),
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 5,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
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

  static void _showAvatarOptionsModal(BuildContext context, String? employeeId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final hasCustom = AvatarService.instance.hasCustomAvatar;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  tr('profile_photo'),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 14),

                // Option 1: Choose from Gallery / Files
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.photo_library_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  title: Text(
                    tr('choose_from_gallery'),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final success = await AvatarService.instance.pickAndSaveAvatar(employeeId);
                    if (success && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(tr('photo_updated')),
                          backgroundColor: primaryColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                ),

                // Option 2: Remove Photo (only shown if custom photo is set)
                if (hasCustom)
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 22,
                      ),
                    ),
                    title: Text(
                      tr('remove_photo'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                    onTap: () async {
                      Navigator.of(ctx).pop();
                      await AvatarService.instance.removeAvatar(employeeId);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(tr('photo_removed')),
                            backgroundColor: const Color(0xFF475569),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

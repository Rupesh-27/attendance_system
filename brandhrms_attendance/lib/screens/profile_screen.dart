import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';
import '../services/language_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
            automaticallyImplyLeading: false,
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
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
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 5),

                      Text(
                        roleName,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

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
                _profileItem(
                  Icons.schedule_outlined,
                  tr('work_timezone'),
                  office?.timezone ?? 'Asia/Kolkata',
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

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ApiService.logout();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout),
                label: Text(tr('logout'), style: const TextStyle(fontSize: 16)),
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
              child: const Icon(Icons.translate_rounded, color: primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('language'),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        currentLang.flag,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${currentLang.name} (${currentLang.nativeName})',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
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

  Widget _sectionCard({required String title, required List<Widget> children}) {
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
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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

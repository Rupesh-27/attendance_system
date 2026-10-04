import 'package:flutter/material.dart';

import '../main.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color primaryColor = Color(0xFF0F9D8A);

  @override
  Widget build(BuildContext context) {
    final emp = ApiService.currentEmployee;
    final office = ApiService.assignedOffice;

    final initial = (emp != null && emp.fullName.isNotEmpty)
        ? emp.fullName[0].toUpperCase()
        : 'E';
    final name = emp?.fullName ?? 'Employee';
    final code = emp?.employeeCode ?? 'EMP1001';
    final email = (emp?.email != null && emp!.email!.isNotEmpty)
        ? emp.email!
        : '${code.toLowerCase()}@brandcrock.com';
    final officeName = office?.name ?? 'Assigned Office';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F9),

      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
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
                    emp?.role ?? 'Employee',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: 'Employee Information',
              children: [
                _profileItem(Icons.badge_outlined, 'Employee ID', code),
                _profileItem(
                  Icons.email_outlined,
                  'Email',
                  email,
                ),
                _profileItem(Icons.phone_outlined, 'Status', emp?.isActive == true ? 'Active' : 'Inactive'),
                _profileItem(
                  Icons.business_outlined,
                  'Role',
                  emp?.role ?? 'EMPLOYEE',
                ),
              ],
            ),

            const SizedBox(height: 16),

            _sectionCard(
              title: 'Work Information',
              children: [
                _profileItem(
                  Icons.location_city_outlined,
                  'Assigned Office',
                  officeName,
                ),
                _profileItem(Icons.work_outline, 'Geofence Radius', '${office?.radiusMeters.toStringAsFixed(0) ?? "10"} meters'),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  ApiService.logout();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                    (route) => false,
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout', style: TextStyle(fontSize: 16)),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
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

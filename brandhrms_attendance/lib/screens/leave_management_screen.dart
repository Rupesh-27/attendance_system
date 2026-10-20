import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/language_service.dart';

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
}

String _formatDateIso(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({super.key});

  @override
  State<LeaveManagementScreen> createState() => LeaveManagementScreenState();
}

class LeaveManagementScreenState extends State<LeaveManagementScreen> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  bool _isLoading = true;
  List<LeaveType> _leaveTypes = [];
  List<EmployeeLeaveBalance> _balances = [];
  List<LeaveApplication> _myApplications = [];
  String _selectedStatusFilter = 'ALL';
  int _activeTabIndex = 0; // 0: Leave Balance, 1: Application History
  String? _selectedLeaveTypeFilter; // null for all, or specific leaveTypeId

  @override
  void initState() {
    super.initState();
    refreshData();
  }

  Future<void> refreshData() async {
    setState(() => _isLoading = true);
    try {
      final typesFuture = ApiService.getLeaveTypes();
      final balancesFuture = ApiService.getLeaveBalances();
      final myAppsFuture = ApiService.getMyLeaveApplications();

      final results = await Future.wait([
        typesFuture,
        balancesFuture,
        myAppsFuture,
      ]);

      if (mounted) {
        setState(() {
          _leaveTypes = results[0] as List<LeaveType>;
          _balances = results[1] as List<EmployeeLeaveBalance>;
          _myApplications = results[2] as List<LeaveApplication>;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          tr('my_leaves'),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: refreshData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openApplyLeaveModal,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(tr('apply_leave'), style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : Column(
              children: [
                _buildSegmentedSwitcher(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: refreshData,
                    color: primaryColor,
                    child: _activeTabIndex == 0
                        ? _buildLeaveBalanceView()
                        : _buildApplicationHistoryView(),
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== SEGMENTED SWITCHER ====================
  Widget _buildSegmentedSwitcher() {
    final pendingCount =
        _myApplications.where((a) => a.status == 'PENDING').length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() => _activeTabIndex = 0);
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 0 ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTabIndex == 0
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline_rounded,
                      size: 16,
                      color: _activeTabIndex == 0
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr('leave_balance'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTabIndex == 0
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                setState(() {
                  _activeTabIndex = 1;
                  _selectedStatusFilter = 'ALL';
                  _selectedLeaveTypeFilter = null;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _activeTabIndex == 1 ? primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: _activeTabIndex == 1
                      ? [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 16,
                      color: _activeTabIndex == 1
                          ? Colors.white
                          : const Color(0xFF475569),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tr('application_history'),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _activeTabIndex == 1
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                    ),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _activeTabIndex == 1
                              ? Colors.white
                              : const Color(0xFFF59E0B),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: _activeTabIndex == 1
                                ? primaryColor
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== LEAVE BALANCE VIEW ====================
  Widget _buildLeaveBalanceView() {
    if (_balances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No leave balances found for current year',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
      children: [
        Text(
          tr('leave_balances'),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),

        ..._balances.asMap().entries.map((entry) {
          final index = entry.key;
          final bal = entry.value;
          return _buildDetailedBalanceCard(bal, index);
        }),
      ],
    );
  }

  Widget _buildDetailedBalanceCard(EmployeeLeaveBalance bal, int index) {
    final colors = [
      {'color': const Color(0xFF0F9D8A), 'bg': const Color(0xFFECFDF5)},
      {'color': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'color': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
    ];
    final scheme = colors[index % colors.length];

    final double progress = bal.allocatedDays > 0
        ? (bal.remainingDays / bal.allocatedDays).clamp(0.0, 1.0)
        : 0.0;

    final remainingText = bal.remainingDays.truncateToDouble() == bal.remainingDays
        ? bal.remainingDays.toInt().toString()
        : bal.remainingDays.toStringAsFixed(1);

    final usedText = bal.usedDays.truncateToDouble() == bal.usedDays
        ? bal.usedDays.toInt().toString()
        : bal.usedDays.toStringAsFixed(1);

    String ruleText = 'Annual allowance for standard employee entitlement';
    if (bal.leaveTypeCode == 'CL' || bal.leaveTypeName.toLowerCase().contains('casual')) {
      ruleText = 'Max 1 day per application • Urgent personal work';
    } else if (bal.leaveTypeCode == 'SL' || bal.leaveTypeName.toLowerCase().contains('sick')) {
      ruleText = 'Medical certificate required for 2+ consecutive days';
    } else if (bal.leaveTypeCode == 'PL' || bal.leaveTypeName.toLowerCase().contains('paid')) {
      ruleText = 'Privilege leave for planned holidays and family events';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              _selectedLeaveTypeFilter = bal.leaveTypeId;
              _selectedStatusFilter = 'ALL';
              _activeTabIndex = 1;
            });
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: scheme['bg'] as Color,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            bal.leaveTypeCode.isNotEmpty ? bal.leaveTypeCode : 'LEAVE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: scheme['color'] as Color,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          bal.leaveTypeName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'History',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: scheme['color'] as Color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.chevron_right, size: 16, color: scheme['color'] as Color),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Metrics Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Allocated',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${bal.allocatedDays.toInt()} Days',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Used',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$usedText Days',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'Available',
                            style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$remainingText Days',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: scheme['color'] as Color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(scheme['color'] as Color),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 8),

                // Policy / Rule Tag
                Row(
                  children: [
                    const Icon(Icons.info_outline, size: 12, color: Color(0xFF94A3B8)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        ruleText,
                        style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==================== APPLICATION HISTORY VIEW ====================
  Widget _buildApplicationHistoryView() {
    final leaveTypeName = _selectedLeaveTypeFilter != null
        ? _balances.firstWhere(
            (b) => b.leaveTypeId == _selectedLeaveTypeFilter,
            orElse: () => EmployeeLeaveBalance(
              id: '',
              employeeId: '',
              leaveTypeId: '',
              leaveTypeName: 'Selected',
              leaveTypeCode: '',
              year: 2026,
              allocatedDays: 0,
              usedDays: 0,
              remainingDays: 0,
            ),
          ).leaveTypeName
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      children: [
        if (_selectedLeaveTypeFilter != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFBAE6FD)),
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_alt, size: 16, color: Color(0xFF0284C7)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Filtered by: $leaveTypeName',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0369A1),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    setState(() => _selectedLeaveTypeFilter = null);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close, size: 14, color: Color(0xFF0369A1)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildStatusFilterChips(),
        const SizedBox(height: 14),
        _buildApplicationsList(),
      ],
    );
  }

  Widget _buildStatusFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': tr('all_requests')},
      {'key': 'PENDING', 'label': tr('pending')},
      {'key': 'APPROVED', 'label': tr('approved')},
      {'key': 'REJECTED', 'label': tr('rejected')},
      {'key': 'WITHDRAWN', 'label': tr('withdrawn')},
      {'key': 'CANCELLATION_PENDING', 'label': tr('cancel_requested')},
      {'key': 'CANCELLED', 'label': tr('cancelled')},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: filters.map((f) {
        final isSelected = _selectedStatusFilter == f['key'];
        return ChoiceChip(
          label: Text(
            f['label']!,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF475569),
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 12,
            ),
          ),
          selected: isSelected,
          selectedColor: primaryColor,
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isSelected ? primaryColor : const Color(0xFFCBD5E1),
            ),
          ),
          onSelected: (val) {
            setState(() {
              _selectedStatusFilter = val ? f['key']! : 'ALL';
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildApplicationsList() {
    final filtered = _myApplications.where((a) {
      if (_selectedStatusFilter != 'ALL' && a.status != _selectedStatusFilter) {
        return false;
      }
      if (_selectedLeaveTypeFilter != null &&
          a.leaveTypeId != _selectedLeaveTypeFilter) {
        return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      final isFiltered =
          _selectedStatusFilter != 'ALL' || _selectedLeaveTypeFilter != null;
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              tr('no_leave_requests'),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isFiltered
                  ? tr('no_requests_filter')
                  : tr('tap_apply_leave'),
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
            if (isFiltered) ...[
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () => setState(() {
                  _selectedStatusFilter = 'ALL';
                  _selectedLeaveTypeFilter = null;
                }),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Show All Requests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((app) => _buildApplicationCard(app)).toList(),
    );
  }

  Widget _buildDetailColumn({
    required String label,
    required String value,
    IconData? icon,
    Color? valueColor,
    FontWeight? valueFontWeight,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: const Color(0xFF94A3B8)),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: valueFontWeight ?? FontWeight.w600,
            color: valueColor ?? const Color(0xFF1E293B),
            height: 1.25,
          ),
        ),
      ],
    );
  }

  Widget _buildApplicationCard(LeaveApplication app) {
    final startStr = _formatDate(app.startDate);
    final endStr = _formatDate(app.endDate);
    final durationDisplay = app.isHalfDay
        ? '0.5 Day (${app.halfDaySession == "SECOND_HALF" || app.halfDaySession == "Session 2" ? "Session 2 (PM)" : "Session 1 (AM)"})'
        : '${app.totalDays.toInt()} ${app.totalDays > 1 ? "Days" : "Day"}';
    final appliedOnStr = _formatDate(app.createdAt);

    Color statusColor;
    Color statusBg;
    String statusDisplay = app.status;

    switch (app.status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusBg = const Color(0xFFD1FAE5);
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusBg = const Color(0xFFFEE2E2);
        break;
      case 'WITHDRAWN':
        statusColor = const Color(0xFF64748B);
        statusBg = const Color(0xFFF1F5F9);
        statusDisplay = 'WITHDRAWN';
        break;
      case 'CANCELLATION_PENDING':
        statusColor = const Color(0xFF6366F1);
        statusBg = const Color(0xFFEEF2FF);
        statusDisplay = 'CANCEL REQUESTED';
        break;
      case 'CANCELLED':
        statusColor = const Color(0xFF6B7280);
        statusBg = const Color(0xFFF3F4F6);
        break;
      case 'PENDING':
      default:
        statusColor = const Color(0xFFF59E0B);
        statusBg = const Color(0xFFFEF3C7);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F9D8A).withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        app.leaveTypeCode.isNotEmpty ? app.leaveTypeCode : 'LEAVE',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        app.leaveTypeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusDisplay,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Structured 2-column details grid
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailColumn(
                        label: tr('from_date'),
                        value: startStr,
                        icon: Icons.calendar_today_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailColumn(
                        label: tr('to_date'),
                        value: endStr,
                        icon: Icons.event_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _buildDetailColumn(
                        label: tr('duration'),
                        value: durationDisplay,
                        icon: Icons.timelapse_rounded,
                        valueColor: primaryColor,
                        valueFontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildDetailColumn(
                        label: tr('applied_on'),
                        value: appliedOnStr,
                        icon: Icons.schedule_rounded,
                      ),
                    ),
                  ],
                ),
                if ((app.applyingTo != null && app.applyingTo!.isNotEmpty) ||
                    (app.cc != null && app.cc!.isNotEmpty)) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildDetailColumn(
                          label: tr('applying_to'),
                          value: (app.applyingTo != null && app.applyingTo!.isNotEmpty)
                              ? app.applyingTo!
                              : '-',
                          icon: Icons.person_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDetailColumn(
                          label: tr('cc_to'),
                          value: (app.cc != null && app.cc!.isNotEmpty)
                              ? app.cc!
                              : '-',
                          icon: Icons.people_outline,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (app.reason.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr('reason').toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    app.reason,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF334155),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (app.managerRemarks != null && app.managerRemarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.comment_outlined, size: 14, color: Color(0xFF64748B)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Manager Remarks: ${app.managerRemarks}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (app.status == 'CANCELLATION_PENDING') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.hourglass_top, size: 14, color: Color(0xFF6366F1)),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Cancellation is pending manager approval',
                      style: TextStyle(fontSize: 11, color: Color(0xFF4338CA), fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (app.status == 'PENDING' || app.status == 'APPROVED') ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmCancelApplication(app),
                icon: Icon(
                  app.status == 'PENDING' ? Icons.undo : Icons.cancel_outlined,
                  size: 16,
                  color: const Color(0xFFEF4444),
                ),
                label: Text(
                  app.status == 'PENDING' ? 'Withdraw Application' : 'Request Cancellation',
                  style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== ACTIONS & MODALS ====================
  void _openApplyLeaveModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ApplyLeaveBottomSheet(
        leaveTypes: _leaveTypes,
        balances: _balances,
        onApplied: () {
          Navigator.pop(context);
          refreshData();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Leave application submitted successfully!'),
              backgroundColor: primaryColor,
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmCancelApplication(LeaveApplication app) async {
    final isPending = app.status == 'PENDING';
    final title = isPending ? 'Withdraw Leave Application?' : 'Request Leave Cancellation?';
    final content = isPending
        ? 'Are you sure you want to withdraw this application? It will be cancelled immediately and held days returned.'
        : 'Your leave has already been approved. Cancelling will submit a request to your manager for approval.';
    final buttonText = isPending ? 'Withdraw' : 'Submit Request';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text(buttonText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await ApiService.cancelLeaveApplication(app.id);
      if (success) {
        refreshData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isPending
                  ? 'Application withdrawn successfully'
                  : 'Cancellation request submitted to manager'),
              backgroundColor: primaryColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to process cancellation request'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
        }
      }
    }
  }
}

// ==================== APPLY LEAVE BOTTOM SHEET ====================
class _ApplyLeaveBottomSheet extends StatefulWidget {
  final List<LeaveType> leaveTypes;
  final List<EmployeeLeaveBalance> balances;
  final VoidCallback onApplied;

  const _ApplyLeaveBottomSheet({
    required this.leaveTypes,
    required this.balances,
    required this.onApplied,
  });

  @override
  State<_ApplyLeaveBottomSheet> createState() => _ApplyLeaveBottomSheetState();
}

class _ApplyLeaveBottomSheetState extends State<_ApplyLeaveBottomSheet> {
  static const Color primaryColor = Color(0xFF0F9D8A);

  String? _selectedTypeId;
  DateTime _startDate = DateTime.now().add(const Duration(days: 1));
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _isHalfDay = false;
  String _halfDaySession = 'FIRST_HALF';
  final TextEditingController _reasonController = TextEditingController();
  final String _applyingTo = 'Mathumitha';
  final List<String> _ccList = [];
  PlatformFile? _attachedFile;
  int _attachedFileSize = 0;

  bool _isSubmitting = false;
  String? _errorMessage;

  Future<void> _pickFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg'],
      );
      if (file != null) {
        final size = file.lengthSync() ?? (await file.length()) ?? 0;
        if (size > 10 * 1024 * 1024) {
          setState(() {
            _errorMessage = 'Selected file exceeds the 10 MB limit.';
          });
          return;
        }
        setState(() {
          _attachedFile = file;
          _attachedFileSize = size;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to pick file. Please try again.';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _attachedFile = null;
      _attachedFileSize = 0;
    });
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _showAddCcDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add CC', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter colleague name or email to keep them notified:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'e.g. Alice Smith, HR',
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isNotEmpty && !_ccList.contains(text)) {
                setState(() => _ccList.add(text));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.leaveTypes.isNotEmpty) {
      _selectedTypeId = widget.leaveTypes.first.id;
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _isCasualLeave {
    if (_selectedTypeId == null) return false;
    try {
      final t = widget.leaveTypes.firstWhere((lt) => lt.id == _selectedTypeId);
      return t.code == 'CL' || t.name.toLowerCase().contains('casual');
    } catch (_) {
      return false;
    }
  }

  bool get _isSickLeave {
    if (_selectedTypeId == null) return false;
    try {
      final t = widget.leaveTypes.firstWhere((lt) => lt.id == _selectedTypeId);
      return t.code == 'SL' || t.name.toLowerCase().contains('sick');
    } catch (_) {
      return false;
    }
  }

  double get _calculatedDays {
    if (_isHalfDay) return 0.5;
    return _endDate.difference(_startDate).inDays + 1.0;
  }

  EmployeeLeaveBalance? get _selectedBalance {
    if (_selectedTypeId == null) return null;
    try {
      return widget.balances.firstWhere((b) => b.leaveTypeId == _selectedTypeId);
    } catch (_) {
      return null;
    }
  }

  Future<void> _submit() async {
    if (_selectedTypeId == null) {
      setState(() => _errorMessage = 'Please select a leave type');
      return;
    }
    if (_reasonController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please provide a reason for the leave');
      return;
    }

    if (_isCasualLeave && _calculatedDays > 1.0) {
      setState(() => _errorMessage = 'Casual Leave cannot exceed 1 day per application.');
      return;
    }

    final bal = _selectedBalance;
    if (bal != null && bal.remainingDays < _calculatedDays) {
      setState(() => _errorMessage =
          'Insufficient balance: You have ${bal.remainingDays} days remaining, but requested $_calculatedDays days.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final result = await ApiService.applyLeave(
      leaveTypeId: _selectedTypeId!,
      startDate: _formatDateIso(_startDate),
      endDate: _formatDateIso(_endDate),
      isHalfDay: _isHalfDay,
      halfDaySession: _isHalfDay ? _halfDaySession : null,
      reason: _reasonController.text.trim(),
      applyingTo: _applyingTo,
      cc: _ccList.isNotEmpty ? _ccList.join(', ') : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        widget.onApplied();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to apply leave';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Apply for Leave',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(color: Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Applying to and CC to
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(
                        TextSpan(
                          text: 'Applying To ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          children: const [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F2FE),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'M',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                'Mathumitha',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CC To',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _showAddCcDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle_outline, size: 16, color: primaryColor),
                            SizedBox(width: 6),
                            Text(
                              'Add',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_ccList.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: _ccList.map((cc) {
                  return Chip(
                    backgroundColor: const Color(0xFFF1F5F9),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Text(cc, style: const TextStyle(fontSize: 11, color: Color(0xFF334155))),
                    deleteIcon: const Icon(Icons.close, size: 14, color: Color(0xFF64748B)),
                    onDeleted: () {
                      setState(() {
                        _ccList.remove(cc);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),

            // Leave Type Dropdown
            const Text(
              'Leave Type',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedTypeId,
              items: widget.leaveTypes.map((t) {
                final bal = widget.balances.firstWhere(
                  (b) => b.leaveTypeId == t.id,
                  orElse: () => EmployeeLeaveBalance(
                    id: '',
                    employeeId: '',
                    leaveTypeId: t.id,
                    leaveTypeName: t.name,
                    leaveTypeCode: t.code,
                    year: 2026,
                    allocatedDays: t.annualAllowance.toDouble(),
                    usedDays: 0,
                    remainingDays: t.annualAllowance.toDouble(),
                  ),
                );
                final rem = bal.remainingDays.truncateToDouble() == bal.remainingDays
                    ? bal.remainingDays.toInt().toString()
                    : bal.remainingDays.toStringAsFixed(1);
                return DropdownMenuItem<String>(
                  value: t.id,
                  child: Text('${t.name} ($rem days left)'),
                );
              }).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedTypeId = val;
                  if (_isCasualLeave) {
                    _endDate = _startDate; // CL max 1 day lock
                  }
                });
              },
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),

            if (_isCasualLeave) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: Color(0xFF2563EB)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Casual Leave: Max 1 day • 1 application per calendar month',
                        style: TextStyle(fontSize: 11, color: Color(0xFF1E40AF), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            if (_isSickLeave && _calculatedDays >= 2.0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.medical_services_outlined, size: 14, color: Color(0xFFD97706)),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Medical certificate document is required for Sick Leave of 2+ days',
                        style: TextStyle(fontSize: 11, color: Color(0xFF92400E), fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Half Day Switch
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Half Day Leave',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF334155)),
                    ),
                    Text(
                      '0.5 day deduction for partial shift',
                      style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Switch(
                  value: _isHalfDay,
                  activeThumbColor: primaryColor,
                  onChanged: (val) {
                    setState(() {
                      _isHalfDay = val;
                      if (val) {
                        _endDate = _startDate;
                      }
                    });
                  },
                ),
              ],
            ),
            if (_isHalfDay) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _halfDaySession = 'FIRST_HALF'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _halfDaySession == 'FIRST_HALF'
                              ? const Color(0xFF0F9D8A).withAlpha(25)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _halfDaySession == 'FIRST_HALF'
                                ? primaryColor
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _halfDaySession == 'FIRST_HALF'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: _halfDaySession == 'FIRST_HALF'
                                  ? primaryColor
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            const Text('Session 1 (AM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _halfDaySession = 'SECOND_HALF'),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: _halfDaySession == 'SECOND_HALF'
                              ? const Color(0xFF0F9D8A).withAlpha(25)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: _halfDaySession == 'SECOND_HALF'
                                ? primaryColor
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _halfDaySession == 'SECOND_HALF'
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 16,
                              color: _halfDaySession == 'SECOND_HALF'
                                  ? primaryColor
                                  : const Color(0xFF64748B),
                            ),
                            const SizedBox(width: 6),
                            const Text('Session 2 (PM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),

            // Date Pickers
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'From Date',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                      ),
                      const SizedBox(height: 6),
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 7)),
                            lastDate: DateTime(2027),
                          );
                          if (picked != null) {
                            setState(() {
                              _startDate = picked;
                              if (_isCasualLeave || _isHalfDay || _endDate.isBefore(picked)) {
                                _endDate = picked;
                              }
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            border: Border.all(color: const Color(0xFFCBD5E1)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month, size: 16, color: primaryColor),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _formatDate(_startDate),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isHalfDay && !_isCasualLeave) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'To Date',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
                              firstDate: _startDate,
                              lastDate: DateTime(2027),
                            );
                            if (picked != null) {
                              setState(() => _endDate = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              border: Border.all(color: const Color(0xFFCBD5E1)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month, size: 16, color: primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _formatDate(_endDate),
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Total duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Duration:', style: TextStyle(fontSize: 13, color: Color(0xFF475569))),
                  Text(
                    '${_calculatedDays.toStringAsFixed(_calculatedDays.truncateToDouble() == _calculatedDays ? 0 : 1)} ${_calculatedDays > 1 ? "Days" : "Day"}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Reason
            const Text(
              'Reason for Leave',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'e.g. Doctor appointment, family function, personal work...',
                hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Attach File
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Attach File',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF334155),
                  ),
                ),
                Text(
                  _attachedFile != null ? '1 file selected' : 'Optional (PDF, JPG, PNG)',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            if (_attachedFile == null)
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor.withAlpha(25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_file_rounded,
                          size: 20,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Supporting Document',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'PDF or Images up to 10 MB',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Browse',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: (_attachedFile!.extension?.toLowerCase() == 'pdf')
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        (_attachedFile!.extension?.toLowerCase() == 'pdf')
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded,
                        size: 20,
                        color: (_attachedFile!.extension?.toLowerCase() == 'pdf')
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF0284C7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _attachedFile!.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_attachedFile!.extension?.toUpperCase() ?? 'FILE'} • ${_formatFileSize(_attachedFileSize)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: _removeFile,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFEF4444)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFB91C1C), fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Submit Leave Request',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

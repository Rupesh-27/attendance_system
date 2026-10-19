import 'package:flutter/material.dart';

import '../services/api_service.dart';

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
        title: const Text(
          'My Leaves',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
        label: const Text('Apply Leave', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : RefreshIndicator(
              onRefresh: refreshData,
              color: primaryColor,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
                children: [
                  _buildBalancesCarousel(),
                  const SizedBox(height: 20),
                  _buildSectionHeader('Application History'),
                  const SizedBox(height: 10),
                  _buildStatusFilterChips(),
                  const SizedBox(height: 14),
                  _buildApplicationsList(),
                ],
              ),
            ),
    );
  }

  // ==================== BALANCES CAROUSEL ====================
  Widget _buildBalancesCarousel() {
    if (_balances.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text(
            'No leave balances found for current year',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Leave Balances (2026)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
            Text(
              '${_balances.length} Types',
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _balances.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final bal = _balances[index];
              return _buildBalanceCard(bal, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceCard(EmployeeLeaveBalance bal, int index) {
    final colors = [
      {'gradStart': const Color(0xFF0F9D8A), 'bg': const Color(0xFFECFDF5)},
      {'gradStart': const Color(0xFF3B82F6), 'bg': const Color(0xFFEFF6FF)},
      {'gradStart': const Color(0xFFF59E0B), 'bg': const Color(0xFFFFFBEB)},
    ];
    final colorScheme = colors[index % colors.length];

    final double progress = bal.allocatedDays > 0
        ? (bal.remainingDays / bal.allocatedDays).clamp(0.0, 1.0)
        : 0.0;

    final remainingText = bal.remainingDays.truncateToDouble() == bal.remainingDays
        ? bal.remainingDays.toInt().toString()
        : bal.remainingDays.toStringAsFixed(1);

    return Container(
      width: 190,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme['bg'],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bal.leaveTypeCode.isNotEmpty ? bal.leaveTypeCode : 'LEAVE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: colorScheme['gradStart'],
                  ),
                ),
              ),
              Icon(Icons.event_available, size: 18, color: colorScheme['gradStart']),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                bal.leaveTypeName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    remainingText,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '/ ${bal.allocatedDays.toInt()} Days',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme['gradStart']!),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E293B),
      ),
    );
  }

  Widget _buildStatusFilterChips() {
    final filters = [
      {'key': 'ALL', 'label': 'All Requests'},
      {'key': 'PENDING', 'label': 'Pending'},
      {'key': 'APPROVED', 'label': 'Approved'},
      {'key': 'REJECTED', 'label': 'Rejected'},
      {'key': 'WITHDRAWN', 'label': 'Withdrawn'},
      {'key': 'CANCELLATION_PENDING', 'label': 'Cancel Requested'},
      {'key': 'CANCELLED', 'label': 'Cancelled'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final isSelected = _selectedStatusFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                f['label']!,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                if (val) {
                  setState(() => _selectedStatusFilter = f['key']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildApplicationsList() {
    final filtered = _myApplications.where((a) {
      if (_selectedStatusFilter == 'ALL') return true;
      return a.status == _selectedStatusFilter;
    }).toList();

    if (filtered.isEmpty) {
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
            const Text(
              'No Leave Requests Found',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedStatusFilter == 'ALL'
                  ? 'Tap "Apply Leave" below to submit your first request'
                  : 'No requests match the selected filter',
              style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: filtered.map((app) => _buildApplicationCard(app)).toList(),
    );
  }

  Widget _buildApplicationCard(LeaveApplication app) {
    final startStr = _formatDate(app.startDate);
    final endStr = _formatDate(app.endDate);
    final dateDisplay = app.startDate.isAtSameMomentAs(app.endDate)
        ? startStr
        : '$startStr - $endStr';

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
              Row(
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
                  Text(
                    app.leaveTypeName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
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
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                dateDisplay,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  app.isHalfDay
                      ? '0.5 Day (${app.halfDaySession == "SECOND_HALF" || app.halfDaySession == "Session 2" ? "Session 2 (PM)" : "Session 1 (AM)"})'
                      : '${app.totalDays.toInt()} ${app.totalDays > 1 ? "Days" : "Day"}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF475569),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          if (app.applyingTo != null && app.applyingTo!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 13, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Applying to: ${app.applyingTo}',
                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
                if (app.cc != null && app.cc!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '• CC: ${app.cc}',
                      style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ],
          if (app.reason.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              app.reason,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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

  bool _isSubmitting = false;
  String? _errorMessage;

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
                      RichText(
                        text: const TextSpan(
                          text: 'Applying to ',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                          children: [
                            TextSpan(
                              text: '*',
                              style: TextStyle(color: Color(0xFFEF4444)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFCBD5E1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0F2FE),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'M',
                                style: TextStyle(
                                  fontSize: 13,
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
                                  fontSize: 13.5,
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
                      'CC to',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: _showAddCcDialog,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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

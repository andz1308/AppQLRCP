import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/staff_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';
import 'staff_verify_ticket_screen.dart';

class StaffHomeScreen extends StatefulWidget {
  final User user;

  const StaffHomeScreen({super.key, required this.user});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  int _currentIndex = 0;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _DashboardScreen(staffId: widget.user.userId),
      StaffVerifyTicketScreen(),
      _ProfileScreen(user: widget.user),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            activeIcon: Icon(Icons.qr_code_scanner),
            label: 'Soát vé',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// Dashboard Screen
class _DashboardScreen extends StatefulWidget {
  final int staffId;

  const _DashboardScreen({required this.staffId});

  @override
  State<_DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<_DashboardScreen> {
  final _staffService = StaffService();
  Map<String, dynamic>? _dashboardData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    final result = await _staffService.getDashboard(widget.staffId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _dashboardData = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thống kê doanh thu'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dashboardData == null
          ? const Center(child: Text('Không thể tải dữ liệu'))
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tổng quan', style: AppTheme.headingMedium),
                    const SizedBox(height: 16),

                    // Stats grid
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.5,
                      children: [
                        _StatCard(
                          title: 'Tổng vé bán',
                          value: _dashboardData!['total_tickets'].toString(),
                          icon: Icons.confirmation_number,
                          color: AppTheme.primaryOrange,
                        ),
                        _StatCard(
                          title: 'Tổng doanh thu',
                          value: '${_dashboardData!['total_revenue']}đ',
                          icon: Icons.attach_money,
                          color: AppTheme.success,
                        ),
                        _StatCard(
                          title: 'Doanh thu tháng',
                          value: '${_dashboardData!['monthly_revenue']}đ',
                          icon: Icons.trending_up,
                          color: AppTheme.info,
                        ),
                        _StatCard(
                          title: 'Đơn tháng này',
                          value: _dashboardData!['monthly_bookings'].toString(),
                          icon: Icons.receipt_long,
                          color: AppTheme.warning,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('Soát vé', style: AppTheme.headingMedium),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'Đã soát',
                            value: _dashboardData!['tickets_verified']
                                .toString(),
                            icon: Icons.check_circle,
                            color: AppTheme.success,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Chưa soát',
                            value: _dashboardData!['tickets_pending']
                                .toString(),
                            icon: Icons.pending,
                            color: AppTheme.warning,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            Text(
              value,
              style: AppTheme.headingSmall.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Screen
class _ProfileScreen extends StatefulWidget {
  final User user;

  const _ProfileScreen({required this.user});

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _staffService = StaffService();
  final _authService = AuthService();
  Map<String, dynamic>? _profileData;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    final result = await _staffService.getStaffProfile(widget.user.userId);

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result['data'] != null) {
          _profileData = result['data'];
        } else {
          _errorMessage = result['message'] ?? 'Không thể tải dữ liệu hồ sơ';
        }
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân - DAV'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadProfile,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Avatar
                Center(
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryOrange,
                    child: Text(
                      (_profileData?['full_name'] ?? widget.user.name)[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  _profileData?['full_name'] ?? widget.user.name,
                  textAlign: TextAlign.center,
                  style: AppTheme.headingMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  _profileData?['email'] ?? widget.user.email,
                  textAlign: TextAlign.center,
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: 32),

                // Info cards
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.email,
                      color: AppTheme.primaryOrange,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(_profileData?['email'] ?? 'N/A'),
                  ),
                ),
                if (_profileData?['phone'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.phone,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Số điện thoại'),
                      subtitle: Text(_profileData!['phone']),
                    ),
                  ),
                if (_profileData?['date_of_birth'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.cake,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Ngày sinh'),
                      subtitle: Text(
                        _formatDate(_profileData?['date_of_birth']),
                      ),
                    ),
                  ),
                if (_profileData?['gender'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.wc,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Giới tính'),
                      subtitle: Text(
                        _profileData!['gender'] == 'M'
                            ? 'Nam'
                            : _profileData!['gender'] == 'F'
                            ? 'Nữ'
                            : _profileData!['gender'],
                      ),
                    ),
                  ),
                if (_profileData?['address'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Địa chỉ'),
                      subtitle: Text(_profileData!['address']),
                    ),
                  ),
                if (_profileData?['role'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.badge,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Chức vụ'),
                      subtitle: Text(_profileData!['role']),
                    ),
                  ),
                if (_profileData?['cinema'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.location_city,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Rạp chiếu'),
                      subtitle: Text(_profileData!['cinema']['name'] ?? 'N/A'),
                    ),
                  ),
                if (_profileData?['join_date'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Ngày vào làm'),
                      subtitle: Text(_formatDate(_profileData?['join_date'])),
                    ),
                  ),
                if (_profileData?['status'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.info,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Trạng thái'),
                      subtitle: Text(_profileData!['status']),
                    ),
                  ),
                const SizedBox(height: 24),

                // Logout button
                ElevatedButton.icon(
                  onPressed: () async {
                    await _authService.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Đăng xuất'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.error,
                  ),
                ),
              ],
            ),
    );
  }
}

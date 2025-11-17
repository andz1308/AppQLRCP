import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/staff_service.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';
import 'staff_booking_screen.dart';
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
      StaffBookingScreen(staffId: widget.user.userId),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_outlined),
            activeIcon: Icon(Icons.point_of_sale),
            label: 'Bán vé',
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
        title: const Text('DAV - Bảng Điều Khiển'),
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
class _ProfileScreen extends StatelessWidget {
  final User user;

  const _ProfileScreen({required this.user});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân - DAV'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryOrange,
              child: Text(
                user.name[0].toUpperCase(),
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
            user.name,
            textAlign: TextAlign.center,
            style: AppTheme.headingMedium,
          ),
          const SizedBox(height: 4),
          Text(
            user.email,
            textAlign: TextAlign.center,
            style: AppTheme.bodyMedium,
          ),
          const SizedBox(height: 32),

          Card(
            child: ListTile(
              leading: const Icon(Icons.email, color: AppTheme.primaryOrange),
              title: const Text('Email'),
              subtitle: Text(user.email),
            ),
          ),
          if (user.phone != null)
            Card(
              child: ListTile(
                leading: const Icon(Icons.phone, color: AppTheme.primaryOrange),
                title: const Text('Số điện thoại'),
                subtitle: Text(user.phone!),
              ),
            ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.badge, color: AppTheme.primaryOrange),
              title: const Text('Vai trò'),
              subtitle: Text(user.role),
            ),
          ),
          const SizedBox(height: 24),

          ElevatedButton.icon(
            onPressed: () async {
              await authService.logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Đăng xuất'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
          ),
        ],
      ),
    );
  }
}

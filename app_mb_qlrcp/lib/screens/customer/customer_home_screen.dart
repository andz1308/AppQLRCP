import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../models/movie.dart';
import '../../services/movie_service.dart';
import '../../services/auth_service.dart';
import '../../services/customer_service.dart';
import '../../utils/app_theme.dart';
import '../login_screen.dart';
import 'movie_detail_screen.dart';
import 'my_tickets_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  final User user;

  const CustomerHomeScreen({super.key, required this.user});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  int _currentIndex = 0;
  final _movieService = MovieService();
  final _authService = AuthService();

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      _MoviesListScreen(movieService: _movieService),
      const MyTicketsScreen(),
      _ProfileScreen(user: widget.user, authService: _authService),
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
            icon: Icon(Icons.movie_outlined),
            activeIcon: Icon(Icons.movie),
            label: 'Phim',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number_outlined),
            activeIcon: Icon(Icons.confirmation_number),
            label: 'Vé của tôi',
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

// Movies List Screen
class _MoviesListScreen extends StatefulWidget {
  final MovieService movieService;

  const _MoviesListScreen({required this.movieService});

  @override
  State<_MoviesListScreen> createState() => _MoviesListScreenState();
}

class _MoviesListScreenState extends State<_MoviesListScreen> {
  List<Movie> _movies = [];
  List<Movie> _filteredMovies = [];
  bool _isLoading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMovies();
    _searchController.addListener(_filterMovies);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMovies() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMovies = _movies;
      } else {
        _filteredMovies = _movies
            .where(
              (movie) =>
                  movie.title.toLowerCase().contains(query) ||
                  (movie.description?.toLowerCase().contains(query) ?? false),
            )
            .toList();
      }
    });
  }

  Future<void> _loadMovies() async {
    setState(() => _isLoading = true);

    final result = await widget.movieService.getMovies();

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true && result.containsKey('movies')) {
          _movies = (result['movies'] as List).cast<Movie>();
          _filteredMovies = _movies;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DAV Cinema'),
        backgroundColor: AppTheme.primaryOrange,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm phim...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterMovies();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
          ),
          // Movies list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _movies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.movie_outlined,
                          size: 80,
                          color: AppTheme.lightGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có phim nào',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : _filteredMovies.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 80,
                          color: AppTheme.lightGray,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy phim',
                          style: AppTheme.bodyLarge.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadMovies,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: _filteredMovies.length,
                      itemBuilder: (context, index) {
                        final movie = _filteredMovies[index];
                        return _MovieCard(
                          movie: movie,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MovieDetailScreen(movie: movie),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

// Movie Card Widget
class _MovieCard extends StatelessWidget {
  final Movie movie;
  final VoidCallback onTap;

  const _MovieCard({required this.movie, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Movie poster
              Container(
                width: 100,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: AppTheme.lightGray,
                  image: movie.image != null
                      ? DecorationImage(
                          image: NetworkImage(movie.image!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: movie.image == null
                    ? const Icon(
                        Icons.movie,
                        size: 40,
                        color: AppTheme.mediumGray,
                      )
                    : null,
              ),
              const SizedBox(width: 12),

              // Movie info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      movie.title,
                      style: AppTheme.headingSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (movie.duration != null)
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 16,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          Text(movie.durationText, style: AppTheme.bodySmall),
                        ],
                      ),
                    if (movie.releaseDate != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: AppTheme.mediumGray,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${movie.releaseDate!.day}/${movie.releaseDate!.month}/${movie.releaseDate!.year}',
                            style: AppTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    if (movie.description != null)
                      Text(
                        movie.description!,
                        style: AppTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Profile Screen
class _ProfileScreen extends StatefulWidget {
  final User user;
  final AuthService authService;

  const _ProfileScreen({required this.user, required this.authService});

  @override
  State<_ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<_ProfileScreen> {
  final _customerService = CustomerService();
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

    final result = await _customerService.getCustomerProfile(
      widget.user.userId,
    );

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

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0 VNĐ';
    try {
      final num value = amount is String ? num.parse(amount) : amount;
      return '${value.toStringAsFixed(0)} VNĐ';
    } catch (e) {
      return '$amount VNĐ';
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

                // Name
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
                if (_profileData?['registration_date'] != null)
                  Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: AppTheme.primaryOrange,
                      ),
                      title: const Text('Ngày đăng ký'),
                      subtitle: Text(
                        _formatDate(_profileData?['registration_date']),
                      ),
                    ),
                  ),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.confirmation_number,
                      color: AppTheme.primaryOrange,
                    ),
                    title: const Text('Tổng vé đã mua'),
                    subtitle: Text(
                      (_profileData?['total_bookings'] ?? 0).toString(),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.attach_money,
                      color: AppTheme.primaryOrange,
                    ),
                    title: const Text('Tổng chi tiêu'),
                    subtitle: Text(
                      _formatCurrency(_profileData?['total_spent'] ?? 0),
                    ),
                  ),
                ),
                Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.badge,
                      color: AppTheme.primaryOrange,
                    ),
                    title: const Text('Vai trò'),
                    subtitle: Text(widget.user.role),
                  ),
                ),
                const SizedBox(height: 24),

                // Logout button
                ElevatedButton.icon(
                  onPressed: () async {
                    await widget.authService.logout();
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

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xangdau_app/widget/gas_station_card.dart';
import '../../services/auth_service.dart';
import '../../services/gas_station_service.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import '../../models/gas_station.dart';

import 'search_screen.dart';
import '../customer/gas_station_detail.dart';
import '../customer/profile_screen.dart';
import '../owner/station_management.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GasStationService _stationService = GasStationService();
  List<GasStation> _stations = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final stations = await _stationService.getAllStations();
      setState(() {
        _stations = stations;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }

  void _navigateToSearch() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SearchScreen()),
    );
  }

  void _navigateToStationDetail(GasStation station) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GasStationDetailScreen(station: station),
      ),
    );
  }

  Future<void> _logout() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.logout();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentIndex == 0 ? 'Trang chủ' : 'Thông tin cá nhân'),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _navigateToSearch,
            ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: _buildBody(authService),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _buildBody(AuthService authService) {
    if (_currentIndex == 0) {
      return _buildHomeTab();
    } else {
      return authService.isOwner
          ? const StationManagementScreen()
          : const ProfileScreen();
    }
  }

  Widget _buildHomeTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadStations,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_stations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.emptyImage,
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 16),
            const Text(
              'Không có cửa hàng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy tìm kiếm theo tên hoặc địa chỉ',
              style: TextStyle(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _navigateToSearch,
              icon: const Icon(Icons.search),
              label: const Text('Tìm kiếm'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        itemCount: _stations.length,
        itemBuilder: (context, index) {
          final station = _stations[index];
          return GasStationCard(
            station: station,
            onTap: () => _navigateToStationDetail(station),
          );
        },
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _logout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }
}
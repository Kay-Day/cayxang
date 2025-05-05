import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:xangdau_app/widget/custom_button.dart';
import '../../services/auth_service.dart';
import '../../services/gas_station_service.dart';
import 'package:xangdau_app/services/config/constants.dart';
import 'package:xangdau_app/services/config/themes.dart';
import '../../models/gas_station.dart';

import 'station_form.dart';
import 'product_management.dart';
import 'order_management.dart';
import 'owner_profile.dart';

class StationManagementScreen extends StatefulWidget {
  const StationManagementScreen({Key? key}) : super(key: key);

  @override
  _StationManagementScreenState createState() => _StationManagementScreenState();
}

class _StationManagementScreenState extends State<StationManagementScreen> {
  final GasStationService _stationService = GasStationService();
  List<GasStation> _stations = [];
  bool _isLoading = true;
  String? _errorMessage;

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
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      
      if (user != null) {
        final stations = await _stationService.getOwnerStations(user.id);
        setState(() {
          _stations = stations;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = AppConstants.generalError;
        _isLoading = false;
      });
    }
  }

  void _navigateToStationForm({GasStation? station}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => StationFormScreen(station: station),
      ),
    ).then((_) => _loadStations());
  }

  void _navigateToProductManagement(GasStation station) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductManagementScreen(station: station),
      ),
    );
  }

  void _navigateToOrderManagement(GasStation station) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderManagementScreen(station: station),
      ),
    );
  }

  void _navigateToOwnerProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const OwnerProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverPersistentHeader(
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    tabs: const [
                      Tab(
                        icon: Icon(Icons.store),
                        text: 'Cửa hàng của tôi',
                      ),
                      Tab(
                        icon: Icon(Icons.person),
                        text: 'Thông tin cá nhân',
                      ),
                    ],
                    indicatorColor: AppColors.primary,
                  ),
                ),
                pinned: true,
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildStationsTab(),
              const OwnerProfileScreen(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToStationForm(),
          child: const Icon(Icons.add),
          tooltip: 'Thêm cửa hàng mới',
        ),
      ),
    );
  }

  Widget _buildStationsTab() {
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
              'Bạn chưa có cửa hàng nào',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Hãy thêm cửa hàng của bạn để bắt đầu',
              style: TextStyle(
                color: AppColors.lightText,
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Thêm cửa hàng',
              onPressed: () => _navigateToStationForm(),
              icon: Icons.add,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _stations.length,
        itemBuilder: (context, index) {
          final station = _stations[index];
          return _buildStationCard(station);
        },
      ),
    );
  }

  Widget _buildStationCard(GasStation station) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              station.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              '${station.address}, ${station.district}, ${station.city}',
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _navigateToStationForm(station: station);
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit),
                    title: Text('Sửa thông tin'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Sản phẩm',
                    onPressed: () => _navigateToProductManagement(station),
                    icon: Icons.local_gas_station,
                    type: ButtonType.outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Đơn hàng',
                    onPressed: () => _navigateToOrderManagement(station),
                    icon: Icons.receipt_long,
                    type: ButtonType.outline,
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

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Colors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
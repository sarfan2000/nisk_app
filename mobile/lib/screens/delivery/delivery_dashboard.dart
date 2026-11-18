import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'rider_kyc_screen.dart';

class DeliveryDashboard extends StatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _availableOrders = [];
  List<dynamic> _myDeliveries = [];
  Map<String, dynamic>? _earningsData;
  bool _isVerified = false;
  String _kycStatus = 'Not Submitted';

  String _userName = 'Rider';

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _fetchDashboardData();
  }

  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _userName = prefs.getString('userName') ?? 'Rider';
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final availableRes = await _apiService.get('/delivery/available-orders');
      final deliveriesRes = await _apiService.get('/delivery/my-deliveries');
      final earningsRes = await _apiService.get('/delivery/earnings');
      final profileRes = await _apiService.get('/delivery/profile/me');

      if (mounted) {
        setState(() {
          _availableOrders = availableRes ?? [];
          _myDeliveries = deliveriesRes ?? [];
          _earningsData = earningsRes;

          if (profileRes != null) {
            final user = profileRes['user'];
            final profile = profileRes['profile'];
            _isVerified = user != null && user['isVerified'] == true;
            _kycStatus = profile != null ? (profile['kycStatus'] ?? 'Pending') : 'Not Submitted';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptOrder(String orderId) async {
    if (!_isVerified) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Text('Verification Required'),
            ],
          ),
          content: Text(
            _kycStatus == 'Pending'
                ? 'Your KYC documents are currently under review by NISK Admin. Once approved, you can accept deliveries.'
                : 'You must submit your National ID and vehicle details for Admin approval before accepting delivery orders.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RiderKycScreen()),
                ).then((_) => _fetchDashboardData());
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
              child: Text(_kycStatus == 'Pending' ? 'View KYC Status' : 'Submit KYC Now'),
            ),
          ],
        ),
      );
      return;
    }

    try {
      await _apiService.patch('/delivery/accept/$orderId', {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order accepted! Customer notified with Delivery OTP.'),
            backgroundColor: Colors.teal,
          ),
        );
      }
      _fetchDashboardData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showOtpCompletionDialog(String orderId, String pName) {
    final otpController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.teal),
                  SizedBox(width: 8),
                  Text('Complete Delivery', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Delivering: $pName', style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  const Text(
                    'Ask the customer for their 4-digit Delivery Security OTP shown in their app:',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                    decoration: InputDecoration(
                      hintText: '••••',
                      counterText: '',
                      filled: true,
                      fillColor: Colors.teal.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.teal.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.teal, width: 2),
                      ),
                    ),
                  ),
                  if (isSubmitting) ...[
                    const SizedBox(height: 12),
                    const Center(child: CircularProgressIndicator(color: Colors.teal)),
                  ]
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting ? null : () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          final otp = otpController.text.trim();
                          if (otp.length != 4) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              const SnackBar(content: Text('Please enter the full 4-digit OTP')),
                            );
                            return;
                          }

                          setDialogState(() => isSubmitting = true);
                          final messenger = ScaffoldMessenger.of(context);
                          final navigator = Navigator.of(dialogCtx);
                          try {
                            await _apiService.post('/delivery/verify-complete/$orderId', {'otp': otp});
                            navigator.pop();
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('Delivery Verified & Completed! Earnings added to your wallet.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            _fetchDashboardData();
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            messenger.showSnackBar(
                              SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Verify & Complete'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _callPhone(String? phone) async {
    if (phone == null || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No phone number available')));
      return;
    }
    final clean = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final Uri url = Uri.parse('tel:$clean');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Cannot call $phone')));
    }
  }

  Future<void> _openMap(String? location) async {
    if (location == null || location.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No location address available')));
      return;
    }
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(location)}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open map')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DELIVERY HUB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text('Rider: $_userName', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
            ],
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderKycScreen()))
                    .then((_) => _fetchDashboardData());
              },
              icon: Icon(
                _isVerified ? Icons.verified : Icons.shield_outlined,
                color: Colors.white,
                size: 16,
              ),
              label: Text(
                _isVerified ? 'VERIFIED' : 'KYC',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchDashboardData,
              tooltip: 'Refresh',
            )
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.inventory_2, size: 20), text: 'AVAILABLE'),
              Tab(icon: Icon(Icons.directions_bike, size: 20), text: 'ACTIVE'),
              Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: 'EARNINGS'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.teal))
            : TabBarView(
                children: [
                  _buildAvailableOrdersView(),
                  _buildMyDeliveriesView(),
                  _buildEarningsView(),
                ],
              ),
      ),
    );
  }

  Widget _buildAvailableOrdersView() {
    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _buildKycWarningBanner(),
          if (_availableOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_outline, size: 70, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text('No Orders Waiting for Delivery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    const Text('Check back soon when sellers pack orders.', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            )
          else
            ..._availableOrders.map((order) {
              final product = order['product'];
              final seller = product != null ? product['seller'] : null;
              final customer = order['customer'];

              final pName = product != null ? product['name'] : 'Product';
              final sellerName = seller != null ? seller['name'] : 'Seller Store';
              final sellerPhone = seller != null ? seller['phone'] : '';
              final sellerLocation = (seller != null && seller['location'] != null)
                  ? (seller['location']['city'] ?? seller['location']['district'] ?? 'Seller Location')
                  : (product != null && product['location'] != null ? product['location'] : 'Seller Location');

              final customerName = customer != null ? customer['name'] : 'Customer';
              final dropoffLocation = order['deliveryLocation'] ?? 'Customer Address';
              final deliveryFee = order['deliveryFee'] ?? 300;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              pName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade300),
                            ),
                            child: Text(
                              'Earn LKR $deliveryFee',
                              style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Pickup info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.store, size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pickup: $sellerName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('$sellerLocation', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                          if (sellerPhone != null && sellerPhone.toString().isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.phone, size: 20, color: Colors.teal),
                              onPressed: () => _callPhone(sellerPhone),
                              tooltip: 'Call Seller',
                            )
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Dropoff info
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Deliver to: $customerName', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                Text('$dropoffLocation', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _acceptOrder(order['orderId']),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Accept Delivery Job', style: TextStyle(fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildKycWarningBanner() {
    if (_isVerified) return const SizedBox.shrink();

    final isPending = _kycStatus == 'Pending';
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPending ? Colors.amber.shade50 : Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isPending ? Colors.amber.shade300 : Colors.red.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(isPending ? Icons.hourglass_top : Icons.warning_amber_rounded, color: isPending ? Colors.amber.shade900 : Colors.red, size: 22),
              const SizedBox(width: 8),
              Text(
                isPending ? 'KYC Verification Pending Review' : 'Verification Required to Deliver',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isPending ? Colors.amber.shade900 : Colors.red.shade900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isPending
                ? 'Your National ID & vehicle details were submitted. Admin review is in progress.'
                : 'Submit your National ID & vehicle details to get approved by Admin and start accepting delivery orders.',
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const RiderKycScreen()))
                  .then((_) => _fetchDashboardData());
            },
            icon: const Icon(Icons.badge, size: 16),
            label: Text(isPending ? 'View KYC Status' : 'Submit KYC Documents'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isPending ? Colors.amber.shade800 : Colors.teal,
              foregroundColor: Colors.white,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyDeliveriesView() {
    if (_myDeliveries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_bike_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Active Deliveries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 6),
            const Text('Accept orders from the "Available" tab to start.', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: ListView.builder(
        padding: const EdgeInsets.all(14),
        itemCount: _myDeliveries.length,
        itemBuilder: (context, index) {
          final order = _myDeliveries[index];
          final product = order['product'];
          final seller = product != null ? product['seller'] : null;
          final customer = order['customer'];

          final pName = product != null ? product['name'] : 'Product';
          final orderId = order['orderId'] ?? '';
          final status = order['orderStatus'] ?? 'Out for Delivery';
          final isDelivered = status == 'Delivered';

          final sellerName = seller != null ? seller['name'] : 'Seller Store';
          final sellerPhone = seller != null ? (seller['phone'] ?? '') : '';
          final sellerLocation = (seller != null && seller['location'] != null)
              ? (seller['location']['city'] ?? seller['location']['district'] ?? 'Seller Location')
              : (product != null && product['location'] != null ? product['location'] : 'Seller Location');

          final customerName = customer != null ? customer['name'] : 'Customer';
          final customerPhone = customer != null ? (customer['phone'] ?? '') : '';
          final dropoffLocation = order['deliveryLocation'] ?? 'Customer Address';
          final fee = order['deliveryFee'] ?? 300;

          return Card(
            elevation: 3,
            margin: const EdgeInsets.only(bottom: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDelivered ? Colors.green.shade50 : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: isDelivered ? Colors.green.shade300 : Colors.amber.shade400),
                        ),
                        child: Text(
                          isDelivered ? 'DELIVERED' : 'OUT FOR DELIVERY',
                          style: TextStyle(
                            color: isDelivered ? Colors.green.shade800 : Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                  Text('Earnings on Delivery: LKR $fee', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13)),
                  const Divider(height: 20),

                  // Pickup box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pickup: $sellerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(sellerLocation, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        if (sellerPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone, size: 20, color: Colors.orange),
                            onPressed: () => _callPhone(sellerPhone),
                            tooltip: 'Call Seller',
                          ),
                        IconButton(
                          icon: const Icon(Icons.directions, size: 20, color: Colors.orange),
                          onPressed: () => _openMap(sellerLocation),
                          tooltip: 'Map to Seller',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Dropoff box
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.person_pin_circle, color: Colors.teal, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dropoff: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              Text(dropoffLocation, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                            ],
                          ),
                        ),
                        if (customerPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone, size: 20, color: Colors.teal),
                            onPressed: () => _callPhone(customerPhone),
                            tooltip: 'Call Customer',
                          ),
                        IconButton(
                          icon: const Icon(Icons.map, size: 20, color: Colors.teal),
                          onPressed: () => _openMap(dropoffLocation),
                          tooltip: 'Map to Customer',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  if (!isDelivered)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showOtpCompletionDialog(orderId, pName),
                        icon: const Icon(Icons.verified),
                        label: const Text('Enter OTP & Complete Delivery', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEarningsView() {
    final data = _earningsData ?? {};
    final totalEarnings = data['totalEarnings'] ?? 0;
    final todayEarnings = data['todayEarnings'] ?? 0;
    final totalDeliveries = data['totalDeliveries'] ?? 0;
    final todayDeliveries = data['todayDeliveries'] ?? 0;
    final activeDeliveries = data['activeDeliveries'] ?? 0;
    final ratePerDelivery = data['ratePerDelivery'] ?? 300;
    final List<dynamic> recent = data['recentDeliveries'] ?? [];

    return RefreshIndicator(
      onRefresh: _fetchDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Big summary card
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: Colors.teal,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Total Earnings to Date', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      'LKR $totalEarnings',
                      style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: Colors.white24),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn("Today", 'LKR $todayEarnings ($todayDeliveries)'),
                        Container(width: 1, height: 35, color: Colors.white24),
                        _buildStatColumn('Total Trips', '$totalDeliveries'),
                        Container(width: 1, height: 35, color: Colors.white24),
                        _buildStatColumn('Active', '$activeDeliveries'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rate and Payout Info Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Earnings Rate: LKR $ratePerDelivery / Delivery', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue)),
                        const SizedBox(height: 2),
                        const Text(
                          'Weekly direct bank payouts are processed by NISK Administration every Friday.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text('Completed Delivery History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (recent.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Text('No completed deliveries yet.', style: TextStyle(color: Colors.grey.shade600)),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recent.length,
                itemBuilder: (context, index) {
                  final trip = recent[index];
                  final pName = trip['product'] != null ? trip['product']['name'] : 'Item';
                  final customerName = trip['customer'] != null ? trip['customer']['name'] : 'Customer';
                  final fee = trip['deliveryFee'] ?? 300;
                  final timeStr = trip['deliveredAt'] != null
                      ? DateTime.parse(trip['deliveredAt']).toLocal().toString().split('.')[0]
                      : 'Completed';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.teal,
                        child: Icon(Icons.check, color: Colors.white, size: 20),
                      ),
                      title: Text(pName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text('To $customerName  •  $timeStr', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      trailing: Text(
                        '+ LKR $fee',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }
}

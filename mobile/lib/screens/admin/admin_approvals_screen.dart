import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AdminApprovalsScreen extends StatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  State<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends State<AdminApprovalsScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _pendingRiders = [];
  List<dynamic> _manpowerBookings = [];

  @override
  void initState() {
    super.initState();
    _fetchAllPending();
  }

  Future<void> _fetchAllPending() async {
    setState(() => _isLoading = true);
    try {
      final ridersRes = await _apiService.get('/admin/delivery/pending-kyc');
      final mpResponse = await _apiService.get('/admin/manpower-bookings/pending');

      if (mounted) {
        setState(() {
          _pendingRiders = ridersRes ?? [];
          _manpowerBookings = mpResponse ?? [];
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load pending approvals: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _decideRiderKyc(String profileId, String decision, {String reason = ''}) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.patch('/admin/delivery/kyc-decision/$profileId', {
        'decision': decision,
        'rejectionReason': reason,
      });

      messenger.showSnackBar(SnackBar(
        content: Text(decision == 'Approved' ? 'Rider Approved & Activated!' : 'Rider KYC Rejected'),
        backgroundColor: decision == 'Approved' ? Colors.green : Colors.red,
      ));

      _fetchAllPending();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  void _promptRejectRider(String profileId, String riderName) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reject KYC: $riderName'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'Reason for Rejection',
            hintText: 'e.g. NIC photo is blurry / Invalid vehicle number',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final r = reasonController.text.trim();
              Navigator.pop(ctx);
              _decideRiderKyc(profileId, 'Rejected', reason: r);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Reject KYC'),
          ),
        ],
      ),
    );
  }

  void _showDocumentPhoto(String? photoPath, String title) {
    if (photoPath == null || photoPath.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No document photo on file')));
      return;
    }

    final imageUrl = photoPath.startsWith('http')
        ? photoPath
        : '${ApiService.baseUrl.replaceAll('/api', '')}/$photoPath';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(title, style: const TextStyle(fontSize: 16)),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))
              ],
            ),
            InteractiveViewer(
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Document could not be loaded'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approveManpowerBooking(String id) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _apiService.patch('/admin/manpower-bookings/$id/approve', {});
      messenger.showSnackBar(const SnackBar(
        content: Text('Payment Approved! Worker Notified.'),
        backgroundColor: Colors.green,
      ));
      _fetchAllPending();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Pending Approvals (Admin)'),
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _fetchAllPending)
          ],
          bottom: TabBar(
            indicatorColor: Colors.teal,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            tabs: [
              Tab(
                icon: const Icon(Icons.directions_bike),
                text: 'RIDERS KYC (${_pendingRiders.length})',
              ),
              Tab(
                icon: const Icon(Icons.handyman),
                text: 'MANPOWER (${_manpowerBookings.length})',
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                children: [
                  _buildRidersKycView(),
                  _buildManpowerView(),
                ],
              ),
      ),
    );
  }

  Widget _buildRidersKycView() {
    if (_pendingRiders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Pending Rider KYC Submissions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 4),
            const Text('All delivery riders are verified and up to date.', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _pendingRiders.length,
      itemBuilder: (context, index) {
        final profile = _pendingRiders[index];
        final user = profile['user'];
        final riderName = user != null ? user['name'] : 'Rider';
        final riderPhone = user != null ? (user['phone'] ?? 'No Phone') : 'No Phone';
        final nicNumber = profile['nicNumber'] ?? 'N/A';
        final vehicleType = profile['vehicleType'] ?? 'Motorbike';
        final vehicleNumber = profile['vehicleNumber'] ?? 'N/A';
        final bank = profile['bankDetails'] ?? {};
        final nicPhoto = profile['nicPhoto'];

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
                    Expanded(
                      child: Text(riderName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: Colors.amber.shade100, borderRadius: BorderRadius.circular(6)),
                      child: Text('PENDING KYC', style: TextStyle(color: Colors.amber.shade900, fontWeight: FontWeight.bold, fontSize: 10)),
                    ),
                  ],
                ),
                Text('Phone: $riderPhone', style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                const Divider(height: 18),

                // Vehicle & NIC details
                Row(
                  children: [
                    const Icon(Icons.two_wheeler, size: 18, color: Colors.teal),
                    const SizedBox(width: 6),
                    Text('$vehicleType: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(vehicleNumber, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.badge, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text('NIC: ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text(nicNumber, style: const TextStyle(fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 10),

                // Bank details box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bank Account for Payouts:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
                      const SizedBox(height: 2),
                      Text('${bank['bankName'] ?? 'Bank'} (${bank['branch'] ?? 'Main'})', style: const TextStyle(fontSize: 12)),
                      Text('Acc: ${bank['accountNumber'] ?? 'N/A'}  •  Holder: ${bank['accountHolderName'] ?? 'N/A'}', style: TextStyle(fontSize: 11, color: Colors.grey.shade800)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Document photo preview button
                if (nicPhoto != null && nicPhoto.toString().isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => _showDocumentPhoto(nicPhoto, 'NIC / License: $riderName'),
                    icon: const Icon(Icons.image, size: 18, color: Colors.teal),
                    label: const Text('View Uploaded NIC / License Photo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.teal,
                      side: const BorderSide(color: Colors.teal),
                    ),
                  ),
                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _promptRejectRider(profile['_id'], riderName),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text('Reject KYC'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _decideRiderKyc(profile['_id'], 'Approved'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        child: const Text('Approve & Activate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildManpowerView() {
    if (_manpowerBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.handyman, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('No Pending Manpower Bookings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _manpowerBookings.length,
      itemBuilder: (context, index) {
        final b = _manpowerBookings[index];
        final customerName = b['customer'] != null ? b['customer']['name'] : 'Unknown Customer';
        final workerName = b['worker'] != null ? b['worker']['name'] : 'Unknown Worker';
        final rate = b['rate'] ?? 0;

        return Card(
          elevation: 3,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.handyman, color: Colors.white)),
            title: Text('Booking ID: ${b['orderId']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Employer: $customerName'),
                Text('Worker: $workerName'),
                Text('Service: ${b['jobCategory']} (LKR $rate)'),
              ],
            ),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () => _approveManpowerBooking(b['_id']),
              child: const Text('APPROVE PAYMENT'),
            ),
          ),
        );
      },
    );
  }
}

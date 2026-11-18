import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/api_service.dart';

class RiderKycScreen extends StatefulWidget {
  const RiderKycScreen({super.key});

  @override
  State<RiderKycScreen> createState() => _RiderKycScreenState();
}

class _RiderKycScreenState extends State<RiderKycScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _nicController = TextEditingController();
  final _licenseController = TextEditingController();
  final _vehicleNumberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _branchController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderNameController = TextEditingController();

  String _selectedVehicleType = 'Motorbike';
  final List<String> _vehicleTypes = ['Motorbike', 'Three-Wheeler', 'Car/Van', 'Bicycle'];

  XFile? _selectedNicPhoto;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingProfile;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _fetchKycProfile();
  }

  @override
  void dispose() {
    _nicController.dispose();
    _licenseController.dispose();
    _vehicleNumberController.dispose();
    _bankNameController.dispose();
    _branchController.dispose();
    _accountNumberController.dispose();
    _holderNameController.dispose();
    super.dispose();
  }

  Future<void> _fetchKycProfile() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.get('/delivery/profile/me');
      if (res != null && mounted) {
        final user = res['user'];
        final profile = res['profile'];

        setState(() {
          _isVerified = user != null && user['isVerified'] == true;
          _existingProfile = profile;

          if (profile != null) {
            _nicController.text = profile['nicNumber'] ?? '';
            _licenseController.text = profile['drivingLicenseNumber'] ?? '';
            _vehicleNumberController.text = profile['vehicleNumber'] ?? '';
            _selectedVehicleType = profile['vehicleType'] ?? 'Motorbike';

            final bank = profile['bankDetails'];
            if (bank != null) {
              _bankNameController.text = bank['bankName'] ?? '';
              _branchController.text = bank['branch'] ?? '';
              _accountNumberController.text = bank['accountNumber'] ?? '';
              _holderNameController.text = bank['accountHolderName'] ?? '';
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load profile: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickNicPhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (photo != null) {
        setState(() {
          _selectedNicPhoto = photo;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
    }
  }

  Future<void> _submitKyc() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedNicPhoto == null && (_existingProfile == null || _existingProfile!['nicPhoto'] == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a clear photo of your NIC or Driving License')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final fields = {
        'nicNumber': _nicController.text.trim(),
        'drivingLicenseNumber': _licenseController.text.trim(),
        'vehicleType': _selectedVehicleType,
        'vehicleNumber': _vehicleNumberController.text.trim().toUpperCase(),
        'bankName': _bankNameController.text.trim(),
        'branch': _branchController.text.trim().isEmpty ? 'Main' : _branchController.text.trim(),
        'accountNumber': _accountNumberController.text.trim(),
        'accountHolderName': _holderNameController.text.trim(),
      };

      final List<XFile> files = [];
      if (_selectedNicPhoto != null) {
        files.add(_selectedNicPhoto!);
      }

      await _apiService.postMultipart('/delivery/profile/kyc', fields, files);

      messenger.showSnackBar(
        const SnackBar(
          content: Text('KYC documents submitted! NISK Admin will review and verify your account.'),
          backgroundColor: Colors.green,
        ),
      );

      _fetchKycProfile();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Failed to submit KYC: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycStatus = _existingProfile != null ? (_existingProfile!['kycStatus'] ?? 'Pending') : 'Not Submitted';
    final rejectionReason = _existingProfile != null ? (_existingProfile!['rejectionReason'] ?? '') : '';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('RIDER KYC VERIFICATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatusBanner(kycStatus, rejectionReason),
                    const SizedBox(height: 16),
                    _buildIdentitySection(),
                    const SizedBox(height: 16),
                    _buildVehicleSection(),
                    const SizedBox(height: 16),
                    _buildBankSection(),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: (_isSubmitting || (_isVerified && kycStatus == 'Approved')) ? null : _submitKyc,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _existingProfile != null ? 'UPDATE KYC DOCUMENTS' : 'SUBMIT KYC FOR APPROVAL',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatusBanner(String status, String reason) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    if (_isVerified && status == 'Approved') {
      bgColor = Colors.green.shade50;
      borderColor = Colors.green.shade300;
      textColor = Colors.green.shade900;
      icon = Icons.verified;
      title = 'Account Verified & Active';
      subtitle = 'You are an approved NISK Delivery Rider. You can accept and deliver customer packages.';
    } else if (status == 'Pending') {
      bgColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade300;
      textColor = Colors.amber.shade900;
      icon = Icons.hourglass_top;
      title = 'KYC Submitted — Under Admin Review';
      subtitle = 'Your documents have been submitted to NISK Administration. Verification usually takes a few hours.';
    } else if (status == 'Rejected') {
      bgColor = Colors.red.shade50;
      borderColor = Colors.red.shade300;
      textColor = Colors.red.shade900;
      icon = Icons.cancel;
      title = 'Verification Rejected';
      subtitle = reason.isNotEmpty ? 'Reason: $reason. Please correct and re-submit.' : 'Please re-upload clear photos and correct details.';
    } else {
      bgColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      textColor = Colors.blue.shade900;
      icon = Icons.info_outline;
      title = 'Verification Required';
      subtitle = 'Please upload your NIC/License, vehicle number, and bank account for weekly payouts.';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: textColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdentitySection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.badge, color: Colors.teal),
                SizedBox(width: 8),
                Text('1. Identity Verification', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              controller: _nicController,
              decoration: const InputDecoration(
                labelText: 'National ID (NIC) Number *',
                hintText: 'e.g. 199512345678 or 951234567V',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.credit_card),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'NIC number is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _licenseController,
              decoration: const InputDecoration(
                labelText: 'Driving License Number (Optional)',
                hintText: 'e.g. B1234567',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.drive_eta),
              ),
            ),
            const SizedBox(height: 14),
            const Text('Photo of NIC or Driving License *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickNicPhoto,
              child: Container(
                width: double.infinity,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
                ),
                child: _selectedNicPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: kIsWeb
                            ? Image.network(_selectedNicPhoto!.path, fit: BoxFit.cover, width: double.infinity)
                            : Image.file(File(_selectedNicPhoto!.path), fit: BoxFit.cover, width: double.infinity),
                      )
                    : (_existingProfile != null && _existingProfile!['nicPhoto'] != null && _existingProfile!['nicPhoto'].toString().isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              _existingProfile!['nicPhoto'].toString().startsWith('http')
                                  ? _existingProfile!['nicPhoto']
                                  : '${ApiService.baseUrl.replaceAll('/api', '')}/${_existingProfile!['nicPhoto']}',
                              fit: BoxFit.cover,
                              width: double.infinity,
                              errorBuilder: (_, __, ___) => const Center(child: Text('Document on file')),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.add_a_photo, size: 38, color: Colors.teal),
                              SizedBox(height: 8),
                              Text('Tap to Take/Upload Document Photo', style: TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                              Text('PNG, JPG up to 10MB', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVehicleSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.two_wheeler, color: Colors.teal),
                SizedBox(width: 8),
                Text('2. Vehicle Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            DropdownButtonFormField<String>(
              value: _selectedVehicleType,
              decoration: const InputDecoration(
                labelText: 'Vehicle Type *',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.commute),
              ),
              items: _vehicleTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedVehicleType = val);
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _vehicleNumberController,
              decoration: const InputDecoration(
                labelText: 'Vehicle Plate Number *',
                hintText: 'e.g. WP BBD-1234 or CP ABC-5678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Vehicle number is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.account_balance, color: Colors.teal),
                SizedBox(width: 8),
                Text('3. Bank Account for Weekly Payouts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const Divider(height: 20),
            TextFormField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: 'Bank Name *',
                hintText: 'e.g. Commercial Bank, BOC, People\'s Bank',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.account_balance),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Bank name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _branchController,
              decoration: const InputDecoration(
                labelText: 'Branch Name',
                hintText: 'e.g. Colombo Fort or Kandy City',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _accountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Account Number *',
                hintText: 'e.g. 100012345678',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Account number is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _holderNameController,
              decoration: const InputDecoration(
                labelText: 'Account Holder Name *',
                hintText: 'As shown in your bank passbook',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Account holder name is required' : null,
            ),
          ],
        ),
      ),
    );
  }
}

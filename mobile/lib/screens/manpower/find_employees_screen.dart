import 'package:flutter/material.dart';
import 'package:nisk_app/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class FindEmployeesScreen extends StatefulWidget {
  const FindEmployeesScreen({super.key});

  @override
  State<FindEmployeesScreen> createState() => _FindEmployeesScreenState();
}

class _FindEmployeesScreenState extends State<FindEmployeesScreen> {
  int _currentStep = 0;

  String? _selectedCategory;
  String? _selectedLocation;
  Map<String, dynamic>? _selectedEmployee;
  int _numberOfDays = 1;

  List<String> _categories = [];
  List<String> _locations = [];
  List<dynamic> _employees = [];
  bool _isLoading = false;

  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _fetchFilters();
  }

  Future<void> _fetchFilters() async {
    try {
      String query = '';
      if (_selectedCategory != null) query += '?category=${Uri.encodeComponent(_selectedCategory!)}';
      
      final data = await _apiService.get('/manpower/jobs/filters$query');
      if (mounted) {
        setState(() {
          _categories = List<String>.from(data['categories'] ?? []);
          _locations = List<String>.from(data['locations'] ?? []);
          
          if (_selectedCategory != null && !_categories.contains(_selectedCategory)) _selectedCategory = null;
          if (_selectedLocation != null && !_locations.contains(_selectedLocation)) _selectedLocation = null;
        });
      }
    } catch (e) {
      debugPrint('Error fetching filters: $e');
    }
  }

  Future<void> _fetchFilteredEmployees() async {
    setState(() => _isLoading = true);
    try {
      String query = '';
      if (_selectedCategory != null) query += '?category=${Uri.encodeComponent(_selectedCategory!)}';
      if (_selectedLocation != null && _selectedLocation!.isNotEmpty) query += '${query.isEmpty ? '?' : '&'}district=${Uri.encodeComponent(_selectedLocation!)}';
      
      final data = await _apiService.get('/manpower/jobs$query');
      if (mounted) {
        setState(() {
          _employees = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load employees: $e')));
      }
    }
  }

  void _showCheckoutDialog() {
    double rate = 2000.0;
    if (_selectedEmployee != null && _selectedEmployee!['salary'] != null) {
      // attempt to parse the rate. E.g "2000" or "LKR 2000"
      final s = _selectedEmployee!['salary'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      if (s.isNotEmpty) rate = double.tryParse(s) ?? 2000.0;
    }
    String empName = _selectedEmployee != null ? (_selectedEmployee!['company'] ?? 'Professional') : 'Unknown';
    
    double subtotal = rate * _numberOfDays;
    double serviceCharge = subtotal * 0.10;
    double grandTotal = subtotal + serviceCharge;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY', style: TextStyle(color: Colors.orange)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: $_selectedCategory'),
            Text('Location: $_selectedLocation'),
            Text('Professional: $empName'),
            const Divider(),
            Text('Days: $_numberOfDays'),
            Text('Rate: LKR $rate'),
            Text('Subtotal: LKR $subtotal'),
            Text('Service Charge (10%): LKR $serviceCharge'),
            const Divider(),
            Text('Total Amount: LKR $grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               _processPayment();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            child: const Text('PROCEED TO PAYMENT'),
          )
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedEmployee == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text('Generating Secure Payment...')
          ],
        ),
      ),
    );

    try {
      final rate = double.tryParse(_selectedEmployee!['salary']?.toString() ?? '1000') ?? 1000.0;
      final subtotal = rate * _numberOfDays;
      final serviceCharge = subtotal * 0.05;
      final total = subtotal + serviceCharge;

      final response = await _apiService.post('/manpower/book', {
        'workerId': _selectedEmployee!['employer'] != null 
             ? (_selectedEmployee!['employer']['_id'] ?? _selectedEmployee!['_id']) 
             : _selectedEmployee!['_id'],
        'jobCategory': _selectedCategory,
        'duration': _numberOfDays,
        'rate': rate,
        'serviceCharge': serviceCharge,
        'total': total
      });

      if (mounted) Navigator.pop(context); // Close loader

      if (response != null && response['paymentUrl'] != null) {
         final String paymentUrl = '${ApiService.baseUrl.replaceAll('/api', '')}${response['paymentUrl']}';
         final Uri url = Uri.parse(paymentUrl);
         
         if (await canLaunchUrl(url)) {
           await launchUrl(url, mode: LaunchMode.inAppWebView);
         } else {
           if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not launch payment portal')));
         }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Booking failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Workers'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedCategory == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Service Category')));
            return;
          }
          if (_currentStep == 1 && (_selectedLocation == null || _selectedLocation!.isEmpty)) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Location')));
            return;
          }
          if (_currentStep == 1) {
             _fetchFilteredEmployees();
          }
          if (_currentStep == 2 && _selectedEmployee == null) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a Professional!')));
            return;
          }
          if (_currentStep < 3) {
            setState(() => _currentStep += 1);
          } else {
            _showCheckoutDialog();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep -= 1);
          }
        },
        steps: [
          Step(
            title: const Text('Service Category'),
            content: DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val;
                  _selectedLocation = null;
                });
                _fetchFilters();
              },
              decoration: const InputDecoration(labelText: 'Select Service (e.g. Plumber)', border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Location'),
            content: DropdownButtonFormField<String>(
              value: _selectedLocation,
              items: _locations.map((loc) => DropdownMenuItem(value: loc, child: Text(loc))).toList(),
              onChanged: (val) {
                setState(() {
                  _selectedLocation = val;
                });
              },
              decoration: const InputDecoration(labelText: 'Select City/Area', border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Select Worker'),
            content: _isLoading 
                ? const Center(child: CircularProgressIndicator()) 
                 : _employees.isEmpty 
                    ? const Text('No workers found for your criteria.')
                    : Column(
                        children: _employees.map((e) {
                          final name = e['company'] ?? 'Independent';
                          final rate = e['salary'] ?? 'Negotiable';
                          final isAvailable = e['isAvailable'] ?? true;
                          
                          String? imageUrl;
                          if (e['jobPicture'] != null && e['jobPicture'].toString().isNotEmpty) {
                            String rawPath = e['jobPicture'].toString();
                            rawPath = rawPath.replaceAll('\\', '/');
                            String base = ApiService.baseUrl.replaceAll(RegExp(r'/api$'), '');
                            if (!rawPath.startsWith('/')) rawPath = '/$rawPath';
                            imageUrl = '$base$rawPath';
                          }

                          return Card(
                            color: (_selectedEmployee != null && _selectedEmployee!['_id'] == e['_id']) ? Colors.orange.shade50 : Colors.white,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: !isAvailable
                                    ? Colors.grey.shade300
                                    : (_selectedEmployee != null && _selectedEmployee!['_id'] == e['_id']) 
                                        ? Colors.orange 
                                        : Colors.grey.shade300,
                                width: (_selectedEmployee != null && _selectedEmployee!['_id'] == e['_id']) ? 2 : 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              enabled: isAvailable,
                              leading: Container(
                                width: 50, height: 50,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: Colors.grey.shade200,
                                ),
                                child: imageUrl != null 
                                  ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover))
                                  : const Icon(Icons.person, color: Colors.grey),
                              ),
                              title: Row(
                                children: [
                                  Text(name, style: TextStyle(fontWeight: FontWeight.bold, color: isAvailable ? Colors.black : Colors.grey)),
                                  if (e['isVerified'] == true) ...[
                                    const SizedBox(width: 4),
                                    const Icon(Icons.verified, color: Colors.blue, size: 16)
                                  ],
                                  if (!isAvailable) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(4)),
                                      child: const Text('UNAVAILABLE', style: TextStyle(fontSize: 10, color: Colors.red, fontWeight: FontWeight.bold)),
                                    )
                                  ]
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text('${e['category']} • Rate: $rate\nLocation: ${e['location'] != null ? e['location']['city'] : 'Unknown'}',
                                    style: TextStyle(color: isAvailable ? Colors.black87 : Colors.grey),
                                  ),
                                ],
                              ),
                              onTap: isAvailable ? () {
                                setState(() => _selectedEmployee = e);
                              } : null,
                            ),
                          );
                        }).toList(),
                      ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Booking Details'),
            content:Row(
              children: [
                const Text('Number of Days/Units: ', style: TextStyle(fontSize: 16)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.remove, color: Colors.orange), onPressed: () => setState(() { if(_numberOfDays>1) _numberOfDays--;})),
                Text('$_numberOfDays', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add, color: Colors.orange), onPressed: () => setState(() => _numberOfDays++)),
              ],
            ),
            isActive: _currentStep >= 3,
          )
        ],
      ),
    );
  }
}

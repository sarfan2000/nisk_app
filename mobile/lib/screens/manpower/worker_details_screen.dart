import 'package:flutter/material.dart';
import 'package:nisk_app/screens/manpower/manpower_checkout_screen.dart';

class WorkerDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> worker;
  final String? imageUrl;
  final String? selectedCategory;
  final String? selectedLocation;

  const WorkerDetailsScreen({
    super.key,
    required this.worker,
    this.imageUrl,
    this.selectedCategory,
    this.selectedLocation,
  });

  @override
  State<WorkerDetailsScreen> createState() => _WorkerDetailsScreenState();
}

class _WorkerDetailsScreenState extends State<WorkerDetailsScreen> {
  int _numberOfDays = 1;

  void _proceedToCheckout() {
    double rate = 2000.0;
    if (widget.worker['salary'] != null) {
      final s = widget.worker['salary'].toString().replaceAll(RegExp(r'[^0-9.]'), '');
      if (s.isNotEmpty) rate = double.tryParse(s) ?? 2000.0;
    }
    String empName = widget.worker['company'] ?? 'Professional';
    
    double subtotal = rate * _numberOfDays;
    double serviceCharge = subtotal * 0.10;
    double grandTotal = subtotal + serviceCharge;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY', style: TextStyle(color: Color(0xFFF1C40F))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Service: ${widget.worker['category'] ?? "General"}'),
            Text('Location: ${widget.worker['location']?['city'] ?? "Unknown"}'),
            Text('Professional: $empName'),
            const Divider(),
            Text('Days/Units: $_numberOfDays'),
            Text('Rate: LKR $rate'),
            Text('Subtotal: LKR $subtotal'),
            Text('Service Charge (10%): LKR $serviceCharge'),
            const Divider(),
            Text('Total Amount: LKR $grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
             onPressed: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (context) => ManpowerCheckoutScreen(
                  bookingDetails: {
                    'category': widget.worker['category'],
                    'location': widget.worker['location']?['city'],
                    'professional': empName,
                    'workerId': widget.worker['employer'] != null 
                              ? (widget.worker['employer']['_id'] ?? widget.worker['_id']) 
                              : widget.worker['_id'],
                    'days': _numberOfDays,
                    'rate': rate,
                    'subtotal': subtotal,
                    'serviceCharge': serviceCharge,
                    'total': grandTotal
                  }
                )));
             },
             style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF1C40F), foregroundColor: Colors.white),
             child: const Text('PROCEED TO PAYMENT'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.worker;
    final name = w['company'] ?? 'Independent';
    final title = w['title'] ?? 'Professional Service';
    final rate = w['salary'] ?? 'Negotiable';
    final location = w['location'] != null ? '${w['location']['city'] ?? ''}, ${w['location']['district'] ?? ''}'.trim() : 'Location Unknown';
    final isAvailable = w['isAvailable'] ?? true;
    final description = w['description'] ?? 'An experienced professional ready to handle your requirements effectively and securely.';
    final skillsArray = (w['requiredSkills'] as List?)?.join(', ') ?? 'Various Skills';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Worker Profile'),
        backgroundColor: const Color(0xFFF1C40F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              color: const Color(0xFFF1C40F).withValues(alpha: 0.1),
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  Hero(
                    tag: 'worker_${w['_id']}',
                    child: Container(
                      width: 120, height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        image: widget.imageUrl != null ? DecorationImage(image: NetworkImage(widget.imageUrl!), fit: BoxFit.cover) : null,
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]
                      ),
                      child: widget.imageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      if (w['isVerified'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blue),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(title, style: TextStyle(color: Colors.grey.shade800, fontSize: 16, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAvailable ? Colors.green.shade100 : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Text(
                      isAvailable ? 'AVAILABLE NOW' : 'CURRENTLY UNAVAILABLE',
                      style: TextStyle(color: isAvailable ? Colors.green.shade800 : Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  )
                ],
              ),
            ),
            
            Padding(
               padding: const EdgeInsets.all(20.0),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    const Text('Service Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text(description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),
                    _buildInfoRow(Icons.location_on, 'Base Location', location),
                    _buildInfoRow(Icons.schedule, 'Job Type', w['jobType'] ?? 'Full Time'),
                    _buildInfoRow(Icons.work, 'Experience Level', w['experienceLevel'] ?? 'Experienced'),
                    _buildInfoRow(Icons.category, 'Category', w['category'] ?? 'General Labor'),
                    const SizedBox(height: 16),
                    const Text('Skills & Expertise', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8, runSpacing: 8,
                      children: skillsArray.split(',').map((skill) {
                        return Chip(label: Text(skill.trim()), backgroundColor: const Color(0xFFF1C40F).withValues(alpha: 0.1));
                      }).toList(),
                    )
                 ],
               ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -5))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rate, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Text('Days / Units:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    InkWell(
                      onTap: () { if(_numberOfDays>1) setState(() => _numberOfDays--); },
                      child: const Icon(Icons.remove_circle, color: Color(0xFFF1C40F)),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('$_numberOfDays', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    InkWell(
                      onTap: () { setState(() => _numberOfDays++); },
                      child: const Icon(Icons.add_circle, color: Color(0xFFF1C40F)),
                    ),
                  ],
                )
              ],
            ),
            ElevatedButton(
              onPressed: isAvailable ? _proceedToCheckout : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1C40F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: const Text('HIRE NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFFF1C40F), size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(data, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          )
        ],
      ),
    );
  }
}


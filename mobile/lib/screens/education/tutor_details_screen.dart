import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/checkout_screen.dart';

class TutorDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> teacher;
  final String? imageUrl;
  final String? selectedMode; // Passed from filters
  final String? selectedGrade; // Passed from filters
  final String? selectedSubject; // Passed from filters

  const TutorDetailsScreen({
    super.key, 
    required this.teacher, 
    this.imageUrl,
    this.selectedMode,
    this.selectedGrade,
    this.selectedSubject,
  });

  @override
  State<TutorDetailsScreen> createState() => _TutorDetailsScreenState();
}

class _TutorDetailsScreenState extends State<TutorDetailsScreen> {
  int _numberOfClasses = 1;
  String _activeTab = 'About'; // About, Info

  String? _mode;
  String? _grade;
  String? _subject;

  @override
  void initState() {
    super.initState();
    final t = widget.teacher;
    _mode = widget.selectedMode ?? ((t['modes'] as List?)?.isNotEmpty == true ? t['modes'][0] : 'Online');
    _grade = widget.selectedGrade ?? ((t['grades'] as List?)?.isNotEmpty == true ? t['grades'][0] : 'Grade 10');
    _subject = widget.selectedSubject ?? ((t['subjects'] as List?)?.isNotEmpty == true ? t['subjects'][0] : 'General');
  }

  void _proceedToCheckout() {
    double rate = widget.teacher['hourlyRate'] != null 
       ? double.tryParse(widget.teacher['hourlyRate'].toString()) ?? 1500.0 
       : 1500.0;
    String teacherName = widget.teacher['user']?['name'] ?? 'Unknown Tutor';
       
    double subtotal = rate * _numberOfClasses;
    double serviceCharge = subtotal * 0.10; // 10% platform fee
    double grandTotal = subtotal + serviceCharge;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking for: $teacherName'),
            const Divider(),
            if (_subject != null) Text('Subject: $_subject'),
            if (_grade != null) Text('Grade: $_grade'),
            Text('Mode: ${_mode ?? "Online"}'),
            const SizedBox(height: 10),
            Text('Classes: $_numberOfClasses'),
            Text('Rate: LKR $rate / hr'),
            Text('Subtotal: LKR $subtotal'),
            Text('Service Charge (10%): LKR $serviceCharge'),
            const Divider(),
            Text('Total Amount: LKR $grandTotal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context); // Close summary
               Navigator.push(context, MaterialPageRoute(builder: (context) => EducationCheckoutScreen(
                 bookingDetails: {
                   'mode': _mode ?? 'Online',
                   'grade': _grade ?? 'Not Specified',
                   'subject': _subject ?? 'General',
                   'teacher': teacherName,
                   'teacherId': widget.teacher['user']?['_id'] ?? widget.teacher['_id'],
                   'classes': _numberOfClasses,
                   'rate': rate,
                   'subtotal': subtotal,
                   'serviceCharge': serviceCharge,
                   'total': grandTotal
                 }
               )));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('PROCEED TO PAYMENT'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.teacher;
    final name = t['user']?['name'] ?? 'Professional Tutor';
    final rate = t['hourlyRate'] ?? 1000;
    final shortDesc = t['shortDescription'] ?? 'An experienced and dedicated teacher ready to help you excel in your studies.';
    final qualifications = (t['qualifications'] as List?)?.join(', ') ?? 'Qualifications not provided';
    final subjectsArray = (t['subjects'] as List?)?.join(', ') ?? 'Multiple subjects';
    final location = t['location'] ?? 'Online';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Tutor Profile'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Section
            Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              child: Column(
                children: [
                  Hero(
                    tag: 'tutor_${t['_id']}',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.white,
                      backgroundImage: widget.imageUrl != null ? NetworkImage(widget.imageUrl!) : null,
                      child: widget.imageUrl == null ? const Icon(Icons.person, size: 60, color: Colors.grey) : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      if (t['isVerified'] == true) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.verified, color: Colors.blue),
                      ]
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Level: ${t['experience'] ?? 'Experienced'}', style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(' ${t['rating'] ?? 5.0}  •  ', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('${t['numberOfStudents'] ?? 0} Students', style: TextStyle(color: Colors.grey.shade600)),
                    ],
                  )
                ],
              ),
            ),
            
            // Booking Selections
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Booking Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdown('Mode', _mode ?? 'Online', (t['modes'] as List?)?.map((e) => e.toString()).toList() ?? ['Online', 'Offline'], (val) => setState(() => _mode = val)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown('Grade', _grade ?? 'Grade 10', (t['grades'] as List?)?.map((e) => e.toString()).toList() ?? ['Grade 10'], (val) => setState(() => _grade = val)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown('Subject', _subject ?? 'Mathematics', (t['subjects'] as List?)?.map((e) => e.toString()).toList() ?? ['Mathematics'], (val) => setState(() => _subject = val)),
                ],
              ),
            ),

            // Tab Controls
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'About'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeTab == 'About' ? Colors.redAccent : Colors.transparent, width: 3))
                      ),
                      child: Center(child: Text('About', style: TextStyle(fontWeight: FontWeight.bold, color: _activeTab == 'About' ? Colors.redAccent : Colors.grey))),
                    ),
                  )
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 'Info'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: _activeTab == 'Info' ? Colors.redAccent : Colors.transparent, width: 3))
                      ),
                      child: Center(child: Text('Information', style: TextStyle(fontWeight: FontWeight.bold, color: _activeTab == 'Info' ? Colors.redAccent : Colors.grey))),
                    ),
                  )
                ),
              ],
            ),
            
            // Content Sections
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: _activeTab == 'About' 
               ? Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     const Text('About the Tutor', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     Text(shortDesc, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                     const SizedBox(height: 24),
                     const Text('Subjects I Teach', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 12),
                     Wrap(
                       spacing: 8, runSpacing: 8,
                       children: subjectsArray.split(',').map((subj) {
                         return Chip(label: Text(subj.trim()), backgroundColor: Colors.red.shade50);
                       }).toList(),
                     )
                   ],
                 )
               : Column(
                   crossAxisAlignment: CrossAxisAlignment.start,
                   children: [
                     _buildInfoRow(Icons.school, 'Qualifications', qualifications),
                     _buildInfoRow(Icons.location_on, 'Location', location),
                     _buildInfoRow(Icons.computer, 'Teaching Modes', (t['modes'] as List?)?.join(', ') ?? 'Online/Offline'),
                     _buildInfoRow(Icons.calendar_month, 'Availability', t['availableDays'] != null ? (t['availableDays'] as List).join(', ') : 'Flexible Schedule'),
                   ],
                 )
            ),
            const SizedBox(height: 100), // padding for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LKR $rate / hour', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Text('Classes:', style: TextStyle(color: Colors.grey, fontSize: 12)),
                Row(
                  children: [
                    InkWell(
                      onTap: () { if(_numberOfClasses>1) setState(() => _numberOfClasses--); },
                      child: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text('$_numberOfClasses', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    ),
                    InkWell(
                      onTap: () { setState(() => _numberOfClasses++); },
                      child: const Icon(Icons.add_circle, color: Colors.redAccent),
                    ),
                  ],
                )
              ],
            ),
            ElevatedButton(
              onPressed: _proceedToCheckout,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))
              ),
              child: const Text('BOOK NOW', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
          Icon(icon, color: Colors.redAccent, size: 28),
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

  Widget _buildDropdown(String hint, String? value, List<String> items, Function(String?) onChanged) {
    // Ensure the current value exists in the options
    String? safeValue = items.contains(value) ? value : (items.isNotEmpty ? items[0] : null);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300)
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          value: safeValue,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
          icon: const Icon(Icons.keyboard_arrow_down, color: Colors.redAccent),
        ),
      ),
    );
  }
}

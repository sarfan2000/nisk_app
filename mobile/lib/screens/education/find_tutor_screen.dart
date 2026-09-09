import 'package:flutter/material.dart';
import 'package:nisk_app/screens/education/checkout_screen.dart';

class FindTutorScreen extends StatefulWidget {
  const FindTutorScreen({super.key});

  @override
  State<FindTutorScreen> createState() => _FindTutorScreenState();
}

class _FindTutorScreenState extends State<FindTutorScreen> {
  int _currentStep = 0;
  
  String? _selectedMode;
  String? _selectedGrade;
  String? _selectedSubject;
  String? _selectedTeacher;
  int _numberOfClasses = 1;

  final List<String> _grades = ['Grade 1', 'Grade 5', 'Grade 10', 'Grade 11']; // Mock dynamic from DB
  final List<String> _subjects = ['Mathematics', 'Science', 'English']; // Mock dynamic from DB
  final List<Map<String, dynamic>> _teachers = [
    {'name': 'Teacher A', 'experience': '8 Years', 'rate': 2000, 'rating': 4.8},
    {'name': 'Teacher B', 'experience': '5 Years', 'rate': 1500, 'rating': 4.5},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Tutor'),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep += 1);
          } else {
            // Checkout logical
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
            title: const Text('Learning Mode'),
            content: Row(
              children: [
                Expanded(child: RadioListTile<String>(
                  title: const Text('Online'),
                  value: 'Online',
                  groupValue: _selectedMode,
                  onChanged: (val) => setState(() => _selectedMode = val),
                  activeColor: Colors.redAccent,
                )),
                Expanded(child: RadioListTile<String>(
                  title: const Text('Offline'),
                  value: 'Offline',
                  groupValue: _selectedMode,
                  onChanged: (val) => setState(() => _selectedMode = val),
                  activeColor: Colors.redAccent,
                )),
              ],
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Select Grade'),
            content: DropdownButtonFormField<String>(
              value: _selectedGrade,
              items: _grades.map((grade) => DropdownMenuItem(value: grade, child: Text(grade))).toList(),
              onChanged: (val) => setState(() => _selectedGrade = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Select Subject'),
            content: DropdownButtonFormField<String>(
              value: _selectedSubject,
              items: _subjects.map((subj) => DropdownMenuItem(value: subj, child: Text(subj))).toList(),
              onChanged: (val) => setState(() => _selectedSubject = val),
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Select Teacher'),
            content: Column(
              children: _teachers.map((t) => Card(
                color: _selectedTeacher == t['name'] ? Colors.red.shade50 : Colors.white,
                child: ListTile(
                  title: Text(t['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Exp: ${t['experience']} | Rate: LKR ${t['rate']}'),
                  trailing: Text('⭐ ${t['rating']}'),
                  onTap: () => setState(() => _selectedTeacher = t['name']),
                ),
              )).toList(),
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Class Details'),
            content:Row(
              children: [
                const Text('Number of Classes: '),
                IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if(_numberOfClasses>1) _numberOfClasses--;})),
                Text('$_numberOfClasses', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _numberOfClasses++)),
              ],
            ),
            isActive: _currentStep >= 4,
          )
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    double rate = _selectedTeacher == 'Teacher A' ? 2000.0 : 1500.0;
    double subtotal = rate * _numberOfClasses;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ORDER SUMMARY'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Mode: $_selectedMode'),
            Text('Grade: $_selectedGrade'),
            Text('Subject: $_selectedSubject'),
            Text('Teacher: $_selectedTeacher'),
            const Divider(),
            Text('Classes: $_numberOfClasses'),
            Text('Rate: LKR $rate'),
            Text('Subtotal: LKR $subtotal', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
               Navigator.pop(context);
               Navigator.push(context, MaterialPageRoute(builder: (context) => EducationCheckoutScreen(
                 bookingDetails: {
                   'mode': _selectedMode,
                   'grade': _selectedGrade,
                   'subject': _selectedSubject,
                   'teacher': _selectedTeacher,
                   'classes': _numberOfClasses,
                   'rate': rate,
                   'subtotal': subtotal
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
}

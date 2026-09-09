import 'package:flutter/material.dart';

class AddProductScreen extends StatelessWidget {
  const AddProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SELL YOUR PRODUCT'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('Upload Product Images', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Product Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Category', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Price (LKR)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                SizedBox(width: 16),
                Expanded(child: TextField(decoration: InputDecoration(labelText: 'Stock Qty', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Delivery Available'),
              value: true,
              onChanged: (val) {},
              activeColor: Colors.green,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product submitted for Admin approval!')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('PUBLISH PRODUCT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}

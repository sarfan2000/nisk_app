import 'package:flutter/material.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages')),
      body: ListView(
        children: const [
          ListTile(
            leading: CircleAvatar(backgroundColor: Colors.redAccent, child: Icon(Icons.person, color: Colors.white)),
            title: Text('Teacher A', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Yes, the class tomorrow is confirmed.', maxLines: 1),
            trailing: Text('10:45 AM', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ListTile(
             leading: CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.work, color: Colors.white)),
             title: Text('BuildMax LK', style: TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text('We reviewed your CV. When can you start?'),
             trailing: Text('Yesterday', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ),
          ListTile(
             leading: CircleAvatar(backgroundColor: Colors.green, child: Icon(Icons.shopping_cart, color: Colors.white)),
             title: Text('NISK Store Seller', style: TextStyle(fontWeight: FontWeight.bold)),
             subtitle: Text('Your order has been dispatched!'),
             trailing: Text('Mon', style: TextStyle(color: Colors.grey, fontSize: 12)),
          )
        ],
      ),
    );
  }
}

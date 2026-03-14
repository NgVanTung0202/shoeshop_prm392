import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/firestore_service.dart';

class AdminUsersScreen extends StatelessWidget {

  final FirestoreService _fs = FirestoreService();

  AdminUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Quản lý người dùng"),
      ),

      body: StreamBuilder<QuerySnapshot>(

        stream: _fs.getUsers(),

        builder: (context, snapshot) {

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: Text("Không có dữ liệu"),
            );
          }

          final users = snapshot.data!.docs;

          return ListView.builder(

            itemCount: users.length,

            itemBuilder: (context, index) {

              final user = users[index];

              final data = user.data() as Map<String, dynamic>;

              return ListTile(

                leading: const Icon(Icons.person),

                title: Text(data["email"] ?? "No Email"),

                subtitle: Text("Role: ${data["role"] ?? "customer"}"),

                trailing: IconButton(

                  icon: const Icon(Icons.delete, color: Colors.red),

                  onPressed: () {
                    _fs.deleteUser(user.id);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

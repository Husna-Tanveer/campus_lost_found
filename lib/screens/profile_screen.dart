import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/auth_provider.dart';
import '../providers/item_provider.dart';
import '../models/item_model.dart';
import '../utils/colors.dart';
import 'login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final itemProvider = Provider.of<ItemProvider>(context);
    final currentUser = FirebaseAuth.instance.currentUser;
    
    final userEmail = auth.currentUser?.email ?? '';
    final userName = userEmail.split('@')[0];

    // Filter items to show only those belonging to the current user
    final myItems = itemProvider.items.where((item) => item.userId == currentUser?.uid).toList();
    final myLostCount = myItems.where((item) => item.status == ItemStatus.lost).length;
    final myFoundCount = myItems.where((item) => item.status == ItemStatus.found).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.only(
                  top: 60, bottom: 30, left: 20, right: 20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName.substring(0, 1).toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userEmail,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _statCard('Lost', myLostCount),
                      const SizedBox(width: 20),
                      _statCard('Found', myFoundCount),
                      const SizedBox(width: 20),
                      _statCard('Total', myItems.length),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // My Reports Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'My Reports',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  myItems.isEmpty
                      ? Center(
                    child: Column(
                      children: [
                        const SizedBox(height: 30),
                        Icon(Icons.inbox_outlined,
                            size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 8),
                        Text(
                          'You haven\'t reported anything yet',
                          style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: myItems.length,
                    itemBuilder: (context, index) {
                      final item = myItems[index];
                      final isLost = item.status == ItemStatus.lost;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isLost
                                ? AppColors.lost.withOpacity(0.1)
                                : AppColors.found.withOpacity(0.1),
                            child: _buildLeadingImage(item, isLost),
                          ),
                          title: Text(
                            item.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(item.location),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isLost
                                  ? AppColors.lost
                                  : AppColors.found,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              isLost ? 'LOST' : 'FOUND',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.lost),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: AppColors.lost),
                      label: const Text(
                        'Logout',
                        style: TextStyle(
                          color: AppColors.lost,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingImage(ItemModel item, bool isLost) {
    if (item.imagePath != null && !kIsWeb) {
      if (item.imagePath!.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            item.imagePath!,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              ItemModel.categoryIcon(item.category),
              color: isLost ? AppColors.lost : AppColors.found,
            ),
          ),
        );
      }
      
      final file = File(item.imagePath!);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: 40,
            height: 40,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Icon(
              ItemModel.categoryIcon(item.category),
              color: isLost ? AppColors.lost : AppColors.found,
            ),
          ),
        );
      }
    }
    return Icon(
      ItemModel.categoryIcon(item.category),
      color: isLost ? AppColors.lost : AppColors.found,
    );
  }

  Widget _statCard(String label, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

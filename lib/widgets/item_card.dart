import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/item_model.dart';
import '../providers/item_provider.dart';
import '../utils/colors.dart';
import '../screens/item_detail_screen.dart';
import '../screens/report_lost_screen.dart';
import '../screens/report_found_screen.dart';

class ItemCard extends StatelessWidget {
  final ItemModel item;

  const ItemCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final isLost = item.status == ItemStatus.lost;
    final currentUser = FirebaseAuth.instance.currentUser;
    // Check if the current user is the one who posted this item
    final isOwner = currentUser != null && item.userId == currentUser.uid;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ItemDetailScreen(item: item),
          ),
        ),
        child: Column(
          children: [
            // Status Header
            Container(
              decoration: BoxDecoration(
                color: isLost ? AppColors.lost : AppColors.found,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isLost ? Icons.report_problem : Icons.check_circle,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLost ? 'LOST' : 'FOUND',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(item.dateTime),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image or Icon
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildImage(),
                  ),
                  const SizedBox(width: 12),

                  // Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.primary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            ItemModel.categoryToString(item.category),
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Action Buttons (Only shown to owner)
                  if (isOwner)
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.primary),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => isLost
                                  ? ReportLostScreen(itemToEdit: item)
                                  : ReportFoundScreen(itemToEdit: item),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent),
                        onPressed: () => _confirmDelete(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (item.imagePath == null) return _iconContainer();
    if (kIsWeb) return _iconContainer();

    // Check if it's a URL or a local file
    if (item.imagePath!.startsWith('http')) {
      return Image.network(
        item.imagePath!,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _iconContainer(),
      );
    }

    final file = File(item.imagePath!);
    if (!file.existsSync()) return _iconContainer();

    return Image.file(
      file,
      width: 80,
      height: 80,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => _iconContainer(),
    );
  }

  Widget _iconContainer() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        ItemModel.categoryIcon(item.category),
        size: 40,
        color: AppColors.primary,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Delete Item'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            onPressed: () {
              Provider.of<ItemProvider>(context, listen: false)
                  .deleteItem(item.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

enum ItemStatus { lost, found }

enum ItemCategory {
  electronics,
  books,
  clothing,
  accessories,
  documents,
  other,
}

class ItemModel {
  final String id;
  final String title;
  final String description;
  final ItemStatus status;
  final ItemCategory category;
  final String location;
  final DateTime dateTime;
  final String contactName;
  final String contactNumber;
  final String userId; // Kaunse user ne post kiya hai
  String? imagePath;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.category,
    required this.location,
    required this.dateTime,
    required this.contactName,
    required this.contactNumber,
    required this.userId,
    this.imagePath,
  });

  static String categoryToString(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics: return 'Electronics';
      case ItemCategory.books: return 'Books';
      case ItemCategory.clothing: return 'Clothing';
      case ItemCategory.accessories: return 'Accessories';
      case ItemCategory.documents: return 'Documents';
      case ItemCategory.other: return 'Other';
    }
  }

  static IconData categoryIcon(ItemCategory category) {
    switch (category) {
      case ItemCategory.electronics: return Icons.devices;
      case ItemCategory.books: return Icons.menu_book;
      case ItemCategory.clothing: return Icons.checkroom;
      case ItemCategory.accessories: return Icons.watch;
      case ItemCategory.documents: return Icons.description;
      case ItemCategory.other: return Icons.category;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status.index,
      'category': category.index,
      'location': location,
      'dateTime': dateTime.toIso8601String(),
      'contactName': contactName,
      'contactNumber': contactNumber,
      'userId': userId,
      'imagePath': imagePath,
    };
  }

  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      status: ItemStatus.values[map['status']],
      category: ItemCategory.values[map['category']],
      location: map['location'],
      dateTime: DateTime.parse(map['dateTime']),
      contactName: map['contactName'],
      contactNumber: map['contactNumber'],
      userId: map['userId'] ?? '',
      imagePath: map['imagePath'],
    );
  }
}
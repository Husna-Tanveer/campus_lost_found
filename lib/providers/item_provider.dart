import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<ItemModel> _items = [];

  List<ItemModel> get items => _items;

  List<ItemModel> get lostItems =>
      _items.where((item) => item.status == ItemStatus.lost).toList();

  List<ItemModel> get foundItems =>
      _items.where((item) => item.status == ItemStatus.found).toList();

  ItemProvider() {
    _listenToItems();
  }

  // Listen to Firestore real-time updates
  void _listenToItems() {
    _firestore
        .collection('items')
        .orderBy('dateTime', descending: true)
        .snapshots()
        .listen((snapshot) {
      _items = snapshot.docs
          .map((doc) => ItemModel.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      notifyListeners();
    });
  }

  // Search filter
  List<ItemModel> searchItems(String query) {
    if (query.isEmpty) return _items;
    return _items.where((item) {
      return item.title.toLowerCase().contains(query.toLowerCase()) ||
          item.description.toLowerCase().contains(query.toLowerCase()) ||
          item.location.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Add new item to Firestore
  Future<void> addItem({
    required String title,
    required String description,
    required ItemStatus status,
    required ItemCategory category,
    required String location,
    required String contactName,
    required String contactNumber,
    String? imagePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('items').add({
      'title': title,
      'description': description,
      'status': status.index,
      'category': category.index,
      'location': location,
      'dateTime': DateTime.now().toIso8601String(),
      'contactName': contactName,
      'contactNumber': contactNumber,
      'userId': user.uid,
      'imagePath': imagePath,
    });
  }

  // Update existing item in Firestore
  Future<void> updateItem({
    required String id,
    required String title,
    required String description,
    required ItemCategory category,
    required String location,
    required String contactName,
    required String contactNumber,
    String? imagePath,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore.collection('items').doc(id).update({
      'title': title,
      'description': description,
      'category': category.index,
      'location': location,
      'contactName': contactName,
      'contactNumber': contactNumber,
      'imagePath': imagePath,
    });
  }

  // Delete item from Firestore
  Future<void> deleteItem(String id) async {
    await _firestore.collection('items').doc(id).delete();
  }
}
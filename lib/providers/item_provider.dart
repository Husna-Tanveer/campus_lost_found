import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import '../models/item_model.dart';

class ItemProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  List<ItemModel> _items = [];

  List<ItemModel> get items => _items;

  List<ItemModel> get lostItems =>
      _items.where((item) => item.status == ItemStatus.lost).toList();

  List<ItemModel> get foundItems =>
      _items.where((item) => item.status == ItemStatus.found).toList();

  ItemProvider() {
    _listenToItems();
  }

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

  // Upload image to Firebase Storage and get URL
  Future<String?> _uploadImage(String localPath) async {
    try {
      File file = File(localPath);
      String fileName = 'items/${DateTime.now().millisecondsSinceEpoch}.jpg';
      Reference ref = _storage.ref().child(fileName);
      UploadTask uploadTask = ref.putFile(file);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

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

    String? downloadUrl;
    if (imagePath != null && !imagePath.startsWith('http')) {
      downloadUrl = await _uploadImage(imagePath);
    }

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
      'imagePath': downloadUrl ?? imagePath,
    });
  }

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

    String? imageUrl = imagePath;
    if (imagePath != null && !imagePath.startsWith('http')) {
      imageUrl = await _uploadImage(imagePath);
    }

    await _firestore.collection('items').doc(id).update({
      'title': title,
      'description': description,
      'category': category.index,
      'location': location,
      'contactName': contactName,
      'contactNumber': contactNumber,
      'imagePath': imageUrl,
    });
  }

  Future<void> deleteItem(String id) async {
    await _firestore.collection('items').doc(id).delete();
  }
}
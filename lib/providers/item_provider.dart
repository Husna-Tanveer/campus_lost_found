import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/item_model.dart';

class ItemProvider extends ChangeNotifier {
  List<ItemModel> _items = [];
  final Uuid _uuid = const Uuid();

  List<ItemModel> get items => _items;

  List<ItemModel> get lostItems =>
      _items.where((item) => item.status == ItemStatus.lost).toList();

  List<ItemModel> get foundItems =>
      _items.where((item) => item.status == ItemStatus.found).toList();

  ItemProvider() {
    loadItems();
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

  // Category filter
  List<ItemModel> filterByCategory(ItemCategory category) {
    return _items.where((item) => item.category == category).toList();
  }

  // Add new item
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
    final newItem = ItemModel(
      id: _uuid.v4(),
      title: title,
      description: description,
      status: status,
      category: category,
      location: location,
      dateTime: DateTime.now(),
      contactName: contactName,
      contactNumber: contactNumber,
      imagePath: imagePath,
    );
    _items.insert(0, newItem);
    notifyListeners();
    await saveItems();
  }

  // Delete item
  Future<void> deleteItem(String id) async {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
    await saveItems();
  }

  // Save to SharedPreferences
  Future<void> saveItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemList = _items.map((item) => jsonEncode(item.toMap())).toList();
    await prefs.setStringList('items', itemList);
  }

  // Load from SharedPreferences
  Future<void> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final itemList = prefs.getStringList('items') ?? [];
    _items = itemList
        .map((item) => ItemModel.fromMap(jsonDecode(item)))
        .toList();
    notifyListeners();
  }
}
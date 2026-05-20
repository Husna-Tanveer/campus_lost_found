import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/item_provider.dart';
import '../models/item_model.dart';
import '../utils/colors.dart';
import '../utils/locations.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class ReportLostScreen extends StatefulWidget {
  final ItemModel? itemToEdit;
  const ReportLostScreen({super.key, this.itemToEdit});

  @override
  State<ReportLostScreen> createState() => _ReportLostScreenState();
}

class _ReportLostScreenState extends State<ReportLostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  ItemCategory _selectedCategory = ItemCategory.other;
  String? _selectedLocation;
  String? _imagePath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.itemToEdit?.title ?? '');
    _descController = TextEditingController(text: widget.itemToEdit?.description ?? '');
    _nameController = TextEditingController(text: widget.itemToEdit?.contactName ?? '');
    _phoneController = TextEditingController(text: widget.itemToEdit?.contactNumber ?? '+92');
    
    if (widget.itemToEdit != null) {
      _selectedCategory = widget.itemToEdit!.category;
      _selectedLocation = widget.itemToEdit!.location;
      _imagePath = widget.itemToEdit!.imagePath;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _imagePath = picked.path);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final provider = Provider.of<ItemProvider>(context, listen: false);

    if (widget.itemToEdit != null) {
      // Update existing item
      await provider.updateItem(
        id: widget.itemToEdit!.id,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        category: _selectedCategory,
        location: _selectedLocation ?? '',
        contactName: _nameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        imagePath: _imagePath,
      );
    } else {
      // Add new item
      await provider.addItem(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        status: ItemStatus.lost,
        category: _selectedCategory,
        location: _selectedLocation ?? '',
        contactName: _nameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        imagePath: _imagePath,
      );
    }

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.itemToEdit != null ? 'Report updated successfully!' : 'Lost item reported successfully!'),
          backgroundColor: AppColors.lost,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.itemToEdit != null;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Lost Report' : 'Report Lost Item',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.lost.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.lost.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.report_problem, color: AppColors.lost),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Update the details of your report below.' : 'Fill in the details of your lost item. We\'ll help you find it!',
                        style: const TextStyle(
                          color: AppColors.lost,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Image Picker
              _sectionLabel('Item Photo (Optional)'),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.divider,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _imagePath != null
                      ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? const Icon(Icons.check_circle, color: AppColors.found, size: 50)
                          : _imagePath!.startsWith('assets/') || _imagePath!.startsWith('http') 
                             ? const Icon(Icons.image, size: 50, color: AppColors.primary)
                             : Image.file(
                        File(_imagePath!),
                        fit: BoxFit.cover,
                      ),
                  )
                      : const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate,
                          size: 50, color: AppColors.primary),
                      SizedBox(height: 8),
                      Text(
                        'Tap to add photo',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Title
              _sectionLabel('Item Title *'),
              _buildTextField(
                controller: _titleController,
                hint: 'e.g. Black Leather Wallet',
                icon: Icons.title,
                validator: (val) =>
                val!.isEmpty ? 'Please enter item title' : null,
              ),

              const SizedBox(height: 16),

              // Category
              _sectionLabel('Category *'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.divider),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<ItemCategory>(
                    value: _selectedCategory,
                    isExpanded: true,
                    items: ItemCategory.values.map((cat) {
                      return DropdownMenuItem(
                        value: cat,
                        child: Row(
                          children: [
                            Icon(ItemModel.categoryIcon(cat),
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 12),
                            Text(ItemModel.categoryToString(cat)),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setState(() => _selectedCategory = val!),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description
              _sectionLabel('Description *'),
              _buildTextField(
                controller: _descController,
                hint: 'Describe the item in detail...',
                icon: Icons.description,
                maxLines: 3,
                validator: (val) =>
                val!.isEmpty ? 'Please enter description' : null,
              ),

              const SizedBox(height: 16),

              // Location
              _sectionLabel('Last Seen Location *'),
              DropdownButtonFormField<String>(
                value: _selectedLocation,
                isExpanded: true,
                hint: const Text('Select Location', style: TextStyle(color: AppColors.textSecondary)),
                icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                items: AppLocations.locations.map((String location) {
                  return DropdownMenuItem<String>(
                    value: location,
                    child: Text(
                      location,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedLocation = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a location' : null,
              ),

              const SizedBox(height: 16),

              // Contact Name
              _sectionLabel('Your Name *'),
              _buildTextField(
                controller: _nameController,
                hint: 'Enter your full name',
                icon: Icons.person,
                validator: (val) =>
                val!.isEmpty ? 'Please enter your name' : null,
              ),

              const SizedBox(height: 16),

              // Phone
              _sectionLabel('Contact Number *'),
              _buildTextField(
                controller: _phoneController,
                hint: 'Enter your phone number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Please enter contact number';
                  }
                  if (!RegExp(r'^((\+92)|(92)|(0))?[3][0-9]{9}$').hasMatch(val)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.lost,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(isEditing ? Icons.save : Icons.report_problem, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        isEditing ? 'Save Changes' : 'Submit Lost Report',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lost),
        ),
      ),
    );
  }
}

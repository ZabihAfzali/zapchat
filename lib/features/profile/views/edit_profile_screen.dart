// lib/features/profile/views/edit_profile_screen.dart
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zapchat/features/profile/repository/profile_repository.dart';

import '../../../core/constants/countries.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileRepository _repository = ProfileRepository();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _bioController = TextEditingController();
  final _countryController = TextEditingController();

  DateTime? _selectedBirthday;
  String _selectedGender = "Male";

  File? _selectedImage;
  String? _currentImageUrl;

  bool _isLoading = true;
  bool _isEditMode = false;
  late Map<String, dynamic> _originalData;

  @override
  void initState() {
    super.initState();
    _loadUserData();

    // Add listeners to detect changes
    _nameController.addListener(_checkForChanges);
    _phoneController.addListener(_checkForChanges);
    _bioController.addListener(_checkForChanges);
    _countryController.addListener(_checkForChanges);
  }

  @override
  void dispose() {
    _nameController.removeListener(_checkForChanges);
    _phoneController.removeListener(_checkForChanges);
    _bioController.removeListener(_checkForChanges);
    _countryController.removeListener(_checkForChanges);
    _nameController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  // ================= CHECK FOR CHANGES =================

  void _checkForChanges() {
    if (!_isLoading) {
      // Check if current image is different from original
      final hasNewImage = _selectedImage != null;
      final hadOriginalImage = _originalData['profileImage'] != null &&
          _originalData['profileImage'].isNotEmpty;

      // Image changed if: we have a new image OR we removed the original image
      final imageChanged = hasNewImage ||
          (hadOriginalImage && _selectedImage == null && _currentImageUrl == null);

      final hasChanges =
          _nameController.text != _originalData['userName'] ||
              _phoneController.text != _originalData['phoneNumber'] ||
              _bioController.text != _originalData['status'] ||
              _countryController.text != _originalData['country'] ||
              _selectedGender != _originalData['gender'] ||
              _selectedBirthday != _originalData['birthdayDate'] ||
              imageChanged; // Include image change detection

      if (hasChanges != _isEditMode) {
        setState(() {
          _isEditMode = hasChanges;
        });
      }
    }
  }

  // ================= LOAD DATA =================

  Future<void> _loadUserData() async {
    try {
      // Load from users collection directly
      final userData = await _repository.getUserData();

      setState(() {
        // Handle field name mapping (userName vs name)
        _nameController.text = userData['userName'] ?? userData['name'] ?? '';
        _phoneController.text = userData['phoneNumber'] ?? userData['phone'] ?? '';
        _bioController.text = userData['status'] ?? 'Hey there! I am using ZapChat';
        _countryController.text = userData['country'] ?? '';
        _selectedGender = userData['gender'] ?? 'Male';
        _currentImageUrl = userData['profileImage'] ?? userData['profilePicture'] ?? '';

        // Handle birthday which might be stored as Timestamp or String
        if (userData['birthday'] != null) {
          if (userData['birthday'] is Timestamp) {
            _selectedBirthday = (userData['birthday'] as Timestamp).toDate();
          } else if (userData['birthday'] is String) {
            _selectedBirthday = DateTime.tryParse(userData['birthday']);
          }
        }

        // Store original data for comparison
        _originalData = {
          'userName': _nameController.text,
          'phoneNumber': _phoneController.text,
          'status': _bioController.text,
          'country': _countryController.text,
          'gender': _selectedGender,
          'birthdayDate': _selectedBirthday,
          'profileImage': _currentImageUrl,
        };

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
        _originalData = {};
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.xmark, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile",
            style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : (_isEditMode ? _saveProfile : null),
            child: Text(
              _isEditMode ? "Save" : "Edit",
              style: TextStyle(
                color: _isEditMode
                    ? CupertinoColors.systemYellow
                    : Colors.grey,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? const Center(
          child: CupertinoActivityIndicator(color: Colors.yellow))
          : SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Column(
          children: [
            _buildProfileImage(),
            SizedBox(height: 30.h),
            _buildTextField(
                _nameController, "Display Name", CupertinoIcons.person),
            _buildTextField(_phoneController, "Phone",
                CupertinoIcons.phone),
            _buildTextField(_bioController, "Status",
                CupertinoIcons.info),
            _buildCountrySelector(), // Changed from _buildCountryDropdown
            SizedBox(height: 20.h),
            _buildBirthdayPicker(),
            SizedBox(height: 20.h),
            _buildGenderSelector(),
          ],
        ),
      ),
    );
  }

  // ================= PROFILE IMAGE =================

  Widget _buildProfileImage() {
    ImageProvider? imageProvider;

    if (_selectedImage != null) {
      imageProvider = FileImage(_selectedImage!);
    } else if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_currentImageUrl!);
    }

    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 60.r,
          backgroundColor: CupertinoColors.systemYellow,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? const Icon(CupertinoIcons.person,
              size: 50, color: Colors.black)
              : null,
        ),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: CupertinoColors.systemYellow,
            ),
            child: const Icon(CupertinoIcons.camera,
                color: Colors.black, size: 18),
          ),
        )
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller,
      String label, IconData icon) {
    return Container(
      margin: EdgeInsets.only(bottom: 15.h),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: CupertinoColors.systemYellow),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
        ),
      ),
    );
  }

  // ================= SEARCHABLE COUNTRY SELECTOR =================

  Widget _buildCountrySelector() {
    return GestureDetector(
      onTap: _showCountryPicker,
      child: Container(
        margin: EdgeInsets.only(bottom: 15.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(CupertinoIcons.location,
                color: CupertinoColors.systemYellow, size: 20),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                _countryController.text.isEmpty
                    ? "Select Country"
                    : _countryController.text,
                style: TextStyle(
                  color: _countryController.text.isEmpty
                      ? Colors.grey[400]
                      : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Icon(CupertinoIcons.chevron_down,
                color: CupertinoColors.systemYellow, size: 18),
          ],
        ),
      ),
    );
  }

  void _showCountryPicker() {
    final searchController = TextEditingController();
    final filteredCountries = ValueNotifier<List<String>>(countries);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.8,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(16.r),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select Country',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.r),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[800],
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search country...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      prefixIcon: const Icon(CupertinoIcons.search,
                          color: CupertinoColors.systemYellow),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w, vertical: 12.h),
                    ),
                    onChanged: (query) {
                      if (query.isEmpty) {
                        filteredCountries.value = countries;
                      } else {
                        filteredCountries.value = countries
                            .where((country) => country
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                            .toList();
                      }
                    },
                  ),
                ),
              ),

              SizedBox(height: 10.h),

              // Country list
              Expanded(
                child: ValueListenableBuilder<List<String>>(
                  valueListenable: filteredCountries,
                  builder: (context, list, child) {
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          'No countries found',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final country = list[index];
                        final isSelected = country == _countryController.text;

                        return ListTile(
                          title: Text(
                            country,
                            style: TextStyle(
                              color: isSelected ? CupertinoColors.systemYellow : Colors.white,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(CupertinoIcons.checkmark_alt,
                              color: CupertinoColors.systemYellow)
                              : null,
                          onTap: () {
                            setState(() {
                              _countryController.text = country;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBirthdayPicker() {
    return ListTile(
      tileColor: Colors.grey[900],
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      leading: const Icon(CupertinoIcons.calendar,
          color: CupertinoColors.systemYellow),
      title: Text(
        _selectedBirthday == null
            ? "Select Birthday"
            : "${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}",
        style: const TextStyle(color: Colors.white),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _selectedBirthday ?? DateTime(2000),
          firstDate: DateTime(1950),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _selectedBirthday = date);
        }
      },
    );
  }

  Widget _buildGenderSelector() {
    // Ensure the selected value is valid, default to null if not
    final isValidValue = ["Male", "Female", "Other"].contains(_selectedGender);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: DropdownButton<String>(
        value: isValidValue ? _selectedGender : null,
        hint: Row(
          children: [
            Icon(CupertinoIcons.person,
                color: CupertinoColors.systemYellow, size: 20),
            SizedBox(width: 12.w),
            Text(
              _selectedGender.isEmpty ? "Select Gender" : _selectedGender,
              style: TextStyle(
                color: _selectedGender.isEmpty ? Colors.grey[400] : Colors.white,
              ),
            ),
          ],
        ),
        dropdownColor: Colors.grey[900],
        iconEnabledColor: CupertinoColors.systemYellow,
        style: const TextStyle(color: Colors.white),
        underline: const SizedBox(),
        isExpanded: true,
        items: ["Male", "Female", "Other"]
            .map((gender) => DropdownMenuItem<String>(
          value: gender,
          child: Row(
            children: [
              SizedBox(width: 32.w), // Align with hint icon
              Text(gender),
            ],
          ),
        ))
            .toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedGender = value;
            });
          }
        },
      ),
    );
  }
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (picked != null) {
        print('✅ Image picked: ${picked.path}');

        setState(() {
          _selectedImage = File(picked.path);
        });

        _checkForChanges();
      }
    } catch (e) {
      print('❌ Error picking image: $e');
    }
  }

  // ================= SAVE PROFILE =================

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      // Prepare profile data for users collection
      final Map<String, dynamic> profileData = {
        'userName': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'status': _bioController.text.trim(),
        'country': _countryController.text.trim(),
        'gender': _selectedGender,
      };

      // Add birthday if selected
      if (_selectedBirthday != null) {
        profileData['birthday'] = _selectedBirthday!.toIso8601String();
      }

      // Use the updateUserProfile method which handles image upload
      await _repository.updateUserProfile(
        profileData: profileData,
        imageFile: _selectedImage,
      );

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Return to previous screen with result
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error saving profile: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
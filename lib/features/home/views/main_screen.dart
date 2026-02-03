import 'package:flutter/material.dart';
import 'package:zapchat/features/home/repository/home_repository.dart';

import '../../../core/widgets/custom_nav_bar.dart';
import 'home_tab.dart';
import 'chat_tab.dart';
import 'camera_tab.dart';
import 'stories_tab.dart';
import 'profile_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late HomeRepository _homeRepository;

  final List<Widget> _tabs = [];

  @override
  void initState() {
    super.initState();
    _homeRepository = HomeRepository();
    _initializeTabs();
  }

  void _initializeTabs() {
    _tabs.addAll([
      HomeTab(homeRepository: _homeRepository),
      ChatTab(homeRepository: _homeRepository),
      const CameraTab(),
      StoriesTab(homeRepository: _homeRepository),
      ProfileTab(homeRepository: _homeRepository),
    ]);
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _tabs.elementAt(_selectedIndex),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
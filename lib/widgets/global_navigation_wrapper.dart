import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';
import '../services/razorpay_payment_service.dart';
import '../providers/auth_provider.dart';
import '../screens/home_screen.dart';
import '../screens/live_stream_screen.dart';
import '../screens/reels_screen.dart';
import '../screens/add_options_screen.dart';
import '../screens/baba_pages_screen.dart';
import '../profile_ui.dart';
import '../utils/video_manager.dart';

class GlobalNavigationWrapper extends StatefulWidget {
  final Widget child;
  final int? initialIndex;

  const GlobalNavigationWrapper({
    super.key,
    required this.child,
    this.initialIndex,
  });

  @override
  State<GlobalNavigationWrapper> createState() => _GlobalNavigationWrapperState();
}

class _GlobalNavigationWrapperState extends State<GlobalNavigationWrapper> {
  int _currentIndex = 0;
  // Lazy load pages - only create them when needed
  final Map<int, Widget> _initializedPages = {};
  
  // Store initial index to load only that screen first
  int get _initialScreenIndex => widget.initialIndex ?? 0;

  @override
  void initState() {
    super.initState();
    _currentIndex = _initialScreenIndex;
    
    // Initialize Razorpay payment service
    RazorpayPaymentService().initialize();
    
    // Only initialize the initial screen immediately
    if (_initializedPages[_initialScreenIndex] == null) {
      _initializedPages[_initialScreenIndex] = _createPage(_initialScreenIndex);
      print('GlobalNavigation: Initialized only screen $_initialScreenIndex');
    }
  }

  Widget _createPage(int index) {
    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const ReelsScreen();
      case 2:
        return const AddOptionsScreen();
      case 3:
        return const BabaPagesScreen();
      case 4:
        return const LiveStreamScreen();
      case 5:
        return const ProfileUI();
      default:
        return const HomeScreen();
    }
  }

  void _onTabTapped(int index) {
    // Special handling for Live Darshan (index 4) - show payment on Android
    if (index == 4) {
      _handleLiveDarshanAccess();
      return;
    }
    
    // If leaving reels section (index 1), pause all videos
    if (_currentIndex == 1 && index != 1) {
      print('GlobalNavigation: Leaving reels section, pausing videos');
      VideoManager().pauseCurrentVideo();
    }
    
    // Only initialize the page if it hasn't been initialized yet
    if (_initializedPages[index] == null) {
      print('GlobalNavigation: Lazy loading screen $index');
      _initializedPages[index] = _createPage(index);
    }
    
    setState(() {
      _currentIndex = index;
    });
  }

  /// Handle Live Darshan access with payment (Android only)
  /// 
  /// NOTE: Payment is ONLY required to access the Live Darshan section.
  /// Once inside, "Start Live" (host) and "Join Live" (viewer) buttons 
  /// work normally WITHOUT any payment requirement.
  void _handleLiveDarshanAccess() {
    // Check if Android platform
    if (!Platform.isAndroid) {
      // For non-Android platforms, directly navigate to Live Darshan
      _navigateToLiveDarshan();
      return;
    }

    // Show payment dialog/process payment on Android
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userEmail = authProvider.userProfile?.email;
    final userContact = authProvider.userProfile?.phoneNumber;

    // Show payment confirmation dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.deepPurple[400], size: 24),
            const SizedBox(width: 8),
            const Text(
              'Live Darshan Access',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'To access Live Darshan, please complete a payment of ₹1.',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.deepPurple.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.deepPurple.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.deepPurple[300], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment required for Live Darshan access',
                      style: TextStyle(
                        color: Colors.deepPurple[200],
                        fontFamily: 'Poppins',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[400],
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processPayment(userEmail, userContact);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
            ),
            child: const Text(
              'Pay ₹1',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Process Razorpay payment for Live Darshan
  void _processPayment(String? userEmail, String? userContact) {
    final paymentService = RazorpayPaymentService();
    
    // Ensure payment service is initialized
    paymentService.initialize();
    
    debugPrint('Starting payment process for Live Darshan...');

    if (!paymentService.isSupported()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Payment is only supported on Android devices.',
            style: TextStyle(fontFamily: 'Poppins'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          color: Colors.deepPurple,
        ),
      ),
    );

    // Process payment
    paymentService.processLiveDarshanPayment(
      userEmail: userEmail,
      userContact: userContact,
      onSuccess: (paymentId) {
        debugPrint('Payment success callback received! Payment ID: $paymentId');
        
        // Close loading dialog if it's still open
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        
        debugPrint('Closing loading dialog and navigating to Live Darshan...');
        
        // Navigate to Live Darshan screen immediately
        _navigateToLiveDarshan();
        
        // Show success message after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Payment successful! Welcome to Live Darshan',
                        style: const TextStyle(
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        });
      },
      onError: (error) {
        // Close loading dialog
        Navigator.pop(context);
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      },
    );
  }

  /// Navigate to Live Darshan screen
  void _navigateToLiveDarshan() {
    // Only initialize the page if it hasn't been initialized yet
    if (_initializedPages[4] == null) {
      print('GlobalNavigation: Lazy loading Live Darshan screen');
      _initializedPages[4] = _createPage(4);
    }
    
    // Use WidgetsBinding to ensure navigation happens after current frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _currentIndex = 4;
        });
        print('GlobalNavigation: Navigated to Live Darshan (index 4)');
      }
    });
  }

  @override
  void dispose() {
    RazorpayPaymentService().dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: List.generate(6, (index) {
              // Return the initialized page, or empty container if not loaded yet
              return _initializedPages[index] ?? Container();
            }),
          ),
          bottomNavigationBar: Container(
            decoration: BoxDecoration(
              color: themeService.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: themeService.primaryColor.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      icon: Icons.home,
                      label: 'Home',
                      index: 0,
                      isSelected: _currentIndex == 0,
                    ),
                    _buildNavItem(
                      icon: Icons.video_library,
                      label: 'Reels',
                      index: 1,
                      isSelected: _currentIndex == 1,
                    ),
                    _buildNavItem(
                      icon: Icons.add,
                      label: 'Add',
                      index: 2,
                      isSelected: _currentIndex == 2,
                    ),
                    _buildNavItem(
                      icon: Icons.self_improvement,
                      label: 'Baba Ji',
                      index: 3,
                      isSelected: _currentIndex == 3,
                    ),
                    _buildNavItem(
                      icon: Icons.live_tv,
                      label: 'Live Dars...',
                      index: 4,
                      isSelected: _currentIndex == 4,
                    ),
                    _buildNavItem(
                      icon: Icons.person,
                      label: 'Account',
                      index: 5,
                      isSelected: _currentIndex == 5,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isSelected,
  }) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return GestureDetector(
          onTap: () => _onTabTapped(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected 
                    ? themeService.primaryColor 
                    : themeService.onSurfaceColor.withOpacity(0.6),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected 
                      ? themeService.primaryColor 
                      : themeService.onSurfaceColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'dart:ui';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'models/user_model.dart';
import 'models/post_model.dart';
import 'providers/auth_provider.dart';
import 'screens/followers_screen.dart';
import 'screens/following_screen.dart';
import 'screens/post_full_view_screen.dart';
import 'screens/post_slider_screen.dart';
import 'utils/snackbar_helper.dart';
import 'services/api_service.dart';
import 'services/local_storage_service.dart';
import 'screens/search_screen.dart';
import 'screens/add_options_screen.dart';
import 'screens/home_screen.dart';
import 'screens/baba_pages_screen.dart';
import 'screens/live_stream_screen.dart';
import 'screens/reels_screen.dart';
import 'screens/profile_edit_screen.dart';
import 'screens/story_upload_screen.dart';
import 'widgets/dp_widget.dart';
import 'services/posts_management_service.dart';
import 'services/reels_management_service.dart';

class ProfileUI extends StatefulWidget {
  const ProfileUI({super.key});

  @override
  State<ProfileUI> createState() => _ProfileUIState();
}

class _ProfileUIState extends State<ProfileUI> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _gridSectionKey = GlobalKey();
  
  int _selectedTab = 0; // 0 = Posts, 1 = Reels, 2 = Tagged
  final Set<String> _deletedMediaIds = <String>{};
  
  List<Post> _userPosts = [];
  List<Post> _userReels = [];
  
  bool _isLoadingPosts = false;
  bool _isLoadingReels = false;
  bool _hasLoadedPosts = false;
  bool _hasLoadedReels = false;
  
  int _followersCount = 0;
  int _followingCount = 0;
  bool _isLoadingFollowers = false;
  bool _isLoadingFollowing = false;

  @override
  void initState() {
    super.initState();
    // Load initial data after frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Load all initial data (posts, reels, followers, following)
  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadUserPosts(),
      _loadUserReels(),
      _loadFollowersCounts(),
    ]);
  }

  /// Load user's posts
  Future<void> _loadUserPosts() async {
    if (_isLoadingPosts || _hasLoadedPosts) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    final userId = authProvider.userProfile?.id;

    if (token == null || userId == null) {
      debugPrint('ProfileUI: Cannot load posts - token or userId is null');
      return;
    }

    setState(() {
      _isLoadingPosts = true;
    });

    try {
      final response = await PostsManagementService.retrievePosts(
        token: token,
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userPosts = response.posts;
          _isLoadingPosts = false;
          _hasLoadedPosts = true;
        });
        debugPrint('ProfileUI: Loaded ${_userPosts.length} posts');
      }
    } catch (e) {
      debugPrint('ProfileUI: Error loading posts: $e');
      if (mounted) {
        setState(() {
          _isLoadingPosts = false;
        });
      }
    }
  }

  /// Load user's reels
  Future<void> _loadUserReels() async {
    if (_isLoadingReels || _hasLoadedReels) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final token = authProvider.authToken;
    final userId = authProvider.userProfile?.id;

    if (token == null || userId == null) {
      debugPrint('ProfileUI: Cannot load reels - token or userId is null');
      return;
    }

    setState(() {
      _isLoadingReels = true;
    });

    try {
      final response = await ReelsManagementService.retrieveReels(
        token: token,
        userId: userId,
        limit: 50,
        offset: 0,
      );

      if (mounted) {
        setState(() {
          _userReels = response.reels;
          _isLoadingReels = false;
          _hasLoadedReels = true;
        });
        debugPrint('ProfileUI: Loaded ${_userReels.length} reels');
      }
    } catch (e) {
      debugPrint('ProfileUI: Error loading reels: $e');
      if (mounted) {
        setState(() {
          _isLoadingReels = false;
        });
      }
    }
  }

  /// Load followers and following counts
  Future<void> _loadFollowersCounts() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.userProfile?.id;

    if (userId == null) return;

    setState(() {
      _isLoadingFollowers = true;
      _isLoadingFollowing = true;
    });

    try {
      final results = await Future.wait([
        authProvider.getFollowersForUser(userId),
        authProvider.getFollowingUsersForUser(userId),
      ]);

      if (mounted) {
        setState(() {
          _followersCount = results[0].length;
          _followingCount = results[1].length;
          _isLoadingFollowers = false;
          _isLoadingFollowing = false;
        });
      }
    } catch (e) {
      debugPrint('ProfileUI: Error loading follow counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingFollowers = false;
          _isLoadingFollowing = false;
        });
      }
    }
  }

  /// Refresh all media and user profile
  Future<void> _refreshMedia() async {
    // Reset loaded flags to allow reloading
    _hasLoadedPosts = false;
    _hasLoadedReels = false;
    
    await Future.wait([
      _loadUserPosts(),
      _loadUserReels(),
      _loadFollowersCounts(),
      Provider.of<AuthProvider>(context, listen: false).refreshUserProfile(),
    ]);
  }

  /// Scroll to grid section
  Future<void> _scrollToGrid() async {
    final contextForGrid = _gridSectionKey.currentContext;
    if (contextForGrid != null) {
      await Scrollable.ensureVisible(
        contextForGrid,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
        alignment: 0.05,
      );
      return;
    }
    if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.userProfile;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/Signup page bg.jpeg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Blur effect overlay
                BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
                  child: Container(color: Colors.transparent),
                ),
                // Spiritual symbols overlay
                _buildSpiritualSymbolsOverlay(),
                SafeArea(
                  child: Column(
                    children: [
                      // Custom App Bar
                      _buildAppBar(auth, user),
                      // Profile Content
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshMedia,
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: _buildProfileContent(user, auth),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Build app bar
  Widget _buildAppBar(AuthProvider auth, UserModel user) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
          ),
          const Expanded(
            child: Text(
              'Account',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
                fontSize: 20,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SearchScreen()),
              );
            },
          ),
          _buildPopupMenu(user),
        ],
      ),
    );
  }

  /// Build popup menu
  Widget _buildPopupMenu(UserModel user) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.black),
      tooltip: 'More options',
      onSelected: (String value) {
        if (value == 'edit_profile') {
          _navigateToEditProfile(user);
        } else if (value == 'logout') {
          _showLogoutDialog(context);
        }
      },
      itemBuilder: (BuildContext context) => [
        const PopupMenuItem<String>(
          value: 'edit_profile',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.edit, color: Color(0xFF1A1A1A), size: 20),
                SizedBox(width: 12),
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: 'logout',
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.logout, color: Color(0xFFE53E3E), size: 20),
                SizedBox(width: 12),
                Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFE53E3E),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build profile content
  Widget _buildProfileContent(UserModel user, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              children: [
                _buildProfileHeader(user, auth),
                const SizedBox(height: 12),
                _buildUserInfo(user),
                const SizedBox(height: 18),
                _buildStatsRow(user),
                const SizedBox(height: 18),
                _buildBio(user),
                const SizedBox(height: 18),
                _buildTabs(),
                const SizedBox(height: 16),
                _buildGrid(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build profile header with avatar
  Widget _buildProfileHeader(UserModel user, AuthProvider auth) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFF00C853), Color(0xFF00E676)],
            ),
          ),
          child: Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: DPWidget(
                  currentImageUrl: user.profileImageUrl,
                  userId: user.id,
                  token: auth.authToken ?? '',
                  userName: user.fullName,
                  onImageChanged: (String newImageUrl) async {
                    final updatedUser = user.copyWith(
                      profileImageUrl: newImageUrl.isEmpty ? null : newImageUrl,
                    );
                    auth.updateLocalUserProfile(updatedUser);
                  },
                  size: 88,
                  borderColor: Colors.white,
                  showEditButton: false,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: () {
              final token = auth.authToken;
              if (token == null || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please login to add a story')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StoryUploadScreen(token: token),
                ),
              );
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00C853), width: 3),
              ),
              child: const Center(
                child: Icon(Icons.add, color: Color(0xFF00C853), size: 18),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build user info (name & username)
  Widget _buildUserInfo(UserModel user) {
    return Column(
      children: [
        Text(
          user.fullName,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '@${user.username ?? 'user'}',
          style: const TextStyle(color: Colors.black87),
        ),
      ],
    );
  }

  /// Build stats row
  Widget _buildStatsRow(UserModel user) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatItem(
          value: _isLoadingPosts ? '...' : '${_userPosts.where((p) => !_deletedMediaIds.contains(p.id)).length}',
          label: 'Posts',
          onTap: () {
            setState(() {
              _selectedTab = 0;
            });
            _scrollToGrid();
          },
        ),
        _StatItem(
          value: _isLoadingReels ? '...' : '${_userReels.where((r) => !_deletedMediaIds.contains(r.id)).length}',
          label: 'Reels',
          onTap: () {
            setState(() {
              _selectedTab = 1;
            });
            _scrollToGrid();
          },
        ),
        _StatItem(
          value: _isLoadingFollowers ? '...' : _followersCount.toString(),
          label: 'Followers',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FollowersScreen(userId: user.id)),
            );
            if (mounted) {
              await _loadFollowersCounts();
            }
          },
        ),
        _StatItem(
          value: _isLoadingFollowing ? '...' : _followingCount.toString(),
          label: 'Following',
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => FollowingScreen(userId: user.id)),
            );
            if (mounted) {
              await _loadFollowersCounts();
            }
          },
        ),
      ],
    );
  }

  /// Build bio section
  Widget _buildBio(UserModel user) {
    return Text(
      user.bio == null || user.bio!.isEmpty
          ? 'Write something about yourself'
          : user.bio!,
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.grey.shade700, height: 1.4),
    );
  }

  /// Build tabs
  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              label: 'Posts',
              icon: Icons.yard_outlined,
              isSelected: _selectedTab == 0,
              onTap: () {
                setState(() {
                  _selectedTab = 0;
                });
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Reels',
              icon: Icons.play_circle_outline,
              isSelected: _selectedTab == 1,
              onTap: () {
                setState(() {
                  _selectedTab = 1;
                });
                _scrollToGrid();
              },
            ),
          ),
          Expanded(
            child: _TabButton(
              label: 'Tagged',
              icon: Icons.book_outlined,
              isSelected: _selectedTab == 2,
              onTap: () {
                setState(() {
                  _selectedTab = 2;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build grid based on selected tab
  Widget _buildGrid() {
    return Container(
      key: _gridSectionKey,
      child: _selectedTab == 0
          ? _buildPostsGrid()
          : _selectedTab == 1
              ? _buildReelsGrid()
              : _buildTaggedGrid(),
    );
  }

  /// Build posts grid
  Widget _buildPostsGrid() {
    if (_isLoadingPosts) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredPosts = _userPosts
        .where((post) => !_deletedMediaIds.contains(post.id))
        .toList();

    if (filteredPosts.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.post_add, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No posts yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Share your first post!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: filteredPosts.length,
      itemBuilder: (context, index) => _gridTile(filteredPosts[index]),
    );
  }

  /// Build reels grid
  Widget _buildReelsGrid() {
    if (_isLoadingReels) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final filteredReels = _userReels
        .where((reel) => !_deletedMediaIds.contains(reel.id))
        .toList();

    if (filteredReels.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'No reels yet',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Share your first reel!',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemCount: filteredReels.length,
      itemBuilder: (context, index) => _gridTile(filteredReels[index]),
    );
  }

  /// Build tagged grid
  Widget _buildTaggedGrid() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.book_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No tagged content yet',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  /// Build grid tile
  Widget _gridTile(Post post) {
    final isVideo = (post.type == PostType.video || post.type == PostType.reel) &&
        (post.videoUrl != null && post.videoUrl!.isNotEmpty);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostSliderScreen(
              posts: [post],
              initialIndex: 0,
            ),
          ),
        );
      },
      onLongPress: () => _maybeShowDeleteOptions(post),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (isVideo)
              _buildVideoThumbnail(post)
            else
              _buildImageTile(post),
            if (isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build video thumbnail
  Widget _buildVideoThumbnail(Post post) {
    return Container(
      color: Colors.black,
      child: post.thumbnailUrl != null
          ? Image.network(
              post.thumbnailUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) =>
                  post.imageUrl != null
                      ? Image.network(
                          post.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stack) =>
                              Container(color: Colors.black),
                        )
                      : Container(color: Colors.black),
            )
          : post.imageUrl != null
              ? Image.network(
                  post.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) =>
                      Container(color: Colors.black),
                )
              : Container(color: Colors.black),
    );
  }

  /// Build image tile
  Widget _buildImageTile(Post post) {
    if (post.imageUrl == null || post.imageUrl!.isEmpty) {
      return Container(
        color: Colors.grey.shade300,
        child: const Center(
          child: Icon(Icons.image_not_supported, color: Colors.grey, size: 28),
        ),
      );
    }

    return Image.network(
      post.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stack) {
        // Mark as deleted on error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _deletedMediaIds.add(post.id);
            });
          }
        });
        return Container(
          color: Colors.grey.shade300,
          child: const Center(
            child: Icon(Icons.broken_image, color: Colors.grey, size: 28),
          ),
        );
      },
    );
  }

  /// Show delete options for post
  void _maybeShowDeleteOptions(Post post) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = auth.userProfile?.id;
    final ownerId = post.userId;
    
    if (currentUserId == null) return;
    if (ownerId != currentUserId && ownerId != 'current_user') return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Delete'),
                  onTap: () {
                    Navigator.pop(context);
                    _confirmDelete(post);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Confirm delete dialog
  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete'),
        content: const Text('Are you sure you want to delete this media?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deletePost(post);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Delete post
  Future<void> _deletePost(Post post) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final token = auth.authToken;
      
      if (token == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to delete')),
          );
        }
        return;
      }

      // Immediately add to deleted set for instant UI update
      setState(() {
        _deletedMediaIds.add(post.id);
      });

      // Determine if it's a post or reel
      final isReel = post.type == PostType.reel || post.isReel == true;

      if (isReel) {
        final response = await ReelsManagementService.deleteReel(
          token: token,
          reelId: post.id,
        );

        if (mounted) {
          if (response.success) {
            setState(() {
              _userReels.removeWhere((reel) => reel.id == post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            setState(() {
              _deletedMediaIds.remove(post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        final response = await PostsManagementService.deletePost(
          token: token,
          postId: post.id,
        );

        if (mounted) {
          if (response.success) {
            setState(() {
              _userPosts.removeWhere((p) => p.id == post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );
          } else {
            setState(() {
              _deletedMediaIds.remove(post.id);
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(response.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _deletedMediaIds.remove(post.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      debugPrint('ProfileUI: Delete error: $e');
    }
  }

  /// Show logout dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.logout,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performLogout(context);
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Perform logout
  Future<void> _performLogout(BuildContext context) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      if (context.mounted) {
        SnackBarHelper.showInfo(context, 'Logging out...');
      }

      await authProvider.logout();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Logout failed: ${e.toString()}');
      }
      debugPrint('ProfileUI: Logout error: $e');
    }
  }

  /// Navigate to edit profile
  Future<void> _navigateToEditProfile(UserModel user) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileEditScreen(user: user),
      ),
    );

    if (result == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  /// Build spiritual symbols overlay
  Widget _buildSpiritualSymbolsOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: SpiritualSymbolsPainter(),
      ),
    );
  }
}

// Spiritual symbols painter
class SpiritualSymbolsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    _drawOm(canvas, size, paint);
    _drawCross(canvas, size, paint);
    _drawStarOfDavid(canvas, size, paint);
    _drawCrescent(canvas, size, paint);
    _drawLotus(canvas, size, paint);
    _drawPeaceSymbol(canvas, size, paint);
  }

  void _drawOm(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final center = Offset(size.width * 0.2, size.height * 0.3);
    final radius = 20.0;

    path.addOval(Rect.fromCircle(center: center, radius: radius));
    canvas.drawPath(path, paint);
  }

  void _drawCross(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.8, size.height * 0.2);
    final length = 30.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - length),
      Offset(center.dx, center.dy + length),
      paint,
    );

    canvas.drawLine(
      Offset(center.dx - length, center.dy),
      Offset(center.dx + length, center.dy),
      paint,
    );
  }

  void _drawStarOfDavid(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.7, size.height * 0.6);
    final radius = 25.0;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60.0) * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrescent(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.3, size.height * 0.7);
    final radius = 20.0;

    final path = Path();
    path.addArc(
      Rect.fromCircle(center: center, radius: radius),
      0.5 * pi,
      pi,
    );
    canvas.drawPath(path, paint);
  }

  void _drawLotus(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.5, size.height * 0.8);
    final radius = 15.0;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45.0) * (pi / 180);
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      final petalPath = Path();
      petalPath.addOval(Rect.fromCircle(center: Offset(x, y), radius: 8));
      canvas.drawPath(petalPath, paint);
    }
  }

  void _drawPeaceSymbol(Canvas canvas, Size size, Paint paint) {
    final center = Offset(size.width * 0.1, size.height * 0.5);
    final radius = 25.0;

    canvas.drawCircle(center, radius, paint);

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawLine(
      Offset(center.dx, center.dy - radius),
      Offset(center.dx, center.dy + radius),
      linePaint,
    );

    final diagonalLength = radius * 0.7;
    canvas.drawLine(
      center,
      Offset(center.dx - diagonalLength, center.dy - diagonalLength),
      linePaint,
    );
    canvas.drawLine(
      center,
      Offset(center.dx + diagonalLength, center.dy - diagonalLength),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Stat item widget
class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const _StatItem({
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black),
          ),
        ],
      ),
    );
  }
}

// Tab button widget
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool highlight;
  final VoidCallback? onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    this.isSelected = false,
    this.highlight = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (highlight) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF59B6AC),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Connect & Follow',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFBFDFED) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          boxShadow: isSelected
              ? const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade700,
            ),
          ),
        ),
      ),
    );
  }
}
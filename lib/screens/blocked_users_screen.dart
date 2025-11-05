import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../utils/avatar_utils.dart';
import 'user_profile_screen.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _isLoading = false;
  bool _isUnblocking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please login to view blocked users';
        });
        return;
      }

      final response = await ApiService.getBlockedUsers(token: token);

      if (mounted) {
        if (response['success'] == true && response['data'] != null) {
          final blockedUsers = response['data']['blockedUsers'] as List?;
          setState(() {
            _blockedUsers = blockedUsers?.cast<Map<String, dynamic>>() ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = response['message'] ?? 'Failed to load blocked users';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error loading blocked users: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _unblockUser(String userId, String username) async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.authToken;

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login to unblock users'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Unblock User'),
          content: Text('Are you sure you want to unblock $username?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unblock'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      setState(() {
        _isUnblocking = true;
      });

      final response = await ApiService.unblockUser(
        userId: userId,
        token: token,
      );

      if (mounted) {
        setState(() {
          _isUnblocking = false;
        });

        if (response['success'] == true) {
          // Remove from local list
          setState(() {
            _blockedUsers.removeWhere((user) => user['_id'] == userId);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$username has been unblocked'),
              backgroundColor: const Color(0xFF6366F1),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to unblock user'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUnblocking = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        title: const Text(
          'Blocked Users',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (_isLoading || _isUnblocking)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            )
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadBlockedUsers,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.block,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No blocked users',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF666666),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Users you block will appear here',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadBlockedUsers,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _blockedUsers.length,
                        itemBuilder: (context, index) {
                          final user = _blockedUsers[index];
                          final userId = user['_id'] as String? ?? '';
                          final username = user['username'] as String? ?? 'Unknown';
                          final fullName = user['fullName'] as String? ?? username;
                          final avatar = user['avatar'] as String?;

                          return ListTile(
                            leading: avatar != null && avatar.isNotEmpty && avatar != 'null'
                                ? CircleAvatar(
                                    radius: 24,
                                    backgroundImage: NetworkImage(avatar),
                                    onBackgroundImageError: (_, __) {},
                                    child: avatar.isEmpty
                                        ? AvatarUtils.buildDefaultAvatar(
                                            name: fullName,
                                            size: 48,
                                          )
                                        : null,
                                  )
                                : AvatarUtils.buildDefaultAvatar(
                                    name: fullName,
                                    size: 48,
                                  ),
                            title: Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              '@$username',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: TextButton(
                              onPressed: _isUnblocking
                                  ? null
                                  : () => _unblockUser(userId, username),
                              child: const Text(
                                'Unblock',
                                style: TextStyle(
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfileScreen(
                                    userId: userId,
                                    username: username,
                                    fullName: fullName,
                                    avatar: avatar ?? '',
                                    bio: user['bio'] as String? ?? '',
                                    followersCount: user['followersCount'] as int? ?? 0,
                                    followingCount: user['followingCount'] as int? ?? 0,
                                    postsCount: user['postsCount'] as int? ?? 0,
                                    isPrivate: user['isPrivate'] as bool? ?? false,
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}



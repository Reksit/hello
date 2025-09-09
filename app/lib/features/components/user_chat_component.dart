import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../auth/providers/auth_provider.dart';
import '../common/providers/toast_provider.dart';
import '../common/widgets/glass_card.dart';
import '../common/widgets/gradient_button.dart';
import '../common/widgets/loading_widget.dart';
import '../common/widgets/professional_input.dart';
import '../services/activity_service.dart';
import '../services/chat_service.dart';

class UserChatComponent extends ConsumerStatefulWidget {
  const UserChatComponent({super.key});

  @override
  ConsumerState<UserChatComponent> createState() => _UserChatComponentState();
}

class _UserChatComponentState extends ConsumerState<UserChatComponent> {
  final ChatService _chatService = ChatService();
  final ActivityService _activityService = ActivityService();
  
  List<dynamic> _conversations = [];
  List<dynamic> _allUsers = [];
  List<dynamic> _filteredUsers = [];
  Map<String, dynamic>? _selectedUser;
  List<dynamic> _messages = [];
  bool _loading = false;
  bool _showUserDropdown = false;
  
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  final ScrollController _messagesScrollController = ScrollController();
  
  String _searchQuery = '';
  String _selectedFilter = 'all';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _searchController.dispose();
    _messagesScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadConversations(),
      _loadAllUsers(),
    ]);
  }

  Future<void> _loadConversations() async {
    try {
      final response = await _chatService.getConversations();
      setState(() => _conversations = response);
    } catch (error) {
      print('Failed to load conversations: $error');
    }
  }

  Future<void> _loadAllUsers() async {
    try {
      final response = await _chatService.getAllUsers();
      setState(() {
        _allUsers = response;
        _filterUsers();
      });
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        'Failed to load users for chat',
        ToastType.error,
      );
    }
  }

  void _filterUsers() {
    final currentUser = ref.read(authProvider).user;
    List<dynamic> filtered = _allUsers.where((user) => user['id'] != currentUser?.id).toList();

    // Filter by role
    if (_selectedFilter != 'all') {
      filtered = filtered.where((user) {
        return user['role'].toString().toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    // Filter by search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((user) {
        return user['name'].toString().toLowerCase().contains(query) ||
            user['email'].toString().toLowerCase().contains(query) ||
            (user['department']?.toString().toLowerCase().contains(query) ?? false);
      }).toList();
    }

    setState(() => _filteredUsers = filtered);
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
    _filterUsers();
  }

  Future<void> _selectUser(Map<String, dynamic> user) async {
    setState(() {
      _selectedUser = user;
      _showUserDropdown = false;
    });
    
    _searchController.clear();
    setState(() => _searchQuery = '');
    
    // Load chat history
    try {
      final response = await _chatService.getChatHistory(user['id']);
      setState(() => _messages = response);
      
      // Mark messages as read
      await _chatService.markMessagesAsRead(user['id']);
      
      // Update conversations
      _loadConversations();
      
      _scrollToBottom();
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _selectedUser == null || _loading) return;

    setState(() => _loading = true);
    
    try {
      final response = await _chatService.sendMessage({
        'receiverId': _selectedUser!['id'],
        'message': messageText,
      });

      setState(() {
        _messages.add(response);
      });
      
      _messageController.clear();
      _scrollToBottom();
      
      // Update conversations
      _loadConversations();
      
      // Log activity
      final activityType = _selectedUser!['role'] == 'ALUMNI' ? 'ALUMNI_CHAT' : 
                          _selectedUser!['role'] == 'PROFESSOR' ? 'PROFESSOR_CHAT' : 'ALUMNI_CHAT';
      try {
        await _activityService.logActivity(activityType, 'Sent message to ${_selectedUser!['name']}');
      } catch (e) {
        print('Failed to log chat activity: $e');
      }
      
      ref.read(toastProvider.notifier).showToast(
        'Message sent successfully!',
        ToastType.success,
      );
    } catch (error) {
      ref.read(toastProvider.notifier).showToast(
        error.toString().replaceFirst('Exception: ', ''),
        ToastType.error,
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_messagesScrollController.hasClients) {
        _messagesScrollController.animateTo(
          _messagesScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'student':
        return AppTheme.primaryColor;
      case 'professor':
        return AppTheme.successColor;
      case 'alumni':
        return AppTheme.secondaryColor;
      case 'management':
        return AppTheme.errorColor;
      default:
        return AppTheme.textMuted;
    }
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inHours < 24) {
        return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[date.weekday - 1];
      } else {
        return '${date.day}/${date.month}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.glowShadow,
                ),
                child: const Icon(
                  Icons.message,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Messages',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Connect with students, alumni, and faculty',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Chat interface
        Expanded(
          child: Row(
            children: [
              // Conversations sidebar
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.35,
                child: Column(
                  children: [
                    // New chat button
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: GradientButton(
                        onPressed: () {
                          setState(() => _showUserDropdown = !_showUserDropdown);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 16),
                            const SizedBox(width: 4),
                            const Text('New Chat'),
                            const Icon(Icons.expand_more, size: 16),
                          ],
                        ),
                      ),
                    ),
                    
                    // User dropdown
                    if (_showUserDropdown) ...[
                      const SizedBox(height: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        constraints: const BoxConstraints(maxHeight: 200),
                        decoration: BoxDecoration(
                          color: AppTheme.darkSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.glassBorder),
                        ),
                        child: Column(
                          children: [
                            // Search and filter
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  ProfessionalInput(
                                    controller: _searchController,
                                    hintText: 'Search users...',
                                    prefixIcon: Icons.search,
                                    onChanged: _onSearchChanged,
                                  ),
                                  const SizedBox(height: 8),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: ['all', 'student', 'professor', 'alumni', 'management'].map((filter) {
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 4),
                                          child: FilterChip(
                                            label: Text(
                                              filter.toUpperCase(),
                                              style: const TextStyle(fontSize: 10),
                                            ),
                                            selected: _selectedFilter == filter,
                                            onSelected: (selected) {
                                              setState(() => _selectedFilter = filter);
                                              _filterUsers();
                                            },
                                            selectedColor: AppTheme.primaryColor.withOpacity(0.3),
                                            backgroundColor: AppTheme.glassBackground,
                                            labelStyle: TextStyle(
                                              color: _selectedFilter == filter ? AppTheme.primaryColor : AppTheme.textMuted,
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Users list
                            Expanded(
                              child: _filteredUsers.isEmpty
                                  ? const Center(
                                      child: Text(
                                        'No users found',
                                        style: TextStyle(
                                          color: AppTheme.textMuted,
                                          fontSize: 12,
                                        ),
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredUsers.length,
                                      itemBuilder: (context, index) {
                                        final user = _filteredUsers[index];
                                        return ListTile(
                                          dense: true,
                                          leading: Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: _getRoleColor(user['role']),
                                              borderRadius: BorderRadius.circular(16),
                                            ),
                                            child: const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                          title: Text(
                                            user['name'] ?? 'Unknown',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          subtitle: Text(
                                            '${user['role']} • ${user['department'] ?? 'Unknown'}',
                                            style: TextStyle(
                                              color: _getRoleColor(user['role']),
                                              fontSize: 10,
                                            ),
                                          ),
                                          onTap: () => _selectUser(user),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Conversations list
                    Expanded(
                      child: _conversations.isEmpty
                          ? const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.message,
                                    size: 48,
                                    color: AppTheme.textMuted,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'No conversations yet',
                                    style: TextStyle(
                                      color: AppTheme.textMuted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              itemCount: _conversations.length,
                              itemBuilder: (context, index) {
                                final conversation = _conversations[index];
                                final user = conversation['user'];
                                final isSelected = _selectedUser?['id'] == user['id'];
                                
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppTheme.primaryColor.withOpacity(0.2)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: isSelected 
                                        ? Border.all(color: AppTheme.primaryColor.withOpacity(0.5))
                                        : null,
                                  ),
                                  child: ListTile(
                                    dense: true,
                                    leading: Container(
                                      width: 32,
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user['role']),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    ),
                                    title: Text(
                                      user['name'] ?? 'Unknown',
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      user['role'] ?? 'Unknown',
                                      style: TextStyle(
                                        color: _getRoleColor(user['role']),
                                        fontSize: 10,
                                      ),
                                    ),
                                    onTap: () => _selectUser(user),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Chat panel
              Expanded(
                flex: 2,
                child: _selectedUser == null
                    ? GlassCard(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.message,
                              size: 64,
                              color: AppTheme.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Select a Conversation',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Choose a conversation from the sidebar or start a new chat.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GlassCard(
                        margin: const EdgeInsets.only(right: 8),
                        child: Column(
                          children: [
                            // Chat header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(color: AppTheme.glassBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _getRoleColor(_selectedUser!['role']),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _selectedUser!['name'] ?? 'Unknown',
                                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _selectedUser!['email'] ?? '',
                                          style: const TextStyle(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          '${_selectedUser!['role']} • ${_selectedUser!['department'] ?? 'Unknown'}',
                                          style: TextStyle(
                                            color: _getRoleColor(_selectedUser!['role']),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Messages
                            Expanded(
                              child: _messages.isEmpty
                                  ? const Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.message,
                                            size: 48,
                                            color: AppTheme.textMuted,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'No messages yet. Start the conversation!',
                                            style: TextStyle(
                                              color: AppTheme.textMuted,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      controller: _messagesScrollController,
                                      padding: const EdgeInsets.all(12),
                                      itemCount: _messages.length,
                                      itemBuilder: (context, index) {
                                        final message = _messages[index];
                                        return _buildMessageBubble(message);
                                      },
                                    ),
                            ),
                            
                            // Input
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: AppTheme.glassBorder),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _messageController,
                                      style: const TextStyle(color: AppTheme.textPrimary),
                                      decoration: InputDecoration(
                                        hintText: 'Type your message...',
                                        hintStyle: const TextStyle(color: AppTheme.textMuted),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppTheme.glassBorder),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppTheme.glassBorder),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                                        ),
                                        filled: true,
                                        fillColor: AppTheme.glassBackground,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      onSubmitted: (_) => _sendMessage(),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: AppTheme.primaryGradient,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: _loading ? null : _sendMessage,
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Icon(
                                          Icons.send,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final currentUser = ref.read(authProvider).user;
    final isCurrentUser = message['senderId'] == currentUser?.id;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getRoleColor(_selectedUser!['role']),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 12,
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.4,
              ),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: isCurrentUser ? AppTheme.primaryGradient : null,
                color: isCurrentUser ? null : AppTheme.glassBackground,
                borderRadius: BorderRadius.circular(12),
                border: isCurrentUser ? null : Border.all(color: AppTheme.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message['message'] ?? '',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : AppTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message['timestamp'] ?? ''),
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white70 : AppTheme.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (isCurrentUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
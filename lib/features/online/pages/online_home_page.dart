import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../contacts/models/contact.dart';
import '../../../core/config/online_config.dart';

class OnlineHomePage extends StatefulWidget {
  final void Function(Contact contact) onMessage;
  final int currentUserId;

  const OnlineHomePage({
    super.key,
    required this.onMessage,
    required this.currentUserId,
  });

  @override
  State<OnlineHomePage> createState() => _OnlineHomePageState();
}

class _OnlineHomePageState extends State<OnlineHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  List<_OnlineUser> _users = [];
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalUsers = 0;
  Timer? _debounceTimer;
  Timer? _presenceTimer;
  String _currentQuery = '';
  final Map<String, StreamSubscription<DatabaseEvent>> _presenceSubscriptions = {};

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _loadUsers();

    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _refreshPresence(),
    );
  }

  @override
  void dispose() {
    _presenceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _stopAllPresenceListeners();
    super.dispose();
  }

  void _stopAllPresenceListeners() {
    for (final sub in _presenceSubscriptions.values) {
      sub.cancel();
    }
    _presenceSubscriptions.clear();
  }

  void _onSearchChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.trim();
      if (query != _currentQuery) {
        _currentQuery = query;
        _currentPage = 1;
        _loadUsers();
      }
    });
  }

  /// Polls presence from the server.
  ///
  /// Realtime Database presence only covers accounts that signed in
  /// through Firebase Auth. Google-OAuth accounts have no
  /// `firebase_uid`, so no realtime listener ever attaches for them and
  /// the list would keep showing whatever status was true at first
  /// load - users would never visibly go offline. The WebSocket sets
  /// `online` in Postgres, so a light periodic re-read is what keeps the
  /// dots honest.
  Future<void> _refreshPresence() async {
    if (!mounted || _loading || _error != null) return;

    try {
      final uri = Uri.parse('${OnlineConfig.serverUrl}/users')
          .replace(queryParameters: <String, String>{
        'page': _currentPage.toString(),
        'page_size': '20',
        'q': _currentQuery,
      });

      final response = await http.get(uri);
      if (response.statusCode != 200) return;

      final decoded = jsonDecode(response.body);

      final fresh = (decoded['users'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_OnlineUser.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        for (int i = 0; i < _users.length; i++) {
          final _OnlineUser existing = _users[i];

          final _OnlineUser? updated = fresh
              .where((_OnlineUser u) => u.id == existing.id)
              .firstOrNull;

          if (updated != null &&
              (updated.online != existing.online ||
                  updated.lastSeen != existing.lastSeen)) {
            _users[i] = existing.copyWith(
              online: updated.online,
              lastSeen: updated.lastSeen,
            );
          }
        }
      });
    } catch (_) {
      // Presence refresh is best effort; a failed poll just means the
      // next one will try again.
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_loadingMore && _currentPage < _totalPages) {
        _loadMore();
      }
    }
  }

  Future<void> _loadUsers() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    _stopAllPresenceListeners();

    try {
      final uri = Uri.parse('${OnlineConfig.serverUrl}/users').replace(queryParameters: {
        'page': _currentPage.toString(),
        'page_size': '20',
        'q': _currentQuery,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      final users = (decoded['users'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_OnlineUser.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _users = users;
        _totalPages = decoded['total_pages'] as int? ?? 1;
        _totalUsers = decoded['total'] as int? ?? 0;
        _loading = false;
      });

      _startPresenceListeners();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = 'Could not load users.\n$e';
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _totalPages) return;

    setState(() => _loadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final uri = Uri.parse('${OnlineConfig.serverUrl}/users').replace(queryParameters: {
        'page': nextPage.toString(),
        'page_size': '20',
        'q': _currentQuery,
      });

      final response = await http.get(uri);

      if (response.statusCode != 200) {
        throw Exception('Server returned ${response.statusCode}');
      }

      final decoded = jsonDecode(response.body);

      final moreUsers = (decoded['users'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(_OnlineUser.fromJson)
          .toList();

      if (!mounted) return;

      setState(() {
        _users.addAll(moreUsers);
        _currentPage = nextPage;
        _loadingMore = false;
      });

      _startPresenceListeners();
    } catch (e) {
      if (!mounted) return;

      setState(() => _loadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _currentPage = 1;
    await _loadUsers();
  }

  void _startPresenceListeners() {
    _stopAllPresenceListeners();

    for (final user in _users) {
      if (user.firebaseUid.isEmpty) continue;

      final presenceRef = _dbRef.child('users/${user.firebaseUid}/presence');
      final subscription = presenceRef.onValue.listen((event) {
        if (!mounted) return;

        final data = event.snapshot.value;
        if (data is Map) {
          final isOnline = (data['online'] as bool?) ?? false;
          setState(() {
            final idx = _users.indexWhere((u) => u.firebaseUid == user.firebaseUid);
            if (idx >= 0) {
              _users[idx] = _users[idx].copyWith(online: isOnline);
            }
          });
        }
      });

      _presenceSubscriptions[user.firebaseUid] = subscription;
    }
  }

  Contact _toContact(_OnlineUser user) {
    return Contact(
      id: user.id.toString(),
      name: user.name.isEmpty ? 'PULSAR User' : user.name,
      lastMessage: '',
      lastSeen: user.online ? 'Online' : 'Offline',
      online: user.online,
      // Carried so the Firebase fallback and any presence work for
      // accounts that actually have one. Previously this was always
      // null, so every fallback silently did nothing.
      firebaseUid: user.firebaseUid,
    );
  }

  String _lastSeenText(_OnlineUser user) {
    if (user.online) {
      return 'Online';
    }

    if (user.lastSeen == null || user.lastSeen!.isEmpty) {
      return 'Offline';
    }

    try {
      final lastSeen = DateTime.parse(user.lastSeen!).toLocal();
      final difference = DateTime.now().difference(lastSeen);

      if (difference.isNegative) {
        return 'Offline';
      }

      if (difference.inMinutes < 1) {
        return 'Last seen just now';
      }

      if (difference.inMinutes < 60) {
        return 'Last seen ${difference.inMinutes}m ago';
      }

      if (difference.inHours < 24) {
        return 'Last seen ${difference.inHours}h ago';
      }

      if (difference.inDays < 7) {
        return 'Last seen ${difference.inDays}d ago';
      }

      return 'Last seen '
          '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    } catch (_) {
      return 'Offline';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearch(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        26,
        28,
        12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Discover Users',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 27,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _totalUsers > 0
                      ? '$_totalUsers users on PULSAR Online'
                      : 'Find people on PULSAR Online',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: (_loading || _loadingMore) ? null : _refresh,
            tooltip: 'Refresh users',
            icon: const Icon(
              Icons.refresh_rounded,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        28,
        8,
        28,
        18,
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
          color: Colors.white,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          hintStyle: const TextStyle(
            color: Colors.white38,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.white54,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    _currentQuery = '';
                    _currentPage = 1;
                    _loadUsers();
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: Colors.white54,
                  ),
                ),
          filled: true,
          fillColor: const Color(0xFF182235),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: Colors.white38,
                size: 48,
              ),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white60,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _refresh,
                icon: const Icon(
                  Icons.refresh_rounded,
                ),
                label: const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.person_search_rounded,
              color: Colors.white30,
              size: 58,
            ),
            const SizedBox(height: 14),
            Text(
              _currentQuery.isEmpty
                  ? 'No PULSAR users found'
                  : 'No users found for "$_currentQuery"',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(
          28,
          0,
          28,
          28,
        ),
        itemCount: _users.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(_OnlineUser user) {
    final displayName = user.name.isEmpty
        ? 'PULSAR User'
        : user.name;

    return Container(
      margin: const EdgeInsets.only(
        bottom: 10,
      ),
      // The entire row opens the conversation. Previously only the
      // "Message" button did, which made the card look tappable but
      // silently expand the directory instead.
      decoration: BoxDecoration(
        color: const Color(0xFF182235),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(17),
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: () => widget.onMessage(_toContact(user)),
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              children: [
                _buildAvatar(user),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email.isEmpty
                            ? 'No email available'
                            : user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: user.online
                                  ? Colors.greenAccent
                                  : Colors.white
                                      .withValues(alpha: 0.24),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _lastSeenText(user),
                            style: TextStyle(
                              color: user.online
                                  ? Colors.greenAccent
                                  : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white38,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(_OnlineUser user) {
    if (user.picture.isNotEmpty) {
      return CircleAvatar(
        radius: 27,
        backgroundImage: NetworkImage(
          user.picture,
        ),
        backgroundColor: const Color(0xFF273449),
      );
    }

    final name = user.name.trim();

    final letter = name.isEmpty
        ? '?'
        : name.substring(0, 1).toUpperCase();

    return CircleAvatar(
      radius: 27,
      backgroundColor: const Color(0xFF273449),
      child: Text(
        letter,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 19,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _OnlineUser {
  final int id;
  final String googleId;
  final String email;
  final String name;
  final String picture;
  final bool online;
  final String? lastSeen;
  final String firebaseUid;

  const _OnlineUser({
    required this.id,
    required this.googleId,
    required this.email,
    required this.name,
    required this.picture,
    required this.online,
    required this.lastSeen,
    required this.firebaseUid,
  });

  factory _OnlineUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return _OnlineUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      googleId:
          json['google_id']?.toString() ?? '',
      email:
          json['email']?.toString() ?? '',
      name:
          json['name']?.toString() ?? '',
      picture:
          json['picture']?.toString() ?? '',
      online:
          json['online'] == true,
      lastSeen:
          json['last_seen']?.toString(),
      firebaseUid:
          json['firebase_uid']?.toString() ?? '',
    );
  }

  _OnlineUser copyWith({bool? online, String? lastSeen}) {
    return _OnlineUser(
      id: id,
      googleId: googleId,
      email: email,
      name: name,
      picture: picture,
      online: online ?? this.online,
      lastSeen: lastSeen ?? this.lastSeen,
      firebaseUid: firebaseUid,
    );
  }
}

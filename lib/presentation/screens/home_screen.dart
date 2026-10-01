import 'package:flutter/material.dart';
import '../../core/services/google_auth_service.dart';

/// The main navigation shell for PRAVIN.
/// Adapts layout based on screen size:
/// - Mobile (< 768px): Bottom navigation bar
/// - Desktop (>= 768px): Navigation rail on the left
class HomeScreen extends StatefulWidget {
  final Widget child;

  const HomeScreen({super.key, required this.child});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GoogleAuthService _authService = GoogleAuthService();
  bool _isSignedIn = false;
  String? _authError;

  @override
  void initState() {
    super.initState();
    _authService.onCurrentUserChanged.listen((account) {
      if (mounted) {
        setState(() {
          _isSignedIn = account != null;
          _authError = null;
        });
      }
    });
    final user = _authService.currentUser;
    if (user != null && mounted) {
      setState(() {
        _isSignedIn = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PRAVIN'),
        centerTitle: false,
        actions: [
          if (_isSignedIn)
            TextButton.icon(
              onPressed: () async {
                await _authService.signOut();
                if (mounted) {
                  setState(() {
                    _isSignedIn = false;
                  });
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Sign out', style: TextStyle(fontSize: 12)),
            ),
          if (!_isSignedIn)
            TextButton.icon(
              onPressed: () async {
                try {
                  final user = await _authService.signIn();
                  if (mounted) {
                    setState(() {
                      _isSignedIn = user != null;
                      _authError = null;
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _authError = e.toString();
                    });
                  }
                }
              },
              icon: const Icon(Icons.login, size: 18),
              label: const Text('Sign in', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      bottomNavigationBar: _isDesktop(context)
          ? null
          : BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
                _navigateToIndex(context, index);
              },
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: 'Chat',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.task_alt),
                  label: 'Tasks',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.calendar_today),
                  label: 'Calendar',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.note_add),
                  label: 'Notes',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.schedule),
                  label: 'Planning',
                ),
              ],
            ),
      drawer: _isDesktop(context) ? _buildDrawer(context) : null,
      body: Row(
        children: [
          if (_isDesktop(context)) _buildNavigationRail(context),
          Expanded(
            child: widget.child,
          ),
        ],
      ),
    );
  }

  bool _isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= 768;
  }

  Widget _buildNavigationRail(BuildContext context) {
    return NavigationRail(
      selectedIndex: _currentIndex,
      onDestinationSelected: (index) {
        setState(() {
          _currentIndex = index;
        });
        _navigateToIndex(context, index);
      },
      minWidth: 100,
      minExtendedWidth: 300,
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.chat),
          label: Text('Chat'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.task_alt),
          label: Text('Tasks'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.calendar_today),
          label: Text('Calendar'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.note_add),
          label: Text('Notes'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.schedule),
          label: Text('Planning'),
        ),
      ],
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.deepPurple,
            ),
            child: Text(
              'PRAVIN',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          _buildDrawerItem(context, Icons.chat, 'Chat', '/chat'),
          _buildDrawerItem(context, Icons.task_alt, 'Tasks', '/tasks'),
          _buildDrawerItem(context, Icons.calendar_today, 'Calendar', '/calendar'),
          _buildDrawerItem(context, Icons.note_add, 'Notes', '/notes'),
          _buildDrawerItem(context, Icons.schedule, 'Planning', '/planning'),
          if (_isSignedIn)
            const Divider(),
          if (_isSignedIn)
            ListTile(
              leading: const Icon(Icons.cloud_done, color: Colors.green),
              title: const Text('Google Sync Connected'),
              subtitle: Text(_authError ?? 'Active'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_authError ?? 'Google account connected'),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
  ) {
    final isActive = _currentIndex == _routeToIndex(route);
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      selected: isActive,
      onTap: () {
        if (!isActive) {
          setState(() {
            _currentIndex = _routeToIndex(route);
          });
          Navigator.pop(context);
        }
      },
    );
  }

  int _routeToIndex(String route) {
    switch (route) {
      case '/chat':
        return 0;
      case '/tasks':
        return 1;
      case '/calendar':
        return 2;
      case '/notes':
        return 3;
      case '/planning':
        return 4;
      default:
        return 0;
    }
  }

  void _navigateToIndex(BuildContext context, int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
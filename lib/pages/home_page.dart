import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'profile_page.dart'; // Halaman profil
import '../widgets/bottom_navigation.dart'; // Bottom navigation bar
import 'photos_page.dart';
import 'search_page.dart';
import 'library_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  String _userName = "Loading...";
  String? _userImage;
  int _selectedIndex = 0;
  bool _isLoading = true; // Tambahkan indikator loading

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  /// Mengambil data user dari Supabase
  Future<void> _loadUserProfile() async {
    try {
      setState(() {
        _isLoading = true; // Mulai loading
      });

      final user = supabase.auth.currentUser;
      if (user != null) {
        final response =
            await supabase.from('profiles').select().eq('id', user.id).single();

        setState(() {
          _userName = response['full_name'] ?? "No Name";
          _userImage = response['profile_image_url'];
        });
      }
    } catch (error) {
      print('Error fetching user profile: $error');
      setState(() {
        _userName = "Error loading profile";
      });
    } finally {
      setState(() {
        _isLoading = false; // Selesai loading
      });
    }
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ProfilePage()),
    ).then((_) {
      _loadUserProfile(); // 🔄 Refresh data setelah kembali dari ProfilePage
    });
  }

  /// Logout pengguna dari aplikasi
  Future<void> _logout() async {
    await supabase.auth.signOut();
    Navigator.pushReplacementNamed(context, '/login'); // Arahkan ke login
  }

  /// Menangani perubahan halaman dari bottom navigation
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  /// Daftar halaman untuk bottom navigation
  static final List<Widget> _pages = [
    PhotosPage(),
    SearchPage(),
    LibraryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memoriku'),
        backgroundColor: Colors.yellow,
        actions: [
          PopupMenuButton<String>(
            icon: CircleAvatar(
              backgroundImage: _userImage != null && _userImage!.isNotEmpty
                  ? NetworkImage(_userImage!)
                  : AssetImage('assets/default_profile.png') as ImageProvider,
            ),
            itemBuilder: (BuildContext context) {
              return {'Set Profile', 'Logout'}.map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: ListTile(
                    leading: Icon(
                      choice == 'Set Profile'
                          ? Icons.account_circle
                          : Icons.logout,
                      color: Colors.black,
                    ),
                    title: Text(choice, style: TextStyle(color: Colors.black)),
                  ),
                );
              }).toList();
            },
            onSelected: (String value) {
              if (value == 'Set Profile') {
                _navigateToProfile(context);
              } else if (value == 'Logout') {
                _logout();
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Tampilkan loading
          : _pages[_selectedIndex], // Menampilkan halaman yang dipilih
      bottomNavigationBar: BottomNavigation(
        selectedIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}

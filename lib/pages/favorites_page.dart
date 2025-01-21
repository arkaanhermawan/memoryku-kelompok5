import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoritesPage extends StatefulWidget {
  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> favoritePhotos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoritePhotos();
  }

  /// Mengambil foto yang ditandai sebagai favorit dari Supabase
  Future<void> _loadFavoritePhotos() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await supabase
          .from('photos')
          .select('id, user_id, image_url, uploaded_at')
          .eq('user_id', userId)
          .eq('is_favorite', true); // Hanya ambil yang favorit

      setState(() {
        favoritePhotos = response
            .map((photo) => {
                  'id': photo['id'],
                  'url': photo['image_url'] ?? '',
                  'uploaded_at': photo['uploaded_at'] ?? '',
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading favorite photos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load favorites: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _removeFromFavorites(int index) async {
    final photo = favoritePhotos[index];
    final photoId = photo['id'];

    try {
      await supabase
          .from('photos')
          .update({'is_favorite': false}).eq('id', photoId);

      setState(() {
        favoritePhotos.removeAt(index); // Hapus dari tampilan favorit
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Removed from Favorites")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error removing from Favorites: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Favorites'),
        backgroundColor: Colors.yellow,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : favoritePhotos.isEmpty
              ? Center(child: Text('No favorite photos yet.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: favoritePhotos.length,
                  itemBuilder: (context, index) {
                    final photo = favoritePhotos[index];
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.yellow, width: 2),
                        borderRadius: BorderRadius.circular(10),
                        image: DecorationImage(
                          image: NetworkImage(photo['url']),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          color: Colors.black54,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              IconButton(
                                icon: Icon(Icons.favorite, color: Colors.red),
                                onPressed: () => _removeFromFavorites(index),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

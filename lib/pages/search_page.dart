import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _filteredPhotos = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  Future<void> _fetchPhotos({String query = ''}) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('photos')
          .select('id, user_id, image_url, uploaded_at, is_favorite, status')
          .eq('user_id', userId)
          .neq('status', 'trash'); // Jangan tampilkan foto di Trash

      List<Map<String, dynamic>> photos =
          List<Map<String, dynamic>>.from(response);

      setState(() {
        _filteredPhotos = photos.where((photo) {
          final uploadedAt = photo['uploaded_at'].toString();
          return uploadedAt.contains(query);
        }).toList();
      });
    } catch (e) {
      print('Error fetching photos: $e');
    }
  }

  void _onSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    _fetchPhotos(query: query);
  }

  Future<void> _updatePhotoStatus(int index, String newStatus) async {
    final photo = _filteredPhotos[index];
    final photoId = photo['id'];

    try {
      await supabase
          .from('photos')
          .update({'status': newStatus}).eq('id', photoId);
      setState(() {
        _filteredPhotos.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(newStatus == 'archive'
                ? 'Photo archived'
                : 'Photo moved to trash')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error updating photo: $e")));
    }
  }

  Future<void> _toggleFavorite(int index) async {
    final photo = _filteredPhotos[index];
    final photoId = photo['id'];
    final newFavoriteStatus = !(photo['is_favorite'] ?? false);

    try {
      await supabase
          .from('photos')
          .update({'is_favorite': newFavoriteStatus}).eq('id', photoId);
      setState(() {
        _filteredPhotos[index]['is_favorite'] = newFavoriteStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(newFavoriteStatus
                ? 'Added to Favorites'
                : 'Removed from Favorites')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error updating favorite status: $e")));
    }
  }

  Widget _buildSearchResults() {
    if (_filteredPhotos.isEmpty) {
      return Center(
        child: Text(
          'Tidak ada foto yang ditemukan.',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _filteredPhotos.length,
      itemBuilder: (context, index) {
        final photo = _filteredPhotos[index];
        return Card(
          color: Colors.grey.shade800,
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(photo['image_url']),
            ),
            title: Text(
              'Waktu: ${photo['uploaded_at']}',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    photo['is_favorite'] ?? false
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: photo['is_favorite'] ?? false
                        ? Colors.red
                        : Colors.white,
                  ),
                  onPressed: () => _toggleFavorite(index),
                ),
                IconButton(
                  icon: Icon(Icons.archive, color: Colors.white),
                  onPressed: () => _updatePhotoStatus(index, 'archive'),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.white),
                  onPressed: () => _updatePhotoStatus(index, 'trash'),
                ),
              ],
            ),
            onTap: () => _showPhotoDialog(photo),
          ),
        );
      },
    );
  }

  void _showPhotoDialog(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10), // Memberikan padding untuk dialog
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 1.0,
            maxScale: 4.0, // Mendukung zoom hingga 4x
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width * 0.8,
                    height: MediaQuery.of(context).size.height * 0.8,
                    child: Image.network(
                      photo['image_url'],
                      fit: BoxFit.contain, // Menjaga gambar tetap proporsional
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Uploaded at: ${photo['uploaded_at']}',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: TextField(
            onChanged: _onSearch,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey.shade900,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Cari foto berdasarkan waktu...',
              hintStyle: TextStyle(color: Colors.grey),
              prefixIcon: Icon(Icons.search, color: Colors.yellow),
            ),
            style: TextStyle(color: Colors.white),
          ),
        ),
        Expanded(
          child: _buildSearchResults(),
        ),
      ],
    );
  }
}

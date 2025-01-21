import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ArchivePage extends StatefulWidget {
  @override
  _ArchivePageState createState() => _ArchivePageState();
}

class _ArchivePageState extends State<ArchivePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> archivedPhotos = [];

  @override
  void initState() {
    super.initState();
    _loadArchivedPhotos();
  }

  Future<void> _loadArchivedPhotos() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await supabase
          .from('photos')
          .select('id, user_id, image_url, uploaded_at, is_favorite, status')
          .eq('user_id', userId)
          .eq('status',
              'archive'); // Filter hanya foto yang statusnya 'archive'

      setState(() {
        archivedPhotos = response
            .map((photo) => {
                  'id': photo['id'],
                  'url': photo['image_url'] ?? '',
                  'uploaded_at': photo['uploaded_at'] ?? '',
                  'liked': photo['is_favorite'] ?? false,
                  'status': photo['status'] ?? 'archive',
                })
            .toList();
      });
    } catch (e) {
      print("Error loading archived photos: $e");
      throw e;
    }
  }

  Future<void> _restorePhoto(int index, BuildContext context) async {
    final photo = archivedPhotos[index];
    final photoId = photo['id'];

    try {
      // Update status ke 'active'
      await supabase
          .from('photos')
          .update({'status': 'active'}).eq('id', photoId);

      // Hapus foto dari daftar dan perbarui UI
      setState(() {
        archivedPhotos.removeAt(index);
      });

      // Berikan feedback pengguna
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Photo restored to active status."),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error restoring photo: $e"),
      ));
    }
  }

  Future<void> _moveToTrash(int index, BuildContext context) async {
    final photo = archivedPhotos[index];
    final photoId = photo['id'];

    try {
      // Update status ke 'deleted'
      await supabase
          .from('photos')
          .update({'status': 'trash'}).eq('id', photoId);

      // Hapus foto dari daftar dan perbarui UI
      setState(() {
        archivedPhotos.removeAt(index);
      });

      // Berikan feedback pengguna
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Photo moved to Trash."),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Error moving photo to Trash: $e"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Archive'),
        backgroundColor: Colors.yellow,
      ),
      body: archivedPhotos.isEmpty
          ? Center(child: Text('No archived photos.'))
          : GridView.builder(
              padding: const EdgeInsets.all(10),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: archivedPhotos.length,
              itemBuilder: (context, index) {
                final photo = archivedPhotos[index];
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.yellow, width: 2),
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: photo['url'].isNotEmpty
                          ? NetworkImage(photo['url'])
                          : AssetImage('assets/placeholder.png')
                              as ImageProvider,
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
                            icon: Icon(Icons.unarchive, color: Colors.green),
                            onPressed: () => _restorePhoto(index, context),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () => _moveToTrash(index, context),
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

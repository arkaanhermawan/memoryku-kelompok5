import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrashPage extends StatefulWidget {
  @override
  _TrashPageState createState() => _TrashPageState();
}

class _TrashPageState extends State<TrashPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> trashPhotos = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrashPhotos();
  }

  /// Mengambil foto dengan status 'deleted' dari Supabase
  Future<void> _loadTrashPhotos() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await supabase
          .from('photos')
          .select('id, user_id, image_url, uploaded_at')
          .eq('user_id', userId)
          .eq('status', 'trash'); // Hanya ambil yang berstatus 'deleted'

      setState(() {
        trashPhotos = response
            .map((photo) => {
                  'id': photo['id'],
                  'url': photo['image_url'] ?? '',
                  'uploaded_at': photo['uploaded_at'] ?? '',
                })
            .toList();
        isLoading = false;
      });
    } catch (e) {
      print("Error loading trash photos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load trash: $e")),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _restorePhoto(int index) async {
    final photo = trashPhotos[index];
    final photoId = photo['id'];

    try {
      // Update status menjadi 'active' di Supabase
      await supabase
          .from('photos')
          .update({'status': 'active'}).eq('id', photoId);

      setState(() {
        trashPhotos.removeAt(index); // Hapus dari tampilan trash
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo restored successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error restoring photo: $e")),
      );
    }
  }

  Future<void> _deletePermanently(int index) async {
    final photo = trashPhotos[index];
    final photoId = photo['id'];

    try {
      debugPrint("Deleting photo from database with ID: $photoId");

      // Hapus foto dari database Supabase
      final deleteResponse = await supabase
          .from('photos')
          .delete()
          .eq('id', photoId)
          .select(); // Supabase mengembalikan data yang dihapus jika berhasil

      // Pastikan data benar-benar dihapus
      if (deleteResponse == null || deleteResponse.isEmpty) {
        throw Exception("Failed to delete photo: No data was deleted");
      }

      debugPrint("Database response after delete: $deleteResponse");

      // Hapus dari UI setelah sukses
      setState(() {
        trashPhotos.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo deleted permanently from database!")),
      );
    } catch (e) {
      debugPrint("Error during deletion: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting photo from database: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Trash'),
        backgroundColor: Colors.yellow,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : trashPhotos.isEmpty
              ? Center(child: Text('Trash is empty.'))
              : GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: trashPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = trashPhotos[index];
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
                                icon: Icon(Icons.restore, color: Colors.green),
                                onPressed: () => _restorePhoto(index),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deletePermanently(index),
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

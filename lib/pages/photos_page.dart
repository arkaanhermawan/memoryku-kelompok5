import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

class PhotosPage extends StatefulWidget {
  @override
  _PhotosPageState createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> photos = [];
  bool isUploading = false;
  String uploadMessage = '';
  bool isLoadingPhotos = true;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    try {
      setState(() {
        isLoadingPhotos = true;
      });

      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await supabase
          .from('photos')
          .select('id, user_id, image_url, uploaded_at, is_favorite, status')
          .eq('user_id', userId)
          .eq('status', 'active'); // Hanya foto aktif

      setState(() {
        photos = response
            .map((photo) => {
                  'id': photo['id'],
                  'url': photo['image_url'] ?? '',
                  'uploaded_at': photo['uploaded_at'] ?? '',
                  'liked': photo['is_favorite'] ?? false,
                  'status': photo['status'] ?? 'active',
                })
            .toList();
      });
    } catch (e) {
      print("Error loading photos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load photos: $e")),
      );
    } finally {
      setState(() {
        isLoadingPhotos = false;
      });
    }
  }

  Future<void> _addPhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      setState(() {
        isUploading = true;
        uploadMessage = 'Uploading...';
      });

      final Uint8List imageBytes = await pickedFile.readAsBytes();

      final userId = supabase.auth.currentUser?.id ?? 'guest';
      final fileName = '$userId-${DateTime.now().millisecondsSinceEpoch}.png';
      final filePath = 'user_photos/$fileName';

      await supabase.storage.from('photos').uploadBinary(
            filePath,
            imageBytes,
            fileOptions: const FileOptions(contentType: 'image/png'),
          );

      final publicUrl = supabase.storage.from('photos').getPublicUrl(filePath);

      await supabase.from('photos').insert({
        'user_id': userId,
        'image_url': publicUrl,
        'status': 'active',
      });

      await _loadPhotos();

      setState(() {
        isUploading = false;
        uploadMessage = 'Upload successful!';
      });
    } catch (e) {
      setState(() {
        isUploading = false;
        uploadMessage = 'Error uploading image: $e';
      });
    }
  }

  Future<void> _deletePhoto(int index) async {
    final photo = photos[index];
    final photoId = photo['id'];

    try {
      await supabase
          .from('photos')
          .update({'status': 'trash'}).eq('id', photoId);

      setState(() {
        photos.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo moved to Trash")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating photo status: $e")),
      );
    }
  }

  Future<void> _archivePhoto(int index) async {
    final photo = photos[index];
    final photoId = photo['id'];

    try {
      await supabase
          .from('photos')
          .update({'status': 'archive'}).eq('id', photoId);

      setState(() {
        photos.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Photo moved to Archive")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating photo status: $e")),
      );
    }
  }

  Future<void> _likePhoto(int index) async {
    final photo = photos[index];
    final photoId = photo['id'];

    try {
      final newFavoriteStatus = !(photo['liked'] ?? false);

      await supabase
          .from('photos')
          .update({'is_favorite': newFavoriteStatus}).eq('id', photoId);

      setState(() {
        photos[index]['liked'] = newFavoriteStatus;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newFavoriteStatus
              ? "Added to Favorites"
              : "Removed from Favorites"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating favorite status: $e")),
      );
    }
  }

  void _downloadImage(String imageUrl) async {
    final response = await html.HttpRequest.request(
      imageUrl,
      method: 'GET',
      responseType: 'blob',
    );

    final blob = response.response as html.Blob;
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "photo.png")
      ..style.display = "none"
      ..target = "_self"; // Tetap di halaman yang sama
    html.document.body?.append(anchor);
    anchor.click();
    anchor.remove(); // Gunakan ini untuk menggantikan removeChild
    html.Url.revokeObjectUrl(url);
  }

  void _showPhotoDialog(Map<String, dynamic> photo) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.all(10), // Padding untuk dialog
          child: InteractiveViewer(
            clipBehavior: Clip.none,
            minScale: 1.0,
            maxScale: 4.0, // Mendukung zoom hingga 4x
            child: Container(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.8,
                child: Image.network(
                  photo['url'],
                  fit: BoxFit.contain, // Menyesuaikan proporsi gambar
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPhotoGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => _showPhotoDialog(photo), // Menampilkan dialog interaktif
          child: Container(
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
                      icon: Icon(
                        photo['liked'] ? Icons.favorite : Icons.favorite_border,
                        color: photo['liked'] ? Colors.red : Colors.grey,
                      ),
                      onPressed: () => _likePhoto(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.archive, color: Colors.white),
                      onPressed: () => _archivePhoto(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      onPressed: () => _deletePhoto(index),
                    ),
                    IconButton(
                      icon: Icon(Icons.download, color: Colors.white),
                      onPressed: () => _downloadImage(photo['url']),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoadingPhotos
          ? Center(child: CircularProgressIndicator())
          : photos.isEmpty
              ? Center(child: Text('No photos uploaded yet.'))
              : _buildPhotoGrid(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        child: Icon(Icons.add),
        tooltip: 'Add Photo',
        backgroundColor: Colors.yellow,
      ),
    );
  }
}

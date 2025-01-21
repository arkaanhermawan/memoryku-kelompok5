import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  String userName = "Loading...";
  String? imageUrl;
  String? tempImageUrl; // Menyimpan sementara URL gambar sebelum disimpan
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        final response =
            await supabase.from('profiles').select().eq('id', user.id).single();
        setState(() {
          userName = response['full_name'] ?? "No Name";
          imageUrl = response['profile_image_url'];
          isLoading = false;
        });
      } catch (e) {
        print("Error loading profile: $e");
      }
    }
  }

  void _editProfile() {
    TextEditingController nameController =
        TextEditingController(text: userName);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text("Edit Profile"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    style: TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                        labelText: 'Edit Name',
                        labelStyle: TextStyle(color: Colors.black)),
                  ),
                  SizedBox(height: 10),
                  tempImageUrl != null
                      ? CircleAvatar(
                          radius: 40,
                          backgroundImage: NetworkImage(tempImageUrl!))
                      : Container(),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      await _pickImage();
                      setStateDialog(() {}); // Update tampilan di dialog
                    },
                    child: Text("Choose Image"),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await _updateProfile(nameController.text);
                    Navigator.pop(context);
                  },
                  child: Text("Save"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);
    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName =
          '${supabase.auth.currentUser!.id}_${result.files.first.name}';
      if (fileBytes != null) {
        final filePath = 'avatars/$fileName';
        try {
          await supabase.storage.from('avatars').uploadBinary(
              filePath, fileBytes,
              fileOptions: FileOptions(upsert: true));
          final publicUrl =
              supabase.storage.from('avatars').getPublicUrl(filePath);
          setState(() {
            tempImageUrl =
                publicUrl; // Simpan sementara, belum update langsung ke profil
          });
        } catch (e) {
          print("Error uploading image: $e");
        }
      }
    }
  }

  Future<void> _updateProfile(String newName) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      try {
        await supabase.from('profiles').update({
          'full_name': newName,
          'profile_image_url': tempImageUrl ?? imageUrl
        }).eq('id', user.id);
        setState(() {
          userName = newName;
          imageUrl = tempImageUrl ?? imageUrl;
        });
        print("Profile updated successfully.");
      } catch (e) {
        print("Error updating profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.yellow,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
                    ? NetworkImage(imageUrl!)
                    : AssetImage('assets/default_profile.png') as ImageProvider,
              ),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.yellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isLoading ? 'Loading...' : 'Username: $userName',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _editProfile,
              icon: Icon(Icons.edit),
              label: Text("Edit Profile"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

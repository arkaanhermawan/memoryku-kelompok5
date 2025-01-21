import 'package:flutter/material.dart';

class PhotoDetailPage extends StatelessWidget {
  final int photoIndex;

  PhotoDetailPage({required this.photoIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Detail Foto'),
        backgroundColor: Colors.yellow,
      ),
      body: Center(
        child: Hero(
          tag: 'photo-$photoIndex',
          child: Container(
            color: Colors.grey.shade800,
            height: 300,
            width: 300,
            child: Icon(Icons.photo, color: Colors.yellow, size: 100),
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class ImageViewerScreen extends StatelessWidget {
  final String imageSource;

  const ImageViewerScreen({Key? key, required this.imageSource}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;

    if (imageSource.startsWith('http://') || imageSource.startsWith('https://')) {
      imageProvider = NetworkImage(imageSource);
    } else if (File(imageSource).existsSync()) {
      imageProvider = FileImage(File(imageSource));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Center(
        child: imageProvider != null
            ? PhotoView(
                imageProvider: imageProvider,
                 minScale: PhotoViewComputedScale.contained * 0.8,
                 maxScale: PhotoViewComputedScale.covered * 2,
                 enableRotation: true,
              )
            : const Icon(
                Icons.error,
                color: Colors.red,
                size: 55, // Aumentado o tamanho do ícone de erro
              ),
      ),
    );
  }
}
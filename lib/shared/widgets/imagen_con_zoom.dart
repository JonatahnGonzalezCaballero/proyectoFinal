import 'package:flutter/material.dart';

class ImagenConZoom extends StatelessWidget {
  const ImagenConZoom({super.key, required this.imageProvider, this.width = 100, this.height = 100});
  final ImageProvider imageProvider;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => mostrarImagenAmpliada(context, imageProvider),
      child: Hero(
        tag: imageProvider.hashCode,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image(image: imageProvider, width: width, height: height, fit: BoxFit.cover),
        ),
      ),
    );
  }
}

void mostrarImagenAmpliada(BuildContext context, ImageProvider imageProvider) {
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: Colors.black87,
      pageBuilder: (context, animation, secondaryAnimation) => _VisorImagen(imageProvider: imageProvider),
    ),
  );
}

class _VisorImagen extends StatelessWidget {
  const _VisorImagen({required this.imageProvider});
  final ImageProvider imageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop()),
      ),
      body: Center(
        child: Hero(
          tag: imageProvider.hashCode,
          child: InteractiveViewer(minScale: 0.8, maxScale: 4, child: Image(image: imageProvider, fit: BoxFit.contain)),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

class NetworkImagePreviewScreen extends StatelessWidget {
  final String imageUrl;
  final String title;

  const NetworkImagePreviewScreen({
    super.key,
    required this.imageUrl,
    this.title = 'Preview Gambar',
  });

  String _cleanImageUrl(String value) {
    return value
        .trim()
        .replaceAll('?#/', '/')
        .replaceAll('#/', '/')
        .replaceAll('?/storage/', '/storage/')
        .replaceAll('?storage/', '/storage/');
  }

  @override
  Widget build(BuildContext context) {
    final url = _cleanImageUrl(imageUrl);

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;

                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white70,
                        size: 64,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Gambar tidak bisa dimuat.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SelectableText(
                        url,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

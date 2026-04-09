import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/client_model.dart';
import '../../core/theme/app_theme.dart';

class ClientCard extends StatelessWidget {
  final Client client;

  const ClientCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 20),
          Expanded(child: _buildInfo()),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    // prioritas: imageUrl → image → null
    final imageUrl = client.imageUrl ?? client.image;

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.border, width: 1.5),
      ),
      clipBehavior: Clip.hardEdge,
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.business, size: 36, color: AppTheme.border),
            )
          : const Icon(Icons.business, size: 36, color: AppTheme.border),
    );
  }

  Widget _buildInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          client.clientName,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 40,
          height: 3,
          decoration: BoxDecoration(
            color: AppTheme.green,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        if (client.desc != null) ...[
          const SizedBox(height: 8),
          Text(
            client.desc!,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textGrey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (client.alamat != null) ...[
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppTheme.textGrey,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  client.alamat!,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _HttpImageCircle extends StatefulWidget {
  final String url;
  final Widget fallback;

  const _HttpImageCircle({required this.url, required this.fallback});

  @override
  State<_HttpImageCircle> createState() => _HttpImageCircleState();
}

class _HttpImageCircleState extends State<_HttpImageCircle> {
  late Future<Uint8List> _imageData;

  @override
  void initState() {
    super.initState();
    _imageData = _fetchImage();
  }

  Future<Uint8List> _fetchImage() async {
    try {
      final response = await http.get(Uri.parse(widget.url));
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      throw Exception('Failed to load image: ${response.statusCode}');
    } catch (e) {
      print('HTTP Error for ${widget.url}: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _imageData,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return Image.memory(
            snapshot.data!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => widget.fallback,
          );
        } else if (snapshot.hasError) {
          print('Image load error for ${widget.url}: ${snapshot.error}');
          return widget.fallback;
        }
        return const Center(child: CircularProgressIndicator(strokeWidth: 2));
      },
    );
  }
}

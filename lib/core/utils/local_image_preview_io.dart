import 'dart:io';

import 'package:flutter/material.dart';

Widget buildLocalImageThumbnail({
  required String path,
  double width = 56,
  double height = 56,
  BoxFit fit = BoxFit.cover,
}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: Image.file(
      File(path),
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: width,
          height: height,
          alignment: Alignment.center,
          color: const Color(0xFFE2E8F0),
          child: const Icon(Icons.broken_image_outlined),
        );
      },
    ),
  );
}

Future<void> showLocalImageViewer(
  BuildContext context, {
  required String path,
  String? title,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) {
      return Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title ?? 'Bukti transaksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4,
                child: Image.file(
                  File(path),
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('Gagal membuka gambar bukti.'),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

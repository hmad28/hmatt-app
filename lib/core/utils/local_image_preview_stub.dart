import 'package:flutter/material.dart';

Widget buildLocalImageThumbnail({
  required String path,
  double width = 56,
  double height = 56,
  BoxFit fit = BoxFit.cover,
}) {
  return Container(
    width: width,
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(10),
    ),
    child: const Icon(Icons.image_not_supported_outlined),
  );
}

Future<void> showLocalImageViewer(
  BuildContext context, {
  required String path,
  String? title,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title ?? 'Bukti transaksi'),
      content: const Text('Preview gambar belum didukung di platform ini.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Tutup'),
        ),
      ],
    ),
  );
}

import 'package:flutter/material.dart';

import 'local_image_preview_stub.dart'
    if (dart.library.io) 'local_image_preview_io.dart' as impl;

Widget buildLocalImageThumbnail({
  required String path,
  double width = 56,
  double height = 56,
  BoxFit fit = BoxFit.cover,
}) {
  return impl.buildLocalImageThumbnail(
    path: path,
    width: width,
    height: height,
    fit: fit,
  );
}

Future<void> showLocalImageViewer(
  BuildContext context, {
  required String path,
  String? title,
}) {
  return impl.showLocalImageViewer(
    context,
    path: path,
    title: title,
  );
}

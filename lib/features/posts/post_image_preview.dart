import 'package:flutter/material.dart';

import '../../core/theme/yunta_theme.dart';

class PostImagePreview extends StatelessWidget {
  const PostImagePreview({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: Image.network(
      url,
      width: double.infinity,
      height: 230,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) => progress == null
          ? child
          : Container(
              height: 230,
              color: YuntaColors.surfaceBlue,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
      errorBuilder: (_, _, _) => const SizedBox.shrink(),
    ),
  );
}

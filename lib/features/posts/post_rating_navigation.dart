import 'package:flutter/material.dart';

import 'post_rating_screen.dart';

Future<bool?> openPostRating({
  required BuildContext context,
  required String postId,
  required String title,
  required String providerName,
}) => Navigator.of(context).push<bool>(
  MaterialPageRoute(
    builder: (_) => PostRatingScreen(
      postId: postId,
      title: title,
      providerName: providerName,
    ),
  ),
);

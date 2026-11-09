const _requestTypesRatedByAuthor = {'help_request', 'urgent_request'};

bool isExpectedPostRater(Map<String, dynamic> detail, String userId) {
  if (userId.isEmpty) return false;
  final authorId = detail['author_id'] as String?;
  final type = detail['type'] as String? ?? '';
  if (_requestTypesRatedByAuthor.contains(type)) return userId == authorId;
  return userId != authorId && detail['my_membership'] == 'accepted';
}

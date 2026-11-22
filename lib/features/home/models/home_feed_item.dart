/// Modelo inmutable para las publicaciones del feed principal de Home (`03 Home/01.png`).
class HomeFeedItem {
  final String id;
  final String authorName;
  final String authorInitials;
  final String actionVerb;
  final String placeName;
  final double rating;
  final String location;
  final List<String> tags;
  final String notes;
  final String activitiesText;
  final int likesCount;
  final int commentsCount;
  final String timestampLabel;
  final String category;
  final bool isLiked;
  final bool isBookmarked;
  final String? favoriteList;
  final List<String> favoriteTags;
  final String? favoriteNotes;

  const HomeFeedItem({
    required this.id,
    required this.authorName,
    required this.authorInitials,
    this.actionVerb = 'gave creds to',
    required this.placeName,
    required this.rating,
    required this.location,
    required this.tags,
    required this.notes,
    required this.activitiesText,
    required this.likesCount,
    required this.commentsCount,
    required this.timestampLabel,
    required this.category,
    this.isLiked = false,
    this.isBookmarked = false,
    this.favoriteList,
    this.favoriteTags = const [],
    this.favoriteNotes,
  });

  /// Crea un [HomeFeedItem] a partir de `FeedItemDto` de `GET /v1/feed`.
  factory HomeFeedItem.fromApiJson(Map<String, dynamic> json) {
    final author = json['author'] is Map<String, dynamic>
        ? json['author'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final place = json['place'] is Map<String, dynamic>
        ? json['place'] as Map<String, dynamic>
        : null;

    final rawTags = json['tagCodes'];
    final tags = rawTags is List
        ? rawTags
            .map((e) => _formatCodeLabel(e.toString()))
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];

    final rawActivities = json['activityCodes'];
    final activities = rawActivities is List
        ? rawActivities
            .map((e) => _formatCodeLabel(e.toString()))
            .where((s) => s.isNotEmpty)
            .toList()
        : const <String>[];

    final itemType = (json['itemType'] ?? '').toString();
    final category = itemType == 'recommendation_request'
        ? 'Recommendations'
        : 'Following';

    final placeName = (place?['name'] as String?)?.trim();
    final headline = (json['headline'] as String?)?.trim();
    final title = (placeName != null && placeName.isNotEmpty)
        ? placeName
        : (headline != null && headline.isNotEmpty)
            ? headline
            : 'Workout spot';

    final locality = (place?['locality'] as String?)?.trim();
    final locationLabel = (json['locationLabel'] as String?)?.trim();
    final subtitle = (place?['subtitle'] as String?)?.trim();
    final location = (locationLabel != null && locationLabel.isNotEmpty)
        ? locationLabel
        : (locality != null && locality.isNotEmpty)
            ? locality
            : (subtitle != null && subtitle.isNotEmpty)
                ? subtitle
                : 'Nearby';

    final notesText = (json['notes'] as String?)?.trim();
    final detailsText = (json['details'] as String?)?.trim();
    final bodyText = (notesText != null && notesText.isNotEmpty)
        ? notesText
        : (detailsText ?? '');

    final placeActivities = (place?['activitiesLabel'] as String?)?.trim();
    final activitiesText = activities.isNotEmpty
        ? activities.join(', ')
        : (placeActivities ?? '');

    return HomeFeedItem(
      id: (json['id'] ?? '').toString(),
      authorName: (author['displayName'] ?? 'Creds User').toString(),
      authorInitials: (author['initials'] ?? 'CR').toString(),
      actionVerb: (json['actionVerb'] ?? 'rated').toString(),
      placeName: title,
      rating: (json['score'] as num?)?.toDouble() ?? 0.0,
      location: location,
      tags: tags,
      notes: bodyText,
      activitiesText: activitiesText,
      likesCount: (json['likesCount'] as num?)?.toInt() ?? 0,
      commentsCount: (json['commentsCount'] as num?)?.toInt() ?? 0,
      timestampLabel: _formatTimestamp(json['createdAt']?.toString()),
      category: category,
      isLiked: json['isLikedByMe'] == true,
      isBookmarked: json['isSavedByMe'] == true,
      favoriteList: json['listCode'] as String?,
    );
  }

  static String _formatCodeLabel(String raw) {
    final clean = raw.replaceAll('_', ' ').trim();
    if (clean.isEmpty) return '';
    return clean[0].toUpperCase() + clean.substring(1);
  }

  static String _formatTimestamp(String? iso) {
    if (iso == null || iso.isEmpty) return 'Recently';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return 'Recently';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  HomeFeedItem copyWith({
    bool? isLiked,
    bool? isBookmarked,
    int? likesCount,
    String? favoriteList,
    List<String>? favoriteTags,
    String? favoriteNotes,
  }) {
    return HomeFeedItem(
      id: id,
      authorName: authorName,
      authorInitials: authorInitials,
      actionVerb: actionVerb,
      placeName: placeName,
      rating: rating,
      location: location,
      tags: tags,
      notes: notes,
      activitiesText: activitiesText,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount,
      timestampLabel: timestampLabel,
      category: category,
      isLiked: isLiked ?? this.isLiked,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      favoriteList: favoriteList ?? this.favoriteList,
      favoriteTags: favoriteTags ?? this.favoriteTags,
      favoriteNotes: favoriteNotes ?? this.favoriteNotes,
    );
  }

  static const List<HomeFeedItem> sampleItems = [
    HomeFeedItem(
      id: 'feed_1',
      authorName: 'Sofía Martínez',
      authorInitials: 'SM',
      placeName: 'Atlas Fitness',
      rating: 8.5,
      location: 'Jesús María, Lima, Peru',
      tags: ['Fun', 'Great service', 'TOP classes'],
      notes:
          'I left feeling energized. The strength classes had great energy and attentive coaches.',
      activitiesText: 'Pilates, exercise',
      likesCount: 24,
      commentsCount: 12,
      timestampLabel: 'Yesterday 9:20 PM · 1 visit',
      category: 'Following',
    ),
    HomeFeedItem(
      id: 'feed_2',
      authorName: 'Luis Chacon',
      authorInitials: 'LC',
      placeName: 'Gym Fitness',
      rating: 8.5,
      location: 'Miraflores, Lima, Peru',
      tags: ['Clean', 'Good equipment'],
      notes:
          'Great free weights zone and very friendly staff throughout the whole session.',
      activitiesText: 'Strength training, HIIT',
      likesCount: 18,
      commentsCount: 5,
      timestampLabel: 'Yesterday 6:15 PM · 2 visits',
      category: 'For you',
    ),
    HomeFeedItem(
      id: 'feed_3',
      authorName: 'Valeria Gómez',
      authorInitials: 'VG',
      placeName: 'Koa Studio',
      rating: 9.2,
      location: 'San Isidro, Lima, Peru',
      tags: ['Reformer', 'Calm vibe'],
      notes:
          'One of the best morning Pilates classes in the city. Super clean studio and clear guidance.',
      activitiesText: 'Pilates, Mobility',
      likesCount: 31,
      commentsCount: 9,
      timestampLabel: '2 days ago · 4 visits',
      category: 'Recommendations',
    ),
  ];
}

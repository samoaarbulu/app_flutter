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
    this.actionVerb = 'rated',
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

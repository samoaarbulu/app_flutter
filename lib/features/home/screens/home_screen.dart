import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/creds_api_service.dart';
import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../auth/services/auth_service.dart';
import '../../splash/screens/presentacion.dart';
import '../models/home_feed_item.dart';
import '../widgets/add_favorite_sheet.dart';
import '../widgets/add_visit_sheet.dart';
import 'new_recommendation_screen.dart';
import 'visit_share_screen.dart';

/// Pantalla principal de la aplicación (`03 Home/01.png`).
///
/// Incluye:
/// - Top bar con wordmark `CREDS`, notificaciones y búsqueda.
/// - Banner de invitación ("Invite 5 friends").
/// - Acceso rápido "Ask for recommendations" con foto o iniciales y nombre del usuario logeado.
/// - Filtros horizontales y feed de calificaciones/reseñas interactivo.
/// - Barra de navegación inferior de 5 pestañas (`Home`, `My lists`, `Explore`, `Club`, `Profile`).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> _filters = [
    'All',
    'Following',
    'For you',
  ];

  int _selectedNavIndex = 0;
  String _selectedFilter = 'All';
  late List<HomeFeedItem> _feedItems;
  bool _isLoadingFeed = false;
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    if (CredsApiService.instance.hasSession) {
      _feedItems = [];
      _loadFeed();
    } else {
      _feedItems = List<HomeFeedItem>.from(HomeFeedItem.sampleItems);
    }
  }

  String _feedTabParamForFilter(String filter) {
    return switch (filter) {
      'Following' => 'following',
      'For you' => 'for_you',
      'Recommendations' => 'recommendations',
      _ => 'all',
    };
  }

  Future<void> _loadFeed() async {
    if (!CredsApiService.instance.hasSession) return;
    setState(() => _isLoadingFeed = true);
    try {
      final items = await CredsApiService.instance.getFeed(
        tab: _feedTabParamForFilter(_selectedFilter),
      );
      if (!mounted) return;
      setState(() {
        _feedItems = items;
        _isLoadingFeed = false;
      });
    } on CredsApiException catch (e) {
      if (!mounted) return;
      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        setState(() {
          _feedItems = List<HomeFeedItem>.from(HomeFeedItem.sampleItems);
          _isLoadingFeed = false;
        });
      } else {
        setState(() => _isLoadingFeed = false);
        AppFeedback.showError(context, e.message);
      }
    }
  }

  /// Obtiene el nombre completo del usuario logeado (o respaldo legible).
  String _resolveLoggedUserName() {
    final apiUser = CredsApiService.instance.currentUser;
    if (apiUser != null) {
      final first = (apiUser.firstName ?? '').trim();
      final last = (apiUser.lastName ?? '').trim();
      final combined = [first, last].where((s) => s.isNotEmpty).join(' ');
      if (combined.isNotEmpty) return combined;
      if (apiUser.displayName.trim().isNotEmpty) {
        return apiUser.displayName.trim();
      }
    }

    final firebaseName = AuthService.instance.currentUser?.displayName?.trim();
    if (firebaseName != null && firebaseName.isNotEmpty) {
      return firebaseName;
    }

    return 'Ana Torres';
  }

  /// Extrae las iniciales de nombre y apellido (ej. "Ana Torres" -> "AT").
  String _extractInitials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'CR';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String? _resolveProfilePhotoUrl() {
    final apiAvatar = CredsApiService.instance.currentUser?.avatarUrl?.trim();
    if (apiAvatar != null && apiAvatar.isNotEmpty) {
      return _normalizePhotoUrl(apiAvatar);
    }
    final firebasePhoto = AuthService.instance.currentUser?.photoURL?.trim();
    if (firebasePhoto != null && firebasePhoto.isNotEmpty) {
      return _normalizePhotoUrl(firebasePhoto);
    }
    return null;
  }

  String _resolveLoggedUsername(String fullName) {
    final apiUsername = CredsApiService.instance.currentUser?.username?.trim();
    if (apiUsername != null && apiUsername.isNotEmpty) {
      return apiUsername;
    }

    final email = CredsApiService.instance.currentUser?.email ??
        AuthService.instance.currentUser?.email;
    if (email != null && email.contains('@')) {
      final prefix = email.split('@').first.trim();
      if (prefix.isNotEmpty) return prefix;
    }

    final normalized = fullName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '.')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    return normalized.isNotEmpty ? normalized : 'ana.torres';
  }

  Future<void> _openNewRecommendation({
    required String userName,
    required String initials,
    required PickedImage? customPhoto,
    required String? photoUrl,
  }) async {
    final username = _resolveLoggedUsername(userName);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NewRecommendationScreen(
          userName: userName,
          username: username,
          initials: initials,
          customPhoto: customPhoto,
          photoUrl: photoUrl,
          onPosted: (item) {
            if (!mounted) return;
            setState(() => _feedItems.insert(0, item));
          },
        ),
      ),
    );
  }

  Future<void> _openAddVisitFlow({
    required HomeFeedItem item,
    required String userName,
    required String initials,
    required PickedImage? customPhoto,
    required String? photoUrl,
  }) async {
    final primaryActivity = item.activitiesText.split(',').first.trim();
    final district = item.location.split(',').first.trim();
    final subtitle = primaryActivity.isNotEmpty
        ? '$primaryActivity · $district'
        : district;

    final result = await AddVisitSheet.show(
      context,
      placeName: item.placeName,
      placeSubtitle: subtitle,
      fullLocation: item.location,
    );
    if (result == null || !mounted) return;

    final newVisitItem = HomeFeedItem(
      id: 'visit_${DateTime.now().millisecondsSinceEpoch}',
      authorName: userName,
      authorInitials: initials,
      actionVerb: 'rated',
      placeName: result.placeName,
      rating: result.rating,
      location: result.location,
      tags: result.tags,
      notes: result.notes.isNotEmpty
          ? result.notes
          : 'Added to ${result.listCategory} list.',
      activitiesText: result.activities.isNotEmpty
          ? result.activities.join(', ')
          : result.listCategory,
      likesCount: 0,
      commentsCount: 0,
      timestampLabel: 'Just now',
      category: 'Following',
    );

    setState(() => _feedItems.insert(0, newVisitItem));

    final username = _resolveLoggedUsername(userName);
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VisitShareScreen(
          userName: userName,
          username: username,
          initials: initials,
          customPhoto: customPhoto,
          photoUrl: photoUrl,
          placeName: result.placeName,
          location: result.location,
          rating: result.rating,
        ),
      ),
    );
  }

  String _normalizePhotoUrl(String rawUrl) {
    if (kIsWeb && rawUrl.contains('googleusercontent.com')) {
      return 'https://images.weserv.nl/?url=${Uri.encodeComponent(rawUrl)}';
    }
    return rawUrl;
  }

  List<HomeFeedItem> get _filteredItems {
    if (_selectedFilter == 'All') return _feedItems;
    return _feedItems
        .where((item) => item.category == _selectedFilter)
        .toList();
  }

  void _toggleLike(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _feedItems = _feedItems.map((item) {
        if (item.id != id) return item;
        final nextLiked = !item.isLiked;
        return item.copyWith(
          isLiked: nextLiked,
          likesCount: nextLiked ? item.likesCount + 1 : item.likesCount - 1,
        );
      }).toList();
    });
  }

  Future<void> _toggleBookmark(HomeFeedItem target) async {
    HapticFeedback.selectionClick();
    final primaryCategory = target.activitiesText.split(',').first.trim();
    final result = await AddFavoriteSheet.show(
      context,
      placeName: target.placeName,
      placeCategory: primaryCategory.isNotEmpty ? primaryCategory : 'Gym',
      fullLocation: target.location,
      initialTags: target.tags,
      isEditing: target.isBookmarked,
      initialList: target.favoriteList,
      initialSelectedTags: target.favoriteTags,
      initialNotes: target.favoriteNotes,
    );
    if (result == null || !mounted) return;

    if (result.removed) {
      setState(() {
        _feedItems = _feedItems.map((item) {
          if (item.id != target.id) return item;
          return item.copyWith(isBookmarked: false);
        }).toList();
      });
      AppFeedback.show(context, '${target.placeName} removed from favorites');
      return;
    }

    setState(() {
      _feedItems = _feedItems.map((item) {
        if (item.id != target.id) return item;
        return item.copyWith(
          isBookmarked: true,
          favoriteList: result.listName,
          favoriteTags: result.tags,
          favoriteNotes: result.notes,
        );
      }).toList();
    });
    AppFeedback.showSuccess(
      context,
      target.isBookmarked
          ? '${target.placeName} updated in ${result.listName}'
          : '${target.placeName} saved to ${result.listName}',
    );
  }

  Future<void> _handleSignOut() async {
    setState(() => _isSigningOut = true);
    try {
      await AuthService.instance.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PresentationScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      AppFeedback.showError(context, 'No se pudo cerrar sesión: $e');
      setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _resolveLoggedUserName();
    final initials = _extractInitials(userName);
    final customPhoto = AuthService.instance.customPhoto;
    final photoUrl = _resolveProfilePhotoUrl();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: IndexedStack(
          index: _selectedNavIndex,
          children: [
            _buildHomeFeedTab(
              userName: userName,
              initials: initials,
              customPhoto: customPhoto,
              photoUrl: photoUrl,
            ),
            _buildMyListsTab(),
            _buildPlaceholderTab(
              title: 'Log',
              description: 'Log a workout visit and rank your favorite spots.',
            ),
            _buildPlaceholderTab(
              title: 'Community',
              description: 'Connect with friends and see their latest workouts.',
            ),
            _buildProfileTab(
              userName: userName,
              initials: initials,
              customPhoto: customPhoto,
              photoUrl: photoUrl,
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 1.5.rem,
      title: Text(
        'CREDS',
        style: GoogleFonts.poppins(
          fontSize: 0.9375.rem, // 15 px
          fontWeight: FontWeight.w800,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Notifications',
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () =>
              AppFeedback.show(context, 'Notifications coming soon'),
        ),
        Padding(
          padding: EdgeInsets.only(right: 0.75.rem),
          child: IconButton(
            tooltip: 'Search',
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.textPrimary,
              size: 24,
            ),
            onPressed: () => setState(() => _selectedNavIndex = 2),
          ),
        ),
      ],
    );
  }

  Widget _buildHomeFeedTab({
    required String userName,
    required String initials,
    required PickedImage? customPhoto,
    required String? photoUrl,
  }) {
    final visibleItems = CredsApiService.instance.hasSession
        ? _feedItems
        : _filteredItems;

    return RefreshIndicator(
      color: AppColors.primaryAction,
      onRefresh: _loadFeed,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(1.5.rem, 0.5.rem, 1.5.rem, 1.5.rem),
        children: [
        // 1. Banner oscuro "Invite 5 friends"
        _buildInviteBanner(),

        SizedBox(height: 1.125.rem),

        // 2. Fila de usuario logeado + "Ask for recommendations"
        _buildRecommendationsComposer(
          userName: userName,
          initials: initials,
          customPhoto: customPhoto,
          photoUrl: photoUrl,
        ),

        SizedBox(height: 1.0.rem),

        // 3. Filtros horizontales
        _buildFilterChips(),

        SizedBox(height: 1.0.rem),

        // 4. Tarjetas del feed
        if (_isLoadingFeed)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.5.rem),
            child: const Center(
              child: CircularProgressIndicator(
                color: AppColors.primaryAction,
              ),
            ),
          )
        else if (visibleItems.isEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 2.5.rem),
            child: Center(
              child: Text(
                'No posts in $_selectedFilter yet.',
                style: GoogleFonts.poppins(
                  fontSize: 0.875.rem,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ...visibleItems.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 1.0.rem),
              child: _FeedPostCard(
                item: item,
                onLikeTap: () => _toggleLike(item.id),
                onBookmarkTap: () => _toggleBookmark(item),
                onAddTap: () => _openAddVisitFlow(
                  item: item,
                  userName: userName,
                  initials: initials,
                  customPhoto: customPhoto,
                  photoUrl: photoUrl,
                ),
                onCommentTap: () =>
                    AppFeedback.show(context, 'Comments coming soon'),
                onShareTap: () =>
                    AppFeedback.show(context, 'Share coming soon'),
              ),
            ),
          ),
      ],
      ),
    );
  }

  Widget _buildInviteBanner() {
    return Material(
      color: AppColors.primaryAction,
      borderRadius: BorderRadius.circular(16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            AppFeedback.show(context, 'Invite friends flow coming soon'),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 1.25.rem,
            vertical: 1.125.rem,
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invite 5 friends',
                      style: GoogleFonts.poppins(
                        fontSize: 1.0.rem, // 16 px
                        fontWeight: FontWeight.w700,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    SizedBox(height: 0.25.rem),
                    Text(
                      'This will unlock more activities in Creds',
                      style: GoogleFonts.poppins(
                        fontSize: 0.8125.rem, // 13 px
                        fontWeight: FontWeight.w400,
                        color: AppColors.onPrimary.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 0.75.rem),
              const Icon(
                Icons.add_rounded,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendationsComposer({
    required String userName,
    required String initials,
    required PickedImage? customPhoto,
    required String? photoUrl,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        UserAvatar(
          size: 2.75.rem, // 44 px
          initials: initials,
          customPhoto: customPhoto,
          photoUrl: photoUrl,
        ),
        SizedBox(width: 0.75.rem),
        Expanded(
          child: Material(
            color: AppColors.inputSurface,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.0),
              side: const BorderSide(color: AppColors.border, width: 1.0),
            ),
            child: InkWell(
              onTap: () => _openNewRecommendation(
                userName: userName,
                initials: initials,
                customPhoto: customPhoto,
                photoUrl: photoUrl,
              ),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(
                  horizontal: 1.0.rem,
                  vertical: 0.8125.rem,
                ),
                child: Text(
                  'Ask your people',
                  style: GoogleFonts.poppins(
                    fontSize: 0.875.rem, // 14 px
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 2.25.rem, // 36 px
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 0.5.rem),
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = filter == _selectedFilter;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedFilter = filter);
              if (CredsApiService.instance.hasSession) {
                _loadFeed();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              padding: EdgeInsets.symmetric(
                horizontal: 0.9375.rem,
                vertical: 0.4375.rem,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryAction : AppColors.surface,
                borderRadius: BorderRadius.circular(20.0),
                border: Border.all(
                  color: isSelected ? AppColors.primaryAction : AppColors.border,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: Text(
                  filter,
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem, // 13 px
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    color: isSelected
                        ? AppColors.onPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMyListsTab() {
    final savedItems = _feedItems.where((item) => item.isBookmarked).toList();
    if (savedItems.isEmpty) {
      return _buildPlaceholderTab(
        title: 'My lists',
        description: 'Tap the bookmark icon on any place to save it to your favorites.',
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(1.5.rem, 0.75.rem, 1.5.rem, 1.5.rem),
      children: [
        Text(
          'Saved favorites',
          style: GoogleFonts.poppins(
            fontSize: 1.125.rem,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 0.75.rem),
        ...savedItems.map((item) {
          final listLabel = item.favoriteList ?? 'Favorites';
          final displayTags =
              item.favoriteTags.isNotEmpty ? item.favoriteTags : item.tags;
          final displayNotes = (item.favoriteNotes ?? '').trim();

          return Padding(
            padding: EdgeInsets.only(bottom: 0.75.rem),
            child: Material(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              child: InkWell(
                onTap: () => _toggleBookmark(item),
                borderRadius: BorderRadius.circular(16.0),
                child: Container(
                  padding: EdgeInsets.all(1.0.rem),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16.0),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.placeName,
                              style: GoogleFonts.poppins(
                                fontSize: 0.9375.rem,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 0.625.rem,
                              vertical: 0.25.rem,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.inputSurface,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              listLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 0.6875.rem,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 0.375.rem),
                          const Icon(
                            Icons.bookmark_rounded,
                            size: 20,
                            color: AppColors.primaryAction,
                          ),
                        ],
                      ),
                      SizedBox(height: 0.25.rem),
                      Text(
                        item.location,
                        style: GoogleFonts.poppins(
                          fontSize: 0.75.rem,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (displayTags.isNotEmpty) ...[
                        SizedBox(height: 0.5.rem),
                        Wrap(
                          spacing: 0.375.rem,
                          runSpacing: 0.375.rem,
                          children: displayTags
                              .map(
                                (tag) => Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.625.rem,
                                    vertical: 0.1875.rem,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.poppins(
                                      fontSize: 0.6875.rem,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      if (displayNotes.isNotEmpty) ...[
                        SizedBox(height: 0.5.rem),
                        Text(
                          displayNotes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 0.75.rem,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPlaceholderTab({
    required String title,
    required String description,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
      child: Center(
        child: AppHeader.centered(
          title: title,
          description: description,
        ),
      ),
    );
  }

  Widget _buildProfileTab({
    required String userName,
    required String initials,
    required PickedImage? customPhoto,
    required String? photoUrl,
  }) {
    final apiUser = CredsApiService.instance.currentUser;
    final firebaseUser = AuthService.instance.currentUser;
    final subtitleLabel = apiUser?.username != null && apiUser!.username!.isNotEmpty
        ? '@${apiUser.username}'
        : (apiUser?.email ?? firebaseUser?.email ?? 'Creds member');
    final activities = apiUser?.activities ?? const <String>[];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 1.5.rem),
          Row(
            children: [
              UserAvatar(
                size: 4.0.rem, // 64 px
                initials: initials,
                customPhoto: customPhoto,
                photoUrl: photoUrl,
              ),
              SizedBox(width: 1.0.rem),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.poppins(
                        fontSize: 1.25.rem, // 20 px
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 0.125.rem),
                    Text(
                      subtitleLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 0.875.rem,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activities.isNotEmpty) ...[
            SizedBox(height: 1.5.rem),
            Text(
              'Activities',
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 0.5.rem),
            Wrap(
              spacing: 0.5.rem,
              runSpacing: 0.5.rem,
              children: activities
                  .map(
                    (code) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 0.75.rem,
                        vertical: 0.375.rem,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        code.replaceAll('_', ' '),
                        style: GoogleFonts.poppins(
                          fontSize: 0.75.rem,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          const Spacer(),
          AppButton(
            text: 'Sign out',
            variant: AppButtonVariant.outline,
            isLoading: _isSigningOut,
            onPressed: _handleSignOut,
          ),
          SizedBox(height: 1.25.rem),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.8),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedNavIndex,
        onTap: (index) => setState(() => _selectedNavIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.background,
        elevation: 0,
        selectedItemColor: AppColors.textPrimary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: 0.6875.rem, // 11 px
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: 0.6875.rem,
          fontWeight: FontWeight.w500,
        ),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.format_list_numbered_rounded),
            label: 'My lists',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline_rounded),
            activeIcon: Icon(Icons.add_circle_rounded),
            label: 'Log',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.groups_outlined),
            activeIcon: Icon(Icons.groups_rounded),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

/// Tarjeta individual del feed de Home (`03 Home/01.png`).
class _FeedPostCard extends StatefulWidget {
  final HomeFeedItem item;
  final VoidCallback onLikeTap;
  final VoidCallback onBookmarkTap;
  final VoidCallback onAddTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const _FeedPostCard({
    required this.item,
    required this.onLikeTap,
    required this.onBookmarkTap,
    required this.onAddTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      padding: EdgeInsets.all(1.0.rem),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Cabecera: Avatar, título "X rated Y", badge rating y botón '+'
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              UserAvatar(
                size: 2.5.rem, // 40 px
                initials: item.authorInitials,
              ),
              SizedBox(width: 0.75.rem),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.authorName} ${item.actionVerb} ${item.placeName}',
                      style: GoogleFonts.poppins(
                        fontSize: 0.875.rem, // 14 px
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.rating > 0) ...[
                      SizedBox(height: 0.25.rem),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 0.5.rem,
                          vertical: 0.125.rem,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              size: 13,
                              color: AppColors.iconSecondary,
                            ),
                            SizedBox(width: 0.25.rem),
                            Text(
                              item.rating.toStringAsFixed(1),
                              style: GoogleFonts.poppins(
                                fontSize: 0.75.rem,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: widget.onAddTap,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
              ),
            ],
          ),

          SizedBox(height: 0.75.rem),

          // 2. Ubicación
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 15,
                color: AppColors.textSecondary,
              ),
              SizedBox(width: 0.25.rem),
              Expanded(
                child: Text(
                  item.location,
                  style: GoogleFonts.poppins(
                    fontSize: 0.75.rem, // 12 px
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 0.625.rem),

          // 3. Tags (Fun, Great service, TOP classes)
          Wrap(
            spacing: 0.375.rem,
            runSpacing: 0.375.rem,
            children: item.tags
                .map(
                  (tag) => Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 0.625.rem,
                      vertical: 0.25.rem,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14.0),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.poppins(
                        fontSize: 0.75.rem,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          SizedBox(height: 0.75.rem),

          // 4. Activities
          RichText(
            text: TextSpan(
              style: GoogleFonts.poppins(
                fontSize: 0.8125.rem,
                color: AppColors.textPrimary,
              ),
              children: [
                const TextSpan(
                  text: 'Activities: ',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                TextSpan(text: item.activitiesText),
              ],
            ),
          ),

          SizedBox(height: 0.5.rem),

          // 5. Notas con See more / See less
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: RichText(
              maxLines: _isExpanded ? null : 2,
              overflow:
                  _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              text: TextSpan(
                style: GoogleFonts.poppins(
                  fontSize: 0.8125.rem, // 13 px
                  color: AppColors.textPrimary,
                  height: 1.4,
                ),
                children: [
                  const TextSpan(
                    text: 'Notes: ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(text: '${item.notes} '),
                  TextSpan(
                    text: _isExpanded ? 'See less' : 'See more',
                    style: const TextStyle(color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 0.75.rem),

          // 6. Galería horizontal de placeholders de fotos
          SizedBox(
            height: 5.25.rem, // 84 px
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, _) => SizedBox(width: 0.5.rem),
              itemBuilder: (_, _) => Container(
                width: 7.75.rem, // 124 px
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          SizedBox(height: 0.75.rem),

          // 7. Barra de interacción social + bookmark
          Row(
            children: [
              InkWell(
                onTap: widget.onLikeTap,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.25.rem),
                  child: Row(
                    children: [
                      Icon(
                        item.isLiked
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 20,
                        color: item.isLiked
                            ? AppColors.error
                            : AppColors.textPrimary,
                      ),
                      SizedBox(width: 0.375.rem),
                      Text(
                        '${item.likesCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 0.8125.rem,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 1.0.rem),
              InkWell(
                onTap: widget.onCommentTap,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.25.rem),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 19,
                        color: AppColors.textPrimary,
                      ),
                      SizedBox(width: 0.375.rem),
                      Text(
                        '${item.commentsCount}',
                        style: GoogleFonts.poppins(
                          fontSize: 0.8125.rem,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 1.0.rem),
              InkWell(
                onTap: widget.onShareTap,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.25.rem),
                  child: const Icon(
                    Icons.ios_share_rounded,
                    size: 19,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: widget.onBookmarkTap,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 0.25.rem),
                  child: Icon(
                    item.isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    size: 21,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 0.375.rem),

          // 8. Timestamp
          Text(
            item.timestampLabel,
            style: GoogleFonts.poppins(
              fontSize: 0.75.rem, // 12 px
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

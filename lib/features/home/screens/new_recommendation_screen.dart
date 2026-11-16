import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../models/home_feed_item.dart';
import 'recommendation_share_screen.dart';

/// Pantalla de creación de solicitud de recomendación
/// (`03 Home/02 Recomendacion/01.png`).
class NewRecommendationScreen extends StatefulWidget {
  final String userName;
  final String username;
  final String initials;
  final PickedImage? customPhoto;
  final String? photoUrl;
  final ValueChanged<HomeFeedItem>? onPosted;

  const NewRecommendationScreen({
    super.key,
    required this.userName,
    required this.username,
    required this.initials,
    this.customPhoto,
    this.photoUrl,
    this.onPosted,
  });

  @override
  State<NewRecommendationScreen> createState() =>
      _NewRecommendationScreenState();
}

class _NewRecommendationScreenState extends State<NewRecommendationScreen> {
  static const List<String> _suggestedLocations = [
    'Lima, Peru',
    'Miraflores, Lima',
    'Jesús María, Lima',
    'San Isidro, Lima',
    'Barranco, Lima',
    'Miami, FL',
  ];

  final TextEditingController _headlineController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _headlineController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _headlineController.removeListener(_onChanged);
    _headlineController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _canPost => _headlineController.text.trim().isNotEmpty;

  Future<void> _pickLocation() async {
    final chosen = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 1.0.rem, 1.5.rem, 1.25.rem),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 2.5.rem,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 1.0.rem),
                Text(
                  'Choose location',
                  style: GoogleFonts.poppins(
                    fontSize: 1.0625.rem,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.75.rem),
                ..._suggestedLocations.map(
                  (loc) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    title: Text(
                      loc,
                      style: GoogleFonts.poppins(
                        fontSize: 0.9375.rem,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    trailing: _selectedLocation == loc
                        ? const Icon(
                            Icons.check_rounded,
                            color: AppColors.primaryAction,
                          )
                        : null,
                    onTap: () => Navigator.of(sheetContext).pop(loc),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() => _selectedLocation = chosen);
    }
  }

  void _handlePost() {
    if (!_canPost) return;

    final headline = _headlineController.text.trim();
    final details = _detailsController.text.trim();
    final location = _selectedLocation ?? 'Lima, Peru';

    final createdItem = HomeFeedItem(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      authorName: widget.userName,
      authorInitials: widget.initials,
      actionVerb: 'asked about',
      placeName: headline,
      rating: 0,
      location: location,
      tags: const ['Recommendation'],
      notes: details.isNotEmpty
          ? details
          : 'Looking for community recommendations.',
      activitiesText: 'All activities',
      likesCount: 0,
      commentsCount: 0,
      timestampLabel: 'Just now',
      category: 'Recommendations',
    );

    widget.onPosted?.call(createdItem);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => RecommendationShareScreen(
          userName: widget.userName,
          username: widget.username,
          initials: widget.initials,
          customPhoto: widget.customPhoto,
          photoUrl: widget.photoUrl,
          headline: headline,
          location: _selectedLocation,
          details: details,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'NEW RECOMMENDATION',
          style: GoogleFonts.poppins(
            fontSize: 0.8125.rem, // 13 px
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 0.5.rem),

                    const AppHeader.title(
                      'What recommendation do\nyou need?',
                    ),

                    SizedBox(height: 1.5.rem),

                    // Avatar + Headline + Pill Location
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        UserAvatar(
                          size: 2.75.rem, // 44 px
                          initials: widget.initials,
                          customPhoto: widget.customPhoto,
                          photoUrl: widget.photoUrl,
                        ),
                        SizedBox(width: 0.875.rem),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextField(
                                controller: _headlineController,
                                textCapitalization:
                                    TextCapitalization.sentences,
                                style: GoogleFonts.poppins(
                                  fontSize: 1.0.rem, // 16 px
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Recommendation headline',
                                  hintStyle: GoogleFonts.poppins(
                                    fontSize: 1.0.rem,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                              SizedBox(height: 0.5.rem),
                              GestureDetector(
                                onTap: _pickLocation,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.75.rem,
                                    vertical: 0.3125.rem,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedLocation != null
                                        ? AppColors.inputSurface
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: _selectedLocation != null
                                          ? AppColors.primaryAction
                                          : AppColors.textSecondary,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_outlined,
                                        size: 14,
                                        color: AppColors.textPrimary,
                                      ),
                                      SizedBox(width: 0.25.rem),
                                      Text(
                                        _selectedLocation ?? 'Location',
                                        style: GoogleFonts.poppins(
                                          fontSize: 0.75.rem, // 12 px
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 1.5.rem),

                    // Campo de detalles multilínea
                    TextField(
                      controller: _detailsController,
                      maxLines: 6,
                      minLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      style: GoogleFonts.poppins(
                        fontSize: 0.9375.rem,
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                      decoration: InputDecoration(
                        hintText:
                            'More details, e.g. best gym, Pilates classes...',
                        hintStyle: GoogleFonts.poppins(
                          fontSize: 0.9375.rem,
                          color: AppColors.textMuted,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                1.5.rem,
                0.75.rem,
                1.5.rem,
                1.0.rem,
              ),
              child: AppButton(
                text: 'Post',
                variant: AppButtonVariant.primary,
                onPressed: _canPost ? _handlePost : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

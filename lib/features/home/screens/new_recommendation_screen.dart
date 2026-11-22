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
  static const List<String> _activityOptions = [
    'Pilates',
    'Gimnasio',
    'Box',
    'Running',
    'Strength training',
    'Yoga',
    'HIIT',
    'Cycling',
  ];

  static const List<String> _suggestedLocations = [
    'Jesús María, Lima',
    'Lima, Peru',
    'Miraflores, Lima',
    'San Isidro, Lima',
    'Barranco, Lima',
    'Miami, FL',
  ];

  final TextEditingController _detailsController = TextEditingController();
  String? _selectedActivity;
  String? _selectedLocation;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  bool get _canPost => _selectedActivity != null;

  Future<void> _pickActivity() async {
    String? tempSelected = _selectedActivity ?? _activityOptions.first;
    final chosen = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  1.5.rem,
                  0.75.rem,
                  1.5.rem,
                  1.25.rem,
                ),
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
                    SizedBox(height: 0.75.rem),
                    Align(
                      alignment: Alignment.centerRight,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ),
                    Text(
                      'Select activity',
                      style: GoogleFonts.poppins(
                        fontSize: 1.25.rem,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 1.0.rem),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(ctx).size.height * 0.42,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _activityOptions.length,
                        separatorBuilder: (_, _) => SizedBox(height: 0.625.rem),
                        itemBuilder: (_, index) {
                          final activity = _activityOptions[index];
                          final isSelected = tempSelected == activity;
                          return InkWell(
                            borderRadius: BorderRadius.circular(14.0),
                            onTap: () =>
                                setSheetState(() => tempSelected = activity),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 1.0.rem,
                                vertical: 0.9375.rem,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.inputSurface
                                    : AppColors.surface,
                                borderRadius: BorderRadius.circular(14.0),
                                border: Border.all(
                                  color: AppColors.border,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      activity,
                                      style: GoogleFonts.poppins(
                                        fontSize: 0.9375.rem,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w400,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      size: 20,
                                      color: AppColors.textSecondary,
                                    )
                                  else
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppColors.border,
                                          width: 1.5,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 1.25.rem),
                    AppButton(
                      text: 'Apply',
                      variant: AppButtonVariant.primary,
                      onPressed: tempSelected != null
                          ? () => Navigator.of(sheetContext).pop(tempSelected)
                          : null,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() => _selectedActivity = chosen);
    }
  }

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

    final activity = _selectedActivity!;
    final details = _detailsController.text.trim();
    final location = _selectedLocation ?? 'Lima, Peru';

    final createdItem = HomeFeedItem(
      id: 'rec_${DateTime.now().millisecondsSinceEpoch}',
      authorName: widget.userName,
      authorInitials: widget.initials,
      actionVerb: 'asked about',
      placeName: activity,
      rating: 0,
      location: location,
      tags: const ['Recommendation'],
      notes: details.isNotEmpty
          ? details
          : 'Looking for $activity recommendations.',
      activitiesText: activity,
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
          headline: activity,
          location: location,
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
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(
            Icons.close_rounded,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
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
                    SizedBox(height: 0.25.rem),

                    const AppHeader.title('Ask your people'),

                    SizedBox(height: 1.5.rem),

                    // Avatar + "Add your request" + Pill "Add activity"
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
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
                              Text(
                                'Add your request',
                                style: GoogleFonts.poppins(
                                  fontSize: 1.0.rem, // 16 px
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 0.375.rem),
                              GestureDetector(
                                onTap: _pickActivity,
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 0.75.rem,
                                    vertical: 0.3125.rem,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _selectedActivity != null
                                        ? AppColors.inputSurface
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: _selectedActivity != null
                                          ? AppColors.primaryAction
                                          : AppColors.border,
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.directions_run_rounded,
                                        size: 14,
                                        color: AppColors.textSecondary,
                                      ),
                                      SizedBox(width: 0.3125.rem),
                                      Text(
                                        _selectedActivity ?? 'Add activity',
                                        style: GoogleFonts.poppins(
                                          fontSize: 0.75.rem, // 12 px
                                          fontWeight: FontWeight.w500,
                                          color: _selectedActivity != null
                                              ? AppColors.textPrimary
                                              : AppColors.textSecondary,
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

                    // Search location
                    Text(
                      'Search location',
                      style: GoogleFonts.poppins(
                        fontSize: 0.8125.rem, // 13 px
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 0.5.rem),
                    GestureDetector(
                      onTap: _pickLocation,
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(
                          horizontal: 1.0.rem,
                          vertical: 0.9375.rem,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(14.0),
                        ),
                        child: Text(
                          _selectedLocation ?? 'Select location',
                          style: GoogleFonts.poppins(
                            fontSize: 0.9375.rem,
                            fontWeight: _selectedLocation != null
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: _selectedLocation != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(height: 1.5.rem),

                    // Anything specific? | Optional
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Anything specific?',
                          style: GoogleFonts.poppins(
                            fontSize: 0.8125.rem,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Optional',
                          style: GoogleFonts.poppins(
                            fontSize: 0.8125.rem,
                            fontWeight: FontWeight.w400,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.rem),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.0.rem,
                        vertical: 0.25.rem,
                      ),
                      child: TextField(
                        controller: _detailsController,
                        maxLines: 3,
                        minLines: 1,
                        textCapitalization: TextCapitalization.sentences,
                        style: GoogleFonts.poppins(
                          fontSize: 0.9375.rem,
                          color: AppColors.textPrimary,
                          height: 1.45,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Add more details',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 0.9375.rem,
                            color: AppColors.textMuted,
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            vertical: 0.6875.rem,
                          ),
                        ),
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

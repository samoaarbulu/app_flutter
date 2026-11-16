import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Pantalla de tarjeta compartible tras publicar una solicitud de recomendación
/// (`03 Home/02 Recomendacion/02.png`).
class RecommendationShareScreen extends StatelessWidget {
  final String userName;
  final String username;
  final String initials;
  final PickedImage? customPhoto;
  final String? photoUrl;
  final String headline;
  final String? location;
  final String details;

  const RecommendationShareScreen({
    super.key,
    required this.userName,
    required this.username,
    required this.initials,
    this.customPhoto,
    this.photoUrl,
    required this.headline,
    this.location,
    required this.details,
  });

  String get _firstName {
    final trimmed = userName.trim();
    if (trimmed.isEmpty) return 'Athlete';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  String get _displayHandle {
    final clean = username.trim().replaceFirst(RegExp(r'^@+'), '');
    if (clean.isEmpty) return '@creds';
    return '@$clean';
  }

  String get _locationHeadline {
    final loc = (location ?? '').trim();
    final head = headline.trim();
    if (loc.isNotEmpty && head.isNotEmpty && loc != head) {
      return '$head · $loc';
    }
    return loc.isNotEmpty ? loc : head;
  }

  void _handleShareTap(BuildContext context, String channel) {
    HapticFeedback.selectionClick();
    if (channel == 'Copy link') {
      Clipboard.setData(
        ClipboardData(
          text:
              '$_firstName is looking for recommendations: $_locationHeadline',
        ),
      );
      AppFeedback.showSuccess(context, 'Recommendation link copied');
      return;
    }
    AppFeedback.showSuccess(context, 'Shared via $channel');
  }

  @override
  Widget build(BuildContext context) {
    const shareChannels = [
      (label: 'Copy link', icon: Icons.link_rounded),
      (label: 'WhatsApp', icon: Icons.chat_outlined),
      (label: 'Instagram', icon: Icons.camera_alt_outlined),
      (label: 'Messages', icon: Icons.sms_outlined),
      (label: 'More', icon: Icons.ios_share_rounded),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área central gris suave con la tarjeta compartible
            Expanded(
              child: Container(
                width: double.infinity,
                color: AppColors.inputSurface,
                padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
                child: Center(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(1.25.rem),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18.0),
                      border: Border.all(color: AppColors.border, width: 1.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Cabecera con foto/iniciales, nombre y @username
                        Row(
                          children: [
                            UserAvatar(
                              size: 3.0.rem, // 48 px
                              initials: initials,
                              customPhoto: customPhoto,
                              photoUrl: photoUrl,
                            ),
                            SizedBox(width: 0.875.rem),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 0.9375.rem,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    _displayHandle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 0.8125.rem,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 1.125.rem),

                        Text(
                          '$_firstName is looking for recommendations:',
                          style: GoogleFonts.poppins(
                            fontSize: 0.9375.rem,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 0.375.rem),

                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: const Icon(
                                Icons.location_on_outlined,
                                size: 17,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            SizedBox(width: 0.375.rem),
                            Expanded(
                              child: Text(
                                _locationHeadline,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.9375.rem,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (details.trim().isNotEmpty) ...[
                          SizedBox(height: 0.75.rem),
                          Text(
                            'Details: ${details.trim()}',
                            style: GoogleFonts.poppins(
                              fontSize: 0.8125.rem,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bandeja inferior de opciones para compartir
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: EdgeInsets.fromLTRB(
                1.0.rem,
                1.125.rem,
                1.0.rem,
                1.25.rem,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Share to get more responses',
                    style: GoogleFonts.poppins(
                      fontSize: 0.9375.rem,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  SizedBox(height: 1.0.rem),
                  SizedBox(
                    height: 5.0.rem,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: 0.5.rem),
                      itemCount: shareChannels.length,
                      separatorBuilder: (_, _) => SizedBox(width: 1.0.rem),
                      itemBuilder: (context, index) {
                        final channel = shareChannels[index];
                        return GestureDetector(
                          onTap: () => _handleShareTap(context, channel.label),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 3.125.rem, // 50 px
                                height: 3.125.rem,
                                decoration: const BoxDecoration(
                                  color: AppColors.badgeSurface,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  channel.icon,
                                  size: 22,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 0.375.rem),
                              Text(
                                channel.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.75.rem,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

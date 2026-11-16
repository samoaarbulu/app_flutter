import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/user_avatar.dart';

/// Pantalla compartible tras registrar una visita (`03 Home/03 agregar visita/08 Versus/02.png`).
class VisitShareScreen extends StatelessWidget {
  final String userName;
  final String username;
  final String initials;
  final PickedImage? customPhoto;
  final String? photoUrl;
  final String placeName;
  final String location;
  final double rating;
  final int visitCount;

  const VisitShareScreen({
    super.key,
    required this.userName,
    required this.username,
    required this.initials,
    this.customPhoto,
    this.photoUrl,
    required this.placeName,
    required this.location,
    required this.rating,
    this.visitCount = 1,
  });

  String get _displayHandle =>
      username.startsWith('@') ? username : '@$username';

  String get _visitLabel =>
      visitCount == 1 ? '1 visit' : '$visitCount visits';

  void _handleShareTap(BuildContext context, String channel) {
    HapticFeedback.selectionClick();
    if (channel == 'Copy link') {
      Clipboard.setData(
        ClipboardData(
          text:
              '$userName rated $placeName (${rating.toStringAsFixed(1)}★) in $location',
        ),
      );
      AppFeedback.showSuccess(context, 'Visit link copied');
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
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 0.75.rem),
            child: IconButton(
              tooltip: 'Close',
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Área central gris suave con la tarjeta compartible de visita
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
                        // Cabecera: Avatar + Nombre + @username + Badge ★ rating
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
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
                            SizedBox(width: 0.5.rem),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 0.5.rem,
                                vertical: 0.25.rem,
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
                                    size: 14,
                                    color: AppColors.iconSecondary,
                                  ),
                                  SizedBox(width: 0.25.rem),
                                  Text(
                                    rating.toStringAsFixed(1),
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
                        ),

                        SizedBox(height: 1.125.rem),

                        Text(
                          placeName,
                          style: GoogleFonts.poppins(
                            fontSize: 0.9375.rem,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),

                        SizedBox(height: 0.25.rem),

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
                                location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.75.rem,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            SizedBox(width: 0.5.rem),
                            Text(
                              _visitLabel,
                              style: GoogleFonts.poppins(
                                fontSize: 0.75.rem,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bandeja inferior: "Share to get more responses"
            Container(
              width: double.infinity,
              color: AppColors.background,
              padding: EdgeInsets.fromLTRB(1.0.rem, 1.25.rem, 1.0.rem, 1.5.rem),
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
                  SizedBox(height: 1.125.rem),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: shareChannels
                        .map(
                          (channel) => InkWell(
                            onTap: () =>
                                _handleShareTap(context, channel.label),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 0.25.rem,
                                vertical: 0.25.rem,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 3.0.rem, // 48 px
                                    height: 3.0.rem,
                                    decoration: const BoxDecoration(
                                      color: AppColors.badgeSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      channel.icon,
                                      size: 20,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.rem),
                                  Text(
                                    channel.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 0.75.rem,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                        .toList(),
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

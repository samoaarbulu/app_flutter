import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../models/onboarding_place.dart';
import 'useful_permissions_screen.dart';

/// Pantalla de resultado del primer ranking (`08 duelos/05.png`).
///
/// Muestra los lugares ordenados según las comparaciones ganadas y permite
/// continuar al siguiente paso del onboarding.
class FirstRankingScreen extends StatelessWidget {
  final List<RankedPlace> rankedPlaces;
  final VoidCallback? onSaveAndContinue;

  const FirstRankingScreen({
    super.key,
    required this.rankedPlaces,
    this.onSaveAndContinue,
  });

  void _handleSaveAndContinue(BuildContext context) {
    if (onSaveAndContinue != null) {
      onSaveAndContinue!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UsefulPermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 0.5.rem),

                    const AppHeader(
                      title: 'Your first ranking is in',
                      description:
                          'Three comparisons, a ranking that reflects your\npreferences.',
                    ),

                    SizedBox(height: 1.75.rem),

                    Text(
                      'BASED ON YOUR CHOICES',
                      style: GoogleFonts.poppins(
                        fontSize: 0.75.rem, // 12 px
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    SizedBox(height: 0.75.rem),

                    ...List.generate(rankedPlaces.length, (index) {
                      final item = rankedPlaces[index];
                      return Padding(
                        padding: EdgeInsets.only(bottom: 0.75.rem),
                        child: _RankedPlaceCard(
                          rank: index + 1,
                          item: item,
                          isWinner: index == 0,
                        ),
                      );
                    }),

                    SizedBox(height: 1.0.rem),
                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.fromLTRB(
                1.5.rem,
                0.5.rem,
                1.5.rem,
                1.0.rem,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You can compare again anytime.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 0.8125.rem, // 13 px
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  SizedBox(height: 0.875.rem),
                  AppButton(
                    text: 'Save and continue',
                    variant: AppButtonVariant.primary,
                    onPressed: () => _handleSaveAndContinue(context),
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

class _RankedPlaceCard extends StatelessWidget {
  final int rank;
  final RankedPlace item;
  final bool isWinner;

  const _RankedPlaceCard({
    required this.rank,
    required this.item,
    required this.isWinner,
  });

  @override
  Widget build(BuildContext context) {
    final rankLabel = rank.toString().padLeft(2, '0');
    final subtitle =
        '${item.wins} of ${item.totalComparisons} comparisons won';

    return Container(
      constraints: BoxConstraints(minHeight: 6.5625.rem), // 105 px
      padding: EdgeInsets.symmetric(
        horizontal: 1.0.rem,
        vertical: 1.0.rem,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 2.25.rem,
            child: Text(
              rankLabel,
              style: GoogleFonts.poppins(
                fontSize: 1.125.rem, // 18 px
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SizedBox(width: 0.5.rem),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.place.name,
                  style: GoogleFonts.poppins(
                    fontSize: 0.9375.rem, // 15 px
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.125.rem),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem, // 13 px
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isWinner)
            Container(
              width: 2.125.rem, // 34 px
              height: 2.125.rem,
              decoration: BoxDecoration(
                color: AppColors.primaryAction,
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: const Icon(
                Icons.workspace_premium_rounded,
                size: 18,
                color: AppColors.onPrimary,
              ),
            ),
        ],
      ),
    );
  }
}

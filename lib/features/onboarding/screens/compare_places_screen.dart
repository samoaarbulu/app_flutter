import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/creds_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../shared/widgets/app_loading_overlay.dart';
import '../models/onboarding_place.dart';
import 'first_ranking_screen.dart';

/// Pantalla de comparaciones 1 a 1 para construir el primer ranking (`08 duelos/02-04.png`).
///
/// Ejecuta 3 rondas (`COMPARISON 1 OF 3` → `3 OF 3`) y calcula el ranking final
/// según los ganadores seleccionados por el usuario.
class ComparePlacesScreen extends StatefulWidget {
  final List<OnboardingPlace> places;
  final ValueChanged<List<RankedPlace>>? onCompleted;

  const ComparePlacesScreen({
    super.key,
    required this.places,
    this.onCompleted,
  });

  @override
  State<ComparePlacesScreen> createState() => _ComparePlacesScreenState();
}

class _ComparePlacesScreenState extends State<ComparePlacesScreen> {
  late final List<(OnboardingPlace, OnboardingPlace)> _pairs;
  final List<String?> _roundWinners = [];
  int _currentIndex = 0;
  String? _highlightedId;
  bool _isTransitioning = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _pairs = _buildComparisonPairs(widget.places);
    _roundWinners.addAll(List<String?>.filled(_pairs.length, null));
  }

  /// Genera hasta 3 pares de comparación a partir de los lugares elegidos.
  List<(OnboardingPlace, OnboardingPlace)> _buildComparisonPairs(
    List<OnboardingPlace> places,
  ) {
    final pairs = <(OnboardingPlace, OnboardingPlace)>[];
    for (var i = 0; i < places.length; i++) {
      for (var j = i + 1; j < places.length; j++) {
        pairs.add((places[i], places[j]));
        if (pairs.length == 3) return pairs;
      }
    }
    return pairs;
  }

  void _handleBack() {
    if (_isTransitioning) return;
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _highlightedId = _roundWinners[_currentIndex];
      });
    } else {
      Navigator.of(context).maybePop();
    }
  }

  void _selectWinner(String? winnerId) {
    if (_isTransitioning || _pairs.isEmpty) return;

    HapticFeedback.selectionClick();
    _roundWinners[_currentIndex] = winnerId;

    setState(() {
      _highlightedId = winnerId;
      _isTransitioning = true;
    });

    Future.delayed(const Duration(milliseconds: 180), () {
      if (!mounted) return;
      _advanceOrFinish();
    });
  }

  Future<void> _advanceOrFinish() async {
    if (_currentIndex < _pairs.length - 1) {
      setState(() {
        _currentIndex++;
        _highlightedId = _roundWinners[_currentIndex];
        _isTransitioning = false;
      });
      return;
    }

    var ranked = _computeRanking();

    if (widget.onCompleted != null) {
      setState(() => _isTransitioning = false);
      widget.onCompleted!(ranked);
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isSubmitting = true);
      try {
        final comparisons = <CredsDuelComparisonInput>[];
        for (var i = 0; i < _pairs.length; i++) {
          final (placeA, placeB) = _pairs[i];
          final winnerId = _roundWinners[i];
          final outcome = winnerId == placeA.id
              ? 'place_a'
              : winnerId == placeB.id
                  ? 'place_b'
                  : 'tie';
          comparisons.add(
            CredsDuelComparisonInput(
              placeAId: placeA.id,
              placeBId: placeB.id,
              outcome: outcome,
            ),
          );
        }

        final response =
            await CredsApiService.instance.submitOnboardingRanking(
          placeIds: widget.places.map((p) => p.id).toList(),
          comparisons: comparisons,
        );
        if (response.items.isNotEmpty) {
          ranked = response.items;
        }
      } on CredsApiException catch (e) {
        if (!mounted) return;
        if (!e.isNetworkOrOfflineError) {
          setState(() {
            _isSubmitting = false;
            _isTransitioning = false;
          });
          AppFeedback.showError(context, e.message);
          return;
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }

    if (!mounted) return;
    setState(() => _isTransitioning = false);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FirstRankingScreen(rankedPlaces: ranked),
      ),
    );
  }

  List<RankedPlace> _computeRanking() {
    final wins = <String, int>{for (final p in widget.places) p.id: 0};
    final appearances = <String, int>{for (final p in widget.places) p.id: 0};

    for (var i = 0; i < _pairs.length; i++) {
      final (first, second) = _pairs[i];
      appearances[first.id] = (appearances[first.id] ?? 0) + 1;
      appearances[second.id] = (appearances[second.id] ?? 0) + 1;

      final winnerId = _roundWinners[i];
      if (winnerId != null) {
        wins[winnerId] = (wins[winnerId] ?? 0) + 1;
      }
    }

    final sorted = List<OnboardingPlace>.from(widget.places)
      ..sort((a, b) => (wins[b.id] ?? 0).compareTo(wins[a.id] ?? 0));

    return sorted
        .map(
          (place) => RankedPlace(
            place: place,
            wins: wins[place.id] ?? 0,
            totalComparisons: appearances[place.id] ?? 0,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final (leftPlace, rightPlace) = _pairs[_currentIndex];

    return AppLoadingOverlay(
      isLoading: _isSubmitting,
      message: 'Building your first ranking...',
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0.75.rem),

                      // Barra de progreso: COMPARISON X OF Y + 3 segmentos
                      _buildProgressHeader(),

                      SizedBox(height: 0.875.rem),

                      const AppHeader(
                        title: 'Which was better?',
                        description:
                            "Go with your experience, not what's popular.",
                      ),

                      SizedBox(height: 1.75.rem),

                      _ComparePlaceCard(
                        place: leftPlace,
                        isSelected: _highlightedId == leftPlace.id,
                        onTap: () => _selectWinner(leftPlace.id),
                      ),

                      SizedBox(height: 0.875.rem),

                      _ComparePlaceCard(
                        place: rightPlace,
                        isSelected: _highlightedId == rightPlace.id,
                        onTap: () => _selectWinner(rightPlace.id),
                      ),

                      SizedBox(height: 1.25.rem),

                      Center(
                        child: AppLinkButton(
                          text: 'About the same',
                          onPressed: () => _selectWinner(null),
                        ),
                      ),

                      const Spacer(),
                      SizedBox(height: 1.0.rem),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back,
          color: AppColors.textPrimary,
          size: 24,
        ),
        onPressed: _handleBack,
      ),
      title: Text(
        'COMPARE',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final total = _pairs.length;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'COMPARISON ${_currentIndex + 1} OF $total',
          style: GoogleFonts.poppins(
            fontSize: 0.75.rem, // 12 px
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
            color: AppColors.textSecondary,
          ),
        ),
        Row(
          children: List.generate(total, (index) {
            final isActive = index <= _currentIndex;
            return Container(
              width: 1.5.rem, // 24 px
              height: 3.5,
              margin: EdgeInsets.only(left: index == 0 ? 0 : 0.375.rem),
              decoration: BoxDecoration(
                color: isActive ? AppColors.primaryAction : AppColors.border,
                borderRadius: BorderRadius.circular(2.0),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ComparePlaceCard extends StatelessWidget {
  final OnboardingPlace place;
  final bool isSelected;
  final VoidCallback onTap;

  const _ComparePlaceCard({
    required this.place,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          constraints: BoxConstraints(minHeight: 9.5.rem), // 152 px
          padding: EdgeInsets.all(1.125.rem), // 18 px
          decoration: BoxDecoration(
            color: isSelected ? AppColors.inputSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(18.0),
            border: Border.all(
              color: isSelected ? AppColors.primaryAction : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 4.0.rem, // 64 px
                height: 4.0.rem,
                decoration: BoxDecoration(
                  color: AppColors.badgeSurface,
                  borderRadius: BorderRadius.circular(14.0),
                ),
                child: Icon(
                  place.icon,
                  size: 26,
                  color: AppColors.iconSecondary,
                ),
              ),
              SizedBox(width: 1.0.rem),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: GoogleFonts.poppins(
                        fontSize: 1.0625.rem, // 17 px
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 0.25.rem),
                    Text(
                      '${place.neighborhood} · ${place.address}',
                      style: GoogleFonts.poppins(
                        fontSize: 0.8125.rem, // 13 px
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    SizedBox(height: 0.125.rem),
                    Text(
                      place.activitiesLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 0.8125.rem, // 13 px
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../home/screens/home_screen.dart';
import '../models/onboarding_place.dart';
import 'compare_places_screen.dart';

/// Pantalla inicial del Paso 08 ("Start with places you've tried" — `08 duelos/01.png`).
///
/// Permite agregar al menos 3 lugares visitados para construir el primer ranking
/// mediante comparaciones 1 a 1, u omitir el paso con "Do this later".
class YourPlacesScreen extends StatefulWidget {
  final List<OnboardingPlace>? initialPlaces;
  final ValueChanged<List<OnboardingPlace>>? onStartRanking;
  final VoidCallback? onDoThisLater;

  const YourPlacesScreen({
    super.key,
    this.initialPlaces,
    this.onStartRanking,
    this.onDoThisLater,
  });

  @override
  State<YourPlacesScreen> createState() => _YourPlacesScreenState();
}

class _YourPlacesScreenState extends State<YourPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final List<OnboardingPlace> _selectedPlaces;

  @override
  void initState() {
    super.initState();
    _selectedPlaces = List<OnboardingPlace>.from(
      widget.initialPlaces ?? OnboardingPlace.defaultSelected,
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  List<OnboardingPlace> get _searchResults {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return const [];

    final selectedIds = _selectedPlaces.map((p) => p.id).toSet();
    return OnboardingPlace.sampleCatalog.where((place) {
      if (selectedIds.contains(place.id)) return false;
      return place.name.toLowerCase().contains(query) ||
          place.neighborhood.toLowerCase().contains(query) ||
          place.shortCategory.toLowerCase().contains(query);
    }).toList();
  }

  void _addPlace(OnboardingPlace place) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlaces.add(place);
      _searchController.clear();
    });
  }

  void _removePlace(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlaces.removeWhere((p) => p.id == id);
    });
  }

  void _handleStartRanking() {
    if (_selectedPlaces.length < 3) return;

    if (widget.onStartRanking != null) {
      widget.onStartRanking!(List<OnboardingPlace>.from(_selectedPlaces));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComparePlacesScreen(
          places: List<OnboardingPlace>.from(_selectedPlaces),
        ),
      ),
    );
  }

  void _handleDoThisLater() {
    if (widget.onDoThisLater != null) {
      widget.onDoThisLater!();
      return;
    }

    // TODO(onboarding-step-09): Navegar a UsefulPermissionsScreen (Paso 09) y luego FollowSuggestionsScreen (Paso 10).
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchMatches = _searchResults;
    final canStartRanking = _selectedPlaces.length >= 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
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
                      title: "Start with places you've\ntried",
                      description:
                          "Add at least 3 places you've been to. We'll use them to build your first ranking.",
                    ),

                    SizedBox(height: 1.5.rem),

                    // Buscador reutilizando AppTextField
                    AppTextField(
                      controller: _searchController,
                      hintText: "Search places you've been",
                      prefixIcon: const Icon(Icons.search_rounded, size: 22),
                    ),

                    if (searchMatches.isNotEmpty) ...[
                      SizedBox(height: 0.5.rem),
                      _buildSearchSuggestions(searchMatches),
                    ],

                    SizedBox(height: 1.5.rem),

                    // Encabezado de lista: PLACES  |  3 added
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PLACES',
                          style: GoogleFonts.poppins(
                            fontSize: 0.75.rem, // 12 px
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '${_selectedPlaces.length} added',
                          style: GoogleFonts.poppins(
                            fontSize: 0.8125.rem, // 13 px
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 0.75.rem),

                    if (_selectedPlaces.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.5.rem),
                        child: Center(
                          child: Text(
                            'Search and add at least 3 places above.',
                            style: GoogleFonts.poppins(
                              fontSize: 0.875.rem,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      )
                    else
                      ..._selectedPlaces.map(
                        (place) => Padding(
                          padding: EdgeInsets.only(bottom: 0.75.rem),
                          child: _SelectedPlaceTile(
                            place: place,
                            onRemove: () => _removePlace(place.id),
                          ),
                        ),
                      ),

                    SizedBox(height: 1.0.rem),
                  ],
                ),
              ),
            ),

            // Pie fijo con Start ranking y Do this later
            Padding(
              padding: EdgeInsets.fromLTRB(
                1.5.rem,
                0.75.rem,
                1.5.rem,
                0.75.rem,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    text: 'Start ranking',
                    variant: AppButtonVariant.primary,
                    onPressed: canStartRanking ? _handleStartRanking : null,
                  ),
                  SizedBox(height: 0.25.rem),
                  AppLinkButton(
                    text: 'Do this later',
                    onPressed: _handleDoThisLater,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        'YOUR PLACES',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSearchSuggestions(List<OnboardingPlace> matches) {
    return Material(
      color: AppColors.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.0),
        side: const BorderSide(color: AppColors.border),
      ),
      child: Column(
        children: matches.map((place) {
          return ListTile(
            dense: true,
            leading: Icon(place.icon, size: 20, color: AppColors.iconSecondary),
            title: Text(
              place.name,
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            subtitle: Text(
              '${place.neighborhood} · ${place.shortCategory}',
              style: GoogleFonts.poppins(
                fontSize: 0.75.rem,
                color: AppColors.textSecondary,
              ),
            ),
            trailing: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primaryAction,
              size: 20,
            ),
            onTap: () => _addPlace(place),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectedPlaceTile extends StatelessWidget {
  final OnboardingPlace place;
  final VoidCallback onRemove;

  const _SelectedPlaceTile({
    required this.place,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 0.875.rem,
        vertical: 0.875.rem,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primaryAction, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 3.0.rem, // 48 px
            height: 3.0.rem,
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Icon(
              place.icon,
              size: 22,
              color: AppColors.iconSecondary,
            ),
          ),
          SizedBox(width: 0.875.rem),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  place.name,
                  style: GoogleFonts.poppins(
                    fontSize: 0.9375.rem, // 15 px
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.125.rem),
                Text(
                  '${place.neighborhood} · ${place.shortCategory}',
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem, // 13 px
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            tooltip: 'Remove ${place.name}',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}

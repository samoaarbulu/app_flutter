import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/creds_api_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../models/onboarding_place.dart';
import 'compare_places_screen.dart';
import 'useful_permissions_screen.dart';

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
  final FocusNode _searchFocusNode = FocusNode();
  late final List<OnboardingPlace> _selectedPlaces;
  List<OnboardingPlace> _searchResults = const [];
  Timer? _searchDebounce;
  int _searchRequestId = 0;
  bool _isSearching = false;
  bool _isSubmitting = false;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    _selectedPlaces = List<OnboardingPlace>.from(
      widget.initialPlaces ?? const [],
    );
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _enterSearchMode() {
    if (_isSearchMode) return;
    setState(() => _isSearchMode = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocusNode.requestFocus();
    });
  }

  void _exitSearchMode() {
    _searchFocusNode.unfocus();
    if (!_isSearchMode) return;
    setState(() => _isSearchMode = false);
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      _searchRequestId++;
      setState(() {
        _searchResults = const [];
        _isSearching = false;
      });
      return;
    }

    if (!CredsApiService.instance.hasSession) {
      setState(() {
        _searchResults = _filterLocalCatalog(query);
        _isSearching = false;
      });
      return;
    }

    final requestId = ++_searchRequestId;
    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () {
      _executeRemoteSearch(query, requestId);
    });
  }

  List<OnboardingPlace> _filterLocalCatalog(String query) {
    final lower = query.toLowerCase();
    final selectedIds = _selectedPlaces.map((p) => p.id).toSet();
    return OnboardingPlace.sampleCatalog.where((place) {
      if (selectedIds.contains(place.id)) return false;
      return place.name.toLowerCase().contains(lower) ||
          place.neighborhood.toLowerCase().contains(lower) ||
          place.shortCategory.toLowerCase().contains(lower);
    }).toList();
  }

  Future<void> _executeRemoteSearch(String query, int requestId) async {
    try {
      final results = await CredsApiService.instance.searchPlaces(query: query);
      if (!mounted || requestId != _searchRequestId) return;

      final selectedIds = _selectedPlaces.map((p) => p.id).toSet();
      setState(() {
        _searchResults =
            results.where((p) => !selectedIds.contains(p.id)).toList();
        _isSearching = false;
      });
    } on CredsApiException catch (e) {
      if (!mounted || requestId != _searchRequestId) return;
      if (e.isNetworkOrOfflineError) {
        setState(() {
          _searchResults = _filterLocalCatalog(query);
          _isSearching = false;
        });
      } else {
        setState(() {
          _searchResults = const [];
          _isSearching = false;
        });
        AppFeedback.showError(context, e.message);
      }
    }
  }

  void _addPlace(OnboardingPlace place) {
    HapticFeedback.selectionClick();
    _searchDebounce?.cancel();
    _searchRequestId++;
    _searchFocusNode.unfocus();
    setState(() {
      _selectedPlaces.add(place);
      _searchResults = const [];
      _isSearching = false;
      _isSearchMode = false;
      _searchController.clear();
    });
  }

  void _removePlace(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPlaces.removeWhere((p) => p.id == id);
    });
  }

  Future<void> _handleStartRanking() async {
    if (_selectedPlaces.length < 3 || _isSubmitting) return;

    if (widget.onStartRanking != null) {
      widget.onStartRanking!(List<OnboardingPlace>.from(_selectedPlaces));
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isSubmitting = true);
      try {
        await CredsApiService.instance.prepareOnboardingDuels(
          _selectedPlaces.map((p) => p.id).toList(),
        );
      } on CredsApiException catch (e) {
        if (!mounted) return;
        if (!e.isNetworkOrOfflineError) {
          setState(() => _isSubmitting = false);
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ComparePlacesScreen(
          places: List<OnboardingPlace>.from(_selectedPlaces),
        ),
      ),
    );
  }

  Future<void> _handleDoThisLater() async {
    if (_isSubmitting) return;

    if (widget.onDoThisLater != null) {
      widget.onDoThisLater!();
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isSubmitting = true);
      try {
        await CredsApiService.instance.skipOnboardingRanking();
      } on CredsApiException catch (e) {
        if (!mounted) return;
        if (!e.isNetworkOrOfflineError) {
          setState(() => _isSubmitting = false);
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UsefulPermissionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchMatches = _searchResults;
    final canStartRanking = _selectedPlaces.length >= 3;

    return PopScope(
      canPop: !_isSearchMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isSearchMode) {
          _exitSearchMode();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _isSearchMode ? null : _buildAppBar(context),
        body: SafeArea(
          child: _isSearchMode
              ? _buildFocusedSearchView(searchMatches)
              : Column(
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
                              onTap: _enterSearchMode,
                            ),

                            if (_isSearching) ...[
                              SizedBox(height: 0.5.rem),
                              const LinearProgressIndicator(
                                minHeight: 2,
                                color: AppColors.primaryAction,
                                backgroundColor: AppColors.inputSurface,
                              ),
                            ] else if (searchMatches.isNotEmpty) ...[
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
                    isLoading: _isSubmitting,
                    onPressed:
                        (canStartRanking && !_isSubmitting) ? _handleStartRanking : null,
                  ),
                  SizedBox(height: 0.25.rem),
                  AppLinkButton(
                    text: 'Do this later',
                    onPressed: _isSubmitting ? null : _handleDoThisLater,
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

  /// Vista enfocada de búsqueda (estilo Instagram/Rappi) cuando el usuario toca el buscador.
  Widget _buildFocusedSearchView(List<OnboardingPlace> searchMatches) {
    final query = _searchController.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(0.5.rem, 0.75.rem, 1.5.rem, 0.5.rem),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                  size: 24,
                ),
                onPressed: _exitSearchMode,
              ),
              Expanded(
                child: AppTextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: "Search places you've been",
                  prefixIcon: const Icon(Icons.search_rounded, size: 22),
                  suffixIcon: query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        if (_isSearching)
          const LinearProgressIndicator(
            minHeight: 2,
            color: AppColors.primaryAction,
            backgroundColor: AppColors.inputSurface,
          ),
        Expanded(
          child: query.isEmpty
              ? Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
                    child: Text(
                      'Type a gym, studio or spot name to search.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 0.875.rem,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                )
              : searchMatches.isEmpty && !_isSearching
                  ? Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
                        child: Text(
                          'No places found for "$query".',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(
                            fontSize: 0.875.rem,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: EdgeInsets.symmetric(
                        horizontal: 1.5.rem,
                        vertical: 0.5.rem,
                      ),
                      itemCount: searchMatches.length,
                      separatorBuilder: (_, _) =>
                          const Divider(height: 1, color: AppColors.border),
                      itemBuilder: (context, index) {
                        final place = searchMatches[index];
                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 0.25.rem,
                            vertical: 0.125.rem,
                          ),
                          leading: Icon(
                            place.icon,
                            size: 22,
                            color: AppColors.iconSecondary,
                          ),
                          title: Text(
                            place.name,
                            style: GoogleFonts.poppins(
                              fontSize: 0.9375.rem,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            '${place.neighborhood} · ${place.shortCategory}',
                            style: GoogleFonts.poppins(
                              fontSize: 0.8125.rem,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.add_circle_outline_rounded,
                            color: AppColors.primaryAction,
                            size: 22,
                          ),
                          onTap: () => _addPlace(place),
                        );
                      },
                    ),
        ),
      ],
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

@Preview(
  name: 'Your Places Screen',
  size: Size(390, 844),
)
Widget previewYourPlacesScreen() {
  return const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: YourPlacesScreen(),
  );
}

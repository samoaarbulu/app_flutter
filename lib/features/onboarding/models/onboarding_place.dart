import 'package:flutter/material.dart';

/// Modelo de un lugar/gimnasio usado en el flujo de primer ranking (Paso 08).
class OnboardingPlace {
  final String id;
  final String name;
  final String neighborhood;
  final String address;
  final String activitiesLabel;
  final String shortCategory;
  final IconData icon;

  const OnboardingPlace({
    required this.id,
    required this.name,
    required this.neighborhood,
    required this.address,
    required this.activitiesLabel,
    required this.shortCategory,
    this.icon = Icons.fitness_center_outlined,
  });

  /// Crea un [OnboardingPlace] a partir de `NearbyPlaceItemDto` del backend.
  factory OnboardingPlace.fromApiJson(Map<String, dynamic> json) {
    final category = (json['category'] as String?)?.trim();
    final brandName = (json['brandName'] as String?)?.trim();
    final locality = (json['locality'] as String?)?.trim();
    final region = (json['region'] as String?)?.trim();
    final country = (json['country'] as String?)?.trim();
    final address = (json['address'] as String?)?.trim() ?? '';

    final neighborhood = (locality != null && locality.isNotEmpty)
        ? locality
        : (region != null && region.isNotEmpty)
            ? region
            : (country != null && country.isNotEmpty)
                ? country
                : 'Nearby';

    final rawCategory = (category != null && category.isNotEmpty)
        ? category
        : (brandName != null && brandName.isNotEmpty)
            ? brandName
            : 'Gym';

    final shortCategory = _formatCategory(rawCategory);

    return OnboardingPlace(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      neighborhood: neighborhood,
      address: address,
      activitiesLabel: shortCategory,
      shortCategory: shortCategory,
      icon: _iconForCategory(rawCategory),
    );
  }

  /// Crea un [OnboardingPlace] a partir de `DuelPlaceCardDto` del backend.
  factory OnboardingPlace.fromDuelCardJson(Map<String, dynamic> json) {
    final category = (json['category'] as String?)?.trim();
    final locality = (json['locality'] as String?)?.trim();
    final address = (json['address'] as String?)?.trim() ?? '';
    final activitiesLabel = (json['activitiesLabel'] as String?)?.trim();
    final rawCategory =
        (category != null && category.isNotEmpty) ? category : 'Gym';
    final shortCategory = _formatCategory(rawCategory);

    return OnboardingPlace(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      neighborhood:
          (locality != null && locality.isNotEmpty) ? locality : 'Nearby',
      address: address,
      activitiesLabel: (activitiesLabel != null && activitiesLabel.isNotEmpty)
          ? activitiesLabel
          : shortCategory,
      shortCategory: shortCategory,
      icon: _iconForCategory(rawCategory),
    );
  }

  static String _formatCategory(String raw) {
    final normalized = raw.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Gym';
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  static IconData _iconForCategory(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('pilates') || lower.contains('yoga')) {
      return Icons.self_improvement_outlined;
    }
    if (lower.contains('cycling') || lower.contains('bike')) {
      return Icons.directions_bike_rounded;
    }
    if (lower.contains('crossfit') || lower.contains('hiit')) {
      return Icons.flash_on_rounded;
    }
    if (lower.contains('climb')) {
      return Icons.terrain_outlined;
    }
    return Icons.fitness_center_outlined;
  }

  /// Lugares preseleccionados por defecto para mostrar el flujo completo.
  static const List<OnboardingPlace> defaultSelected = [
    OnboardingPlace(
      id: 'atlas_fitness',
      name: 'Atlas Fitness',
      neighborhood: 'Roma Norte',
      address: 'Colima 145',
      activitiesLabel: 'Strength · Functional training',
      shortCategory: 'Strength',
      icon: Icons.fitness_center_outlined,
    ),
    OnboardingPlace(
      id: 'distrito_fuerza',
      name: 'Distrito Fuerza',
      neighborhood: 'Condesa',
      address: 'Tamaulipas 84',
      activitiesLabel: 'Strength · Cross training',
      shortCategory: 'Strength',
      icon: Icons.fitness_center_outlined,
    ),
    OnboardingPlace(
      id: 'norte_club',
      name: 'Norte Club',
      neighborhood: 'Juárez',
      address: 'Liverpool 32',
      activitiesLabel: 'Cardio · Classes',
      shortCategory: 'Cardio',
      icon: Icons.fitness_center_outlined,
    ),
  ];

  /// Catálogo local de búsqueda mientras se conecta el buscador de lugares al backend.
  static const List<OnboardingPlace> sampleCatalog = [
    ...defaultSelected,
    OnboardingPlace(
      id: 'koa_studio',
      name: 'Koa Studio',
      neighborhood: 'Polanco',
      address: 'Masaryk 210',
      activitiesLabel: 'Pilates · Yoga',
      shortCategory: 'Pilates',
      icon: Icons.self_improvement_outlined,
    ),
    OnboardingPlace(
      id: 'bunker_crossfit',
      name: 'Bunker CrossFit',
      neighborhood: 'Del Valle',
      address: 'Insurgentes Sur 940',
      activitiesLabel: 'CrossFit · HIIT',
      shortCategory: 'CrossFit',
      icon: Icons.flash_on_rounded,
    ),
    OnboardingPlace(
      id: 'tempo_cycling',
      name: 'Tempo Cycling',
      neighborhood: 'Roma Sur',
      address: 'Medellín 198',
      activitiesLabel: 'Cycling · Cardio',
      shortCategory: 'Cycling',
      icon: Icons.directions_bike_rounded,
    ),
    OnboardingPlace(
      id: 'summit_climbing',
      name: 'Summit Climbing',
      neighborhood: 'Nápoles',
      address: 'Dakota 112',
      activitiesLabel: 'Strength · Mobility',
      shortCategory: 'Climbing',
      icon: Icons.terrain_outlined,
    ),
  ];
}

/// Resultado ordenado de un lugar tras completar las comparaciones iniciales.
class RankedPlace {
  final OnboardingPlace place;
  final int wins;
  final int totalComparisons;
  final int? rankPosition;
  final String? rankLabel;
  final double? score;
  final String? summaryLabel;
  final bool isTopChoice;

  const RankedPlace({
    required this.place,
    required this.wins,
    required this.totalComparisons,
    this.rankPosition,
    this.rankLabel,
    this.score,
    this.summaryLabel,
    this.isTopChoice = false,
  });

  /// Crea un [RankedPlace] a partir de `RankedPlaceItemDto` del backend.
  factory RankedPlace.fromApiJson(Map<String, dynamic> json) {
    final placeJson = json['place'];
    final place = placeJson is Map<String, dynamic>
        ? OnboardingPlace.fromDuelCardJson(placeJson)
        : const OnboardingPlace(
            id: '',
            name: '',
            neighborhood: '',
            address: '',
            activitiesLabel: '',
            shortCategory: 'Gym',
          );

    return RankedPlace(
      place: place,
      wins: (json['winsCount'] as num?)?.toInt() ?? 0,
      totalComparisons: (json['comparisonsCount'] as num?)?.toInt() ?? 0,
      rankPosition: (json['rankPosition'] as num?)?.toInt(),
      rankLabel: json['rankLabel'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      summaryLabel: json['summaryLabel'] as String?,
      isTopChoice: json['isTopChoice'] as bool? ?? false,
    );
  }
}

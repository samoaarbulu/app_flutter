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

  const RankedPlace({
    required this.place,
    required this.wins,
    required this.totalComparisons,
  });
}

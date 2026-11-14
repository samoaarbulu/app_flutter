import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../home/screens/home_screen.dart';
import '../../../core/services/creds_api_service.dart';

/// Modelo inmutable para representar una actividad física en el onboarding.
class ActivityOption {
  final String id;
  final String title;
  final IconData icon;

  const ActivityOption({
    required this.id,
    required this.title,
    required this.icon,
  });
}

/// Pantalla de Selección de Actividades ("How do you like to train?").
///
/// Reutiliza [AppHeader] y [AppButton] del Design System de Creds.
/// Permite seleccionar múltiples actividades mediante tarjetas interactivas en cuadrícula
/// y actualiza dinámicamente el texto del botón principal según la cantidad elegida.
class ActivitiesScreen extends StatefulWidget {
  final ValueChanged<List<String>>? onContinue;
  final List<String>? initialSelectedIds;

  const ActivitiesScreen({
    super.key,
    this.onContinue,
    this.initialSelectedIds,
  });

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  static IconData _iconForKey(String iconKey) {
    return switch (iconKey) {
      'dumbbell' => Icons.fitness_center_outlined,
      'flame' => Icons.local_fire_department_outlined,
      'reformer' => Icons.self_improvement_outlined,
      'lotus' => Icons.spa_outlined,
      'runner' => Icons.directions_run_rounded,
      'footprints' => Icons.directions_walk_rounded,
      'music_note' => Icons.music_note_rounded,
      'padel_racquet' => Icons.sports_tennis_outlined,
      'tennis_ball' => Icons.sports_baseball_outlined,
      'boxing_glove' => Icons.sports_mma_outlined,
      'sparkles' => Icons.auto_awesome_outlined,
      'wind' => Icons.air_rounded,
      'sound_wave' => Icons.graphic_eq_rounded,
      'snowflake' => Icons.ac_unit_rounded,
      'thermometer_hot' => Icons.thermostat_rounded,
      'golf_flag' => Icons.golf_course_rounded,
      'ballet' => Icons.accessibility_new_rounded,
      'bike' => Icons.directions_bike_rounded,
      'whistle' => Icons.timer_outlined,
      'kettlebell' => Icons.flash_on_rounded,
      'martial_arts' => Icons.sports_kabaddi_outlined,
      'heart_pulse' => Icons.monitor_heart_outlined,
      _ => Icons.fitness_center_outlined,
    };
  }

  static final List<ActivityOption> _defaultActivities = [
    ActivityOption(
      id: 'strength_training',
      title: 'Strength training',
      icon: _iconForKey('dumbbell'),
    ),
    ActivityOption(
      id: 'hiit',
      title: 'HIIT',
      icon: _iconForKey('flame'),
    ),
    ActivityOption(
      id: 'pilates',
      title: 'Pilates',
      icon: _iconForKey('reformer'),
    ),
    ActivityOption(
      id: 'yoga',
      title: 'Yoga',
      icon: _iconForKey('lotus'),
    ),
    ActivityOption(
      id: 'running',
      title: 'Running',
      icon: _iconForKey('runner'),
    ),
    ActivityOption(
      id: 'walking',
      title: 'Walking',
      icon: _iconForKey('footprints'),
    ),
    ActivityOption(
      id: 'dance',
      title: 'Dance',
      icon: _iconForKey('music_note'),
    ),
    ActivityOption(
      id: 'padel',
      title: 'Padel',
      icon: _iconForKey('padel_racquet'),
    ),
    ActivityOption(
      id: 'tennis',
      title: 'Tennis',
      icon: _iconForKey('tennis_ball'),
    ),
    ActivityOption(
      id: 'boxing',
      title: 'Boxing',
      icon: _iconForKey('boxing_glove'),
    ),
    ActivityOption(
      id: 'meditation',
      title: 'Meditation',
      icon: _iconForKey('sparkles'),
    ),
    ActivityOption(
      id: 'breathwork',
      title: 'Breathwork',
      icon: _iconForKey('wind'),
    ),
    ActivityOption(
      id: 'soundbath',
      title: 'Soundbath',
      icon: _iconForKey('sound_wave'),
    ),
    ActivityOption(
      id: 'ice_plunge',
      title: 'Ice plunge',
      icon: _iconForKey('snowflake'),
    ),
    ActivityOption(
      id: 'sauna',
      title: 'Sauna',
      icon: _iconForKey('thermometer_hot'),
    ),
    ActivityOption(
      id: 'golf',
      title: 'Golf',
      icon: _iconForKey('golf_flag'),
    ),
    ActivityOption(
      id: 'barre',
      title: 'Barre',
      icon: _iconForKey('ballet'),
    ),
    ActivityOption(
      id: 'cycling',
      title: 'Cycling',
      icon: _iconForKey('bike'),
    ),
    ActivityOption(
      id: 'bootcamp',
      title: 'Bootcamp',
      icon: _iconForKey('whistle'),
    ),
    ActivityOption(
      id: 'cross_fit',
      title: 'CrossFit',
      icon: _iconForKey('kettlebell'),
    ),
    ActivityOption(
      id: 'martial_arts',
      title: 'Martial arts',
      icon: _iconForKey('martial_arts'),
    ),
    ActivityOption(
      id: 'recovery',
      title: 'Recovery',
      icon: _iconForKey('heart_pulse'),
    ),
  ];

  late List<ActivityOption> _activities;
  late final Set<String> _selectedIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _activities = List<ActivityOption>.from(_defaultActivities);
    _selectedIds = Set<String>.from(widget.initialSelectedIds ?? const []);
    _syncCatalogFromBackend();
  }

  Future<void> _syncCatalogFromBackend() async {
    try {
      final remoteItems = await CredsApiService.instance.getActivitiesCatalog();
      if (!mounted || remoteItems.isEmpty) return;

      final mapped = remoteItems
          .map(
            (item) => ActivityOption(
              id: item.code,
              title: item.label,
              icon: _iconForKey(item.iconKey),
            ),
          )
          .toList();

      setState(() {
        _activities = mapped;
      });
    } on CredsApiException catch (e) {
      if (!e.isNetworkOrOfflineError) {
        debugPrint('⚠️ Error cargando catálogo remoto de actividades: ${e.message}');
      }
    } catch (_) {
      // Mantiene el catálogo oficial local en modo offline/test.
    }
  }

  void _toggleActivity(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  String get _buttonText {
    final count = _selectedIds.length;
    if (count == 0) return 'Continue';
    if (count == 1) return 'Continue with 1 activity';
    return 'Continue with $count activities';
  }

  Future<void> _handleContinue() async {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoading = true);
    final selectedList = _selectedIds.toList();

    try {
      await CredsApiService.instance.updatePreferences(
        activityCodes: selectedList,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onContinue != null) {
        widget.onContinue!(selectedList);
      } else {
        AppFeedback.showSuccess(
          context,
          'Actividades guardadas (${selectedList.length})',
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (e.isNetworkOrOfflineError &&
          CredsApiService.instance.offlineFallbackEnabled) {
        debugPrint('⚠️ Backend offline en ActivitiesScreen: ${e.message}');
        if (widget.onContinue != null) {
          widget.onContinue!(selectedList);
        } else {
          AppFeedback.showSuccess(
            context,
            'Actividades guardadas (${selectedList.length})',
          );
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
        return;
      }

      AppFeedback.showError(context, e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppFeedback.showError(context, 'Error al guardar actividades: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(context),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Contenido desplazable: Encabezado + Cuadrícula de actividades
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      1.5.rem,
                      0.5.rem,
                      1.5.rem,
                      1.5.rem,
                    ),
                    sliver: SliverToBoxAdapter(
                      child: const AppHeader(
                        title: 'How do you like to train?',
                        description:
                            'Choose your usual activities. You can select more than one.',
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                      1.5.rem,
                      0,
                      1.5.rem,
                      1.5.rem,
                    ),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 0.75.rem, // 12 px
                        mainAxisSpacing: 0.75.rem, // 12 px
                        childAspectRatio: 1.48,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final activity = _activities[index];
                          final isSelected = _selectedIds.contains(activity.id);
                          return _ActivityCard(
                            activity: activity,
                            isSelected: isSelected,
                            onTap: () => _toggleActivity(activity.id),
                          );
                        },
                        childCount: _activities.length,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Pie fijo con botón principal (sin el label inferior)
            _buildBottomFooter(),
          ],
        ),
      ),
    );
  }

  /// Barra superior con botón atrás y título centrado "ACTIVITIES"
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
        'ACTIVITIES',
        style: GoogleFonts.poppins(
          fontSize: 0.8125.rem, // 13 px
          fontWeight: FontWeight.w700,
          letterSpacing: 2.0,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  /// Pie fijo con el componente reutilizable AppButton
  Widget _buildBottomFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        1.5.rem,
        0.75.rem,
        1.5.rem,
        1.0.rem,
      ),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: AppButton(
        text: _buttonText,
        variant: AppButtonVariant.primary,
        isLoading: _isLoading,
        onPressed: _selectedIds.isNotEmpty ? _handleContinue : null,
      ),
    );
  }
}

/// Tarjeta individual seleccionable de actividad física.
class _ActivityCard extends StatelessWidget {
  final ActivityOption activity;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16.0),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.all(1.0.rem), // 16 px
          decoration: BoxDecoration(
            color: isSelected ? AppColors.inputSurface : AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: isSelected ? AppColors.primaryAction : AppColors.border,
              width: isSelected ? 1.8 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Fila superior: Icono de la actividad y checkbox de selección
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    activity.icon,
                    size: 24,
                    color: AppColors.textPrimary,
                  ),
                  _SelectionCheckbox(isSelected: isSelected),
                ],
              ),

              // Título de la actividad
              Text(
                activity.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 0.9375.rem, // 15 px
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Indicador de checkbox redondeado con animación de estado.
class _SelectionCheckbox extends StatelessWidget {
  final bool isSelected;

  const _SelectionCheckbox({required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryAction : Colors.transparent,
        borderRadius: BorderRadius.circular(7.0),
        border: isSelected
            ? null
            : Border.all(
                color: AppColors.border,
                width: 1.5,
              ),
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              size: 16,
              color: AppColors.onPrimary,
            )
          : null,
    );
  }
}

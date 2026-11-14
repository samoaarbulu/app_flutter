import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_feedback.dart';
import '../../../../core/utils/app_rem.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_header.dart';

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
  static const List<ActivityOption> _defaultActivities = [
    ActivityOption(
      id: 'strength',
      title: 'Strength',
      icon: Icons.fitness_center_outlined,
    ),
    ActivityOption(
      id: 'functional',
      title: 'Functional training',
      icon: Icons.show_chart_rounded,
    ),
    ActivityOption(
      id: 'cardio',
      title: 'Cardio',
      icon: Icons.monitor_heart_outlined,
    ),
    ActivityOption(
      id: 'cross_training',
      title: 'Cross training',
      icon: Icons.timer_outlined,
    ),
    ActivityOption(
      id: 'yoga_pilates',
      title: 'Yoga / Pilates',
      icon: Icons.self_improvement_outlined,
    ),
    ActivityOption(
      id: 'group_classes',
      title: 'Group classes',
      icon: Icons.people_outline_rounded,
    ),
    ActivityOption(
      id: 'running',
      title: 'Running',
      icon: Icons.directions_run_rounded,
    ),
    ActivityOption(
      id: 'cycling',
      title: 'Cycling',
      icon: Icons.directions_bike_rounded,
    ),
    ActivityOption(
      id: 'swimming',
      title: 'Swimming',
      icon: Icons.pool_rounded,
    ),
    ActivityOption(
      id: 'mobility',
      title: 'Mobility',
      icon: Icons.accessibility_new_rounded,
    ),
  ];

  late final Set<String> _selectedIds;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set<String>.from(widget.initialSelectedIds ?? const []);
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

  void _handleContinue() {
    if (_selectedIds.isEmpty) return;

    setState(() => _isLoading = true);
    final selectedList = _selectedIds.toList();

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (widget.onContinue != null) {
        widget.onContinue!(selectedList);
      } else {
        AppFeedback.showSuccess(
          context,
          'Actividades guardadas (${selectedList.length})',
        );
      }
    });
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
                          final activity = _defaultActivities[index];
                          final isSelected = _selectedIds.contains(activity.id);
                          return _ActivityCard(
                            activity: activity,
                            isSelected: isSelected,
                            onTap: () => _toggleActivity(activity.id),
                          );
                        },
                        childCount: _defaultActivities.length,
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

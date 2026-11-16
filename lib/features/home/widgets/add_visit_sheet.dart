import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';

enum VisitSentiment { lovedIt, good, didntLikeIt }

enum _AddVisitStep { main, tags, notes, activities, date, versus }

/// Resultado devuelto al completar el flujo de agregar una visita (`03 agregar visita`).
class AddVisitResult {
  final String placeName;
  final String location;
  final double rating;
  final List<String> tags;
  final String notes;
  final List<String> activities;
  final List<PickedImage> photos;
  final DateTime visitDate;
  final String listCategory;

  const AddVisitResult({
    required this.placeName,
    required this.location,
    required this.rating,
    required this.tags,
    required this.notes,
    required this.activities,
    required this.photos,
    required this.visitDate,
    required this.listCategory,
  });
}

/// Bottom sheet multipaso para registrar una visita (`03 Home/03 agregar visita`).
class AddVisitSheet extends StatefulWidget {
  final String placeName;
  final String placeSubtitle;
  final String fullLocation;

  const AddVisitSheet({
    super.key,
    required this.placeName,
    required this.placeSubtitle,
    required this.fullLocation,
  });

  /// Abre el modal sheet y retorna [AddVisitResult] si el usuario completa la visita.
  static Future<AddVisitResult?> show(
    BuildContext context, {
    required String placeName,
    required String placeSubtitle,
    required String fullLocation,
  }) {
    return showModalBottomSheet<AddVisitResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddVisitSheet(
        placeName: placeName,
        placeSubtitle: placeSubtitle,
        fullLocation: fullLocation,
      ),
    );
  }

  @override
  State<AddVisitSheet> createState() => _AddVisitSheetState();
}

class _AddVisitSheetState extends State<AddVisitSheet> {
  static const List<String> _listOptions = [
    'Gym',
    'Studio',
    'Pilates studio',
    'Yoga studio',
    'Other',
  ];

  static const List<String> _availableTags = [
    'Great place',
    'Atmosphere',
    'Professional',
    'Popular',
    'Great instructors',
    'Fun',
    'Great service',
    'TOP classes',
  ];

  static const List<String> _availableActivities = [
    'Exercise',
    'Pilates',
    'Dance',
    'Running',
    'Cross fit',
    'Yoga',
    'Strength training',
    'Cycling',
  ];

  static const List<String> _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _shortMonthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  _AddVisitStep _step = _AddVisitStep.main;

  VisitSentiment _sentiment = VisitSentiment.lovedIt;
  String _selectedList = 'Gym';
  final Set<String> _selectedTags = {'Great place'};
  final Set<String> _selectedActivities = {'Exercise'};
  final List<PickedImage> _selectedPhotos = [];
  String _notes = '';
  DateTime _selectedDate = DateTime.now();
  late DateTime _calendarMonth;

  // Estado temporal de sub-pasos
  final TextEditingController _tagSearchController = TextEditingController();
  late TextEditingController _notesController;
  String _tagQuery = '';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _calendarMonth = DateTime(now.year, now.month, 1);
    _notesController = TextEditingController(text: _notes);
    _tagSearchController.addListener(() {
      setState(() => _tagQuery = _tagSearchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tagSearchController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String get _districtLabel {
    final parts = widget.fullLocation
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    return parts.isNotEmpty ? parts.first : widget.fullLocation;
  }

  ({String name, String district}) get _versusOpponent {
    if (widget.placeName.toLowerCase().contains('urban gym')) {
      return (name: 'Atlas Fitness', district: 'Jesús María');
    }
    return (name: 'Urban Gym', district: 'Miraflores');
  }

  String _formatShortDate(DateTime date) {
    final month = _shortMonthNames[date.month - 1];
    return '$month ${date.day}';
  }

  String _formatFullDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final month = _shortMonthNames[date.month - 1];
    final formatted = '$month ${date.day}, ${date.year}';
    if (date == today) {
      return 'Today · $formatted';
    }
    return formatted;
  }

  Future<void> _pickPhoto() async {
    final picked = await MediaService.instance.pickImageFromGallery();
    if (!mounted) return;
    if (picked != null) {
      setState(() => _selectedPhotos.add(picked));
    } else {
      AppFeedback.show(context, 'No photo selected');
    }
  }

  double _computeRating({required String? versusChoice}) {
    final base = switch (_sentiment) {
      VisitSentiment.lovedIt => 8.5,
      VisitSentiment.good => 7.2,
      VisitSentiment.didntLikeIt => 4.8,
    };
    if (versusChoice == widget.placeName) {
      return (base + 0.5).clamp(1.0, 10.0);
    }
    if (versusChoice == _versusOpponent.name) {
      return (base - 0.3).clamp(1.0, 10.0);
    }
    return base;
  }

  void _completeVisit({String? versusChoice}) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      AddVisitResult(
        placeName: widget.placeName,
        location: widget.fullLocation,
        rating: _computeRating(versusChoice: versusChoice),
        tags: _selectedTags.toList(),
        notes: _notes.trim(),
        activities: _selectedActivities.toList(),
        photos: List<PickedImage>.from(_selectedPhotos),
        visitDate: _selectedDate,
        listCategory: _selectedList,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 0.625.rem),
              // Drag handle
              Container(
                width: 2.5.rem,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: switch (_step) {
                  _AddVisitStep.main => _buildMainStep(),
                  _AddVisitStep.tags => _buildTagsStep(),
                  _AddVisitStep.notes => _buildNotesStep(),
                  _AddVisitStep.activities => _buildActivitiesStep(),
                  _AddVisitStep.date => _buildDateStep(),
                  _AddVisitStep.versus => _buildVersusStep(),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainStep() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón cerrar 'X' arriba a la derecha
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: 'Close',
              onPressed: () => Navigator.of(context).pop(),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              icon: const Icon(
                Icons.close_rounded,
                color: AppColors.textPrimary,
                size: 22,
              ),
            ),
          ),

          SizedBox(height: 0.25.rem),

          // Tarjeta del lugar
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: 1.0.rem,
              vertical: 0.875.rem,
            ),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(14.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.placeName,
                  style: GoogleFonts.poppins(
                    fontSize: 0.9375.rem, // 15 px
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.125.rem),
                Text(
                  widget.placeSubtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 0.75.rem, // 12 px
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 1.25.rem),

          Text(
            'How was it?',
            style: GoogleFonts.poppins(
              fontSize: 0.9375.rem,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 0.75.rem),

          Row(
            children: [
              Expanded(
                child: _SentimentTile(
                  symbol: '+',
                  label: 'Loved it',
                  isSelected: _sentiment == VisitSentiment.lovedIt,
                  onTap: () =>
                      setState(() => _sentiment = VisitSentiment.lovedIt),
                ),
              ),
              SizedBox(width: 0.625.rem),
              Expanded(
                child: _SentimentTile(
                  symbol: '=',
                  label: 'Good',
                  isSelected: _sentiment == VisitSentiment.good,
                  onTap: () => setState(() => _sentiment = VisitSentiment.good),
                ),
              ),
              SizedBox(width: 0.625.rem),
              Expanded(
                child: _SentimentTile(
                  symbol: '−',
                  label: "Didn't like it",
                  isSelected: _sentiment == VisitSentiment.didntLikeIt,
                  onTap: () =>
                      setState(() => _sentiment = VisitSentiment.didntLikeIt),
                ),
              ),
            ],
          ),

          SizedBox(height: 1.25.rem),

          Text(
            'Which list would you add it to?',
            style: GoogleFonts.poppins(
              fontSize: 0.875.rem,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          SizedBox(height: 0.625.rem),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _listOptions.map((option) {
                final isSelected = _selectedList == option;
                return Padding(
                  padding: EdgeInsets.only(right: 0.5.rem),
                  child: ChoiceChip(
                    label: Text(option),
                    selected: isSelected,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _selectedList = option),
                    labelStyle: GoogleFonts.poppins(
                      fontSize: 0.75.rem,
                      fontWeight: FontWeight.w500,
                      color: isSelected
                          ? AppColors.onPrimary
                          : AppColors.textPrimary,
                    ),
                    backgroundColor: AppColors.surface,
                    selectedColor: AppColors.primaryAction,
                    side: BorderSide(
                      color: isSelected
                          ? AppColors.primaryAction
                          : AppColors.border,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: 0.75.rem),
          const Divider(color: AppColors.border, height: 1),
          SizedBox(height: 0.375.rem),

          // Add tags
          _DetailActionRow(
            icon: Icons.local_offer_outlined,
            label: 'Add tags',
            onTap: () => setState(() => _step = _AddVisitStep.tags),
          ),
          if (_selectedTags.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.rem),
              child: Wrap(
                spacing: 0.375.rem,
                runSpacing: 0.375.rem,
                children: _selectedTags
                    .map((tag) => _SmallValueChip(label: tag))
                    .toList(),
              ),
            ),

          // Add notes
          _DetailActionRow(
            icon: Icons.article_outlined,
            label: 'Add notes',
            onTap: () {
              _notesController.text = _notes;
              setState(() => _step = _AddVisitStep.notes);
            },
          ),
          if (_notes.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.rem),
              child: Text(
                _notes.trim(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 0.75.rem,
                  color: AppColors.textSecondary,
                ),
              ),
            ),

          // Add activities
          _DetailActionRow(
            icon: Icons.fitness_center_outlined,
            label: 'Add activities',
            onTap: () => setState(() => _step = _AddVisitStep.activities),
          ),
          if (_selectedActivities.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.rem),
              child: Wrap(
                spacing: 0.375.rem,
                runSpacing: 0.375.rem,
                children: _selectedActivities
                    .map((act) => _SmallValueChip(label: act))
                    .toList(),
              ),
            ),

          // Add photos
          _DetailActionRow(
            icon: Icons.camera_alt_outlined,
            label: 'Add photos',
            onTap: _pickPhoto,
          ),
          if (_selectedPhotos.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 0.5.rem),
              child: SizedBox(
                height: 3.5.rem,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedPhotos.length,
                  separatorBuilder: (_, _) => SizedBox(width: 0.5.rem),
                  itemBuilder: (_, index) => ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _selectedPhotos[index].bytes,
                      width: 3.5.rem,
                      height: 3.5.rem,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

          // When did you go?
          _DetailActionRow(
            icon: Icons.location_on_outlined,
            label: 'When did you go?',
            onTap: () => setState(() => _step = _AddVisitStep.date),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 1.0.rem),
            child: Text(
              _formatShortDate(_selectedDate),
              style: GoogleFonts.poppins(
                fontSize: 0.75.rem,
                color: AppColors.textSecondary,
              ),
            ),
          ),

          AppButton(
            text: 'Add',
            onPressed: () {
              HapticFeedback.selectionClick();
              setState(() => _step = _AddVisitStep.versus);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSubHeader({
    required String title,
    String actionLabel = 'Done',
    required VoidCallback onBack,
    required VoidCallback onAction,
  }) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0.75.rem, 0.25.rem, 1.0.rem, 0.5.rem),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Back',
            onPressed: onBack,
            icon: const Icon(
              Icons.chevron_left_rounded,
              color: AppColors.textPrimary,
              size: 26,
            ),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 0.9375.rem,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel,
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagsStep() {
    final filteredTags = _availableTags
        .where((tag) => tag.toLowerCase().contains(_tagQuery))
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Add tags',
          onBack: () => setState(() => _step = _AddVisitStep.main),
          onAction: () => setState(() => _step = _AddVisitStep.main),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tagSearchController,
                  style: GoogleFonts.poppins(
                    fontSize: 0.875.rem,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search tags',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 0.875.rem,
                      color: AppColors.textSecondary,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    filled: true,
                    fillColor: AppColors.inputSurface,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 1.0.rem,
                      vertical: 0.75.rem,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14.0),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                SizedBox(height: 1.25.rem),
                Text(
                  'Most used',
                  style: GoogleFonts.poppins(
                    fontSize: 0.875.rem,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.5.rem),
                ...filteredTags.map((tag) {
                  final isSelected = _selectedTags.contains(tag);
                  return Column(
                    children: [
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTags.remove(tag);
                            } else {
                              _selectedTags.add(tag);
                            }
                          });
                        },
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 0.75.rem),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tag,
                                      style: GoogleFonts.poppins(
                                        fontSize: 0.875.rem,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    Text(
                                      '100 uses',
                                      style: GoogleFonts.poppins(
                                        fontSize: 0.75.rem,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _SquareCheckbox(isChecked: isSelected),
                            ],
                          ),
                        ),
                      ),
                      const Divider(color: AppColors.border, height: 1),
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Add notes',
          onBack: () => setState(() => _step = _AddVisitStep.main),
          onAction: () {
            setState(() {
              _notes = _notesController.text.trim();
              _step = _AddVisitStep.main;
            });
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(1.5.rem, 0.5.rem, 1.5.rem, 1.5.rem),
          child: Container(
            height: 11.0.rem,
            padding: EdgeInsets.all(1.0.rem),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14.0),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _notesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: GoogleFonts.poppins(
                fontSize: 0.875.rem,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Tell us what you thought...',
                hintStyle: GoogleFonts.poppins(
                  fontSize: 0.875.rem,
                  color: AppColors.textSecondary,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Add activities',
          onBack: () => setState(() => _step = _AddVisitStep.main),
          onAction: () => setState(() => _step = _AddVisitStep.main),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
            child: Column(
              children: _availableActivities.map((activity) {
                final isSelected = _selectedActivities.contains(activity);
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedActivities.remove(activity);
                          } else {
                            _selectedActivities.add(activity);
                          }
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.875.rem),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                activity,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.875.rem,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            _SquareCheckbox(isChecked: isSelected),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: AppColors.border, height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateStep() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final quickDates = [
      (label: 'Today', date: today),
      (label: 'Yesterday', date: today.subtract(const Duration(days: 1))),
      (label: '2 days ago', date: today.subtract(const Duration(days: 2))),
      (label: '3 days ago', date: today.subtract(const Duration(days: 3))),
    ];

    final daysInMonth =
        DateTime(_calendarMonth.year, _calendarMonth.month + 1, 0).day;
    final leadingEmptyDays = _calendarMonth.weekday - 1; // Monday = 0
    final totalCells = leadingEmptyDays + daysInMonth;
    final monthTitle =
        '${_monthNames[_calendarMonth.month - 1]} ${_calendarMonth.year}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'When did you go?',
          onBack: () => setState(() => _step = _AddVisitStep.main),
          onAction: () => setState(() => _step = _AddVisitStep.main),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
            child: Column(
              children: [
                // Quick date chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: quickDates.map((item) {
                      final isSelected = _selectedDate == item.date;
                      return Padding(
                        padding: EdgeInsets.only(right: 0.5.rem),
                        child: ChoiceChip(
                          label: Text(item.label),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) => setState(() {
                            _selectedDate = item.date;
                            _calendarMonth =
                                DateTime(item.date.year, item.date.month, 1);
                          }),
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 0.75.rem,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textPrimary,
                          ),
                          backgroundColor: AppColors.surface,
                          selectedColor: AppColors.primaryAction,
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.primaryAction
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: 1.0.rem),

                // Navegación de mes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month - 1,
                          1,
                        );
                      }),
                      icon: const Icon(
                        Icons.chevron_left_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      monthTitle,
                      style: GoogleFonts.poppins(
                        fontSize: 0.9375.rem,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() {
                        _calendarMonth = DateTime(
                          _calendarMonth.year,
                          _calendarMonth.month + 1,
                          1,
                        );
                      }),
                      icon: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 0.5.rem),

                // Encabezado días de la semana
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                      .map(
                        (day) => SizedBox(
                          width: 2.25.rem,
                          child: Center(
                            child: Text(
                              day,
                              style: GoogleFonts.poppins(
                                fontSize: 0.75.rem,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

                SizedBox(height: 0.5.rem),

                // Grilla de días del mes
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: totalCells,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemBuilder: (_, index) {
                    if (index < leadingEmptyDays) {
                      return const SizedBox.shrink();
                    }
                    final day = index - leadingEmptyDays + 1;
                    final cellDate = DateTime(
                      _calendarMonth.year,
                      _calendarMonth.month,
                      day,
                    );
                    final isSelected = _selectedDate == cellDate;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = cellDate),
                      child: Center(
                        child: Container(
                          width: 2.0.rem,
                          height: 2.0.rem,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primaryAction
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Center(
                            child: Text(
                              '$day',
                              style: GoogleFonts.poppins(
                                fontSize: 0.8125.rem,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.onPrimary
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 0.875.rem),

                Text(
                  _formatFullDate(_selectedDate),
                  style: GoogleFonts.poppins(
                    fontSize: 0.75.rem,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVersusStep() {
    final opponent = _versusOpponent;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Which place do you prefer?',
          actionLabel: 'Skip',
          onBack: () => setState(() => _step = _AddVisitStep.main),
          onAction: () => _completeVisit(versusChoice: null),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(1.5.rem, 0.75.rem, 1.5.rem, 1.5.rem),
          child: Column(
            children: [
              SizedBox(
                height: 11.5.rem,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _VersusPlaceCard(
                            title: widget.placeName,
                            subtitle: _districtLabel,
                            onTap: () =>
                                _completeVisit(versusChoice: widget.placeName),
                          ),
                        ),
                        SizedBox(width: 0.75.rem),
                        Expanded(
                          child: _VersusPlaceCard(
                            title: opponent.name,
                            subtitle: opponent.district,
                            onTap: () =>
                                _completeVisit(versusChoice: opponent.name),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 2.25.rem,
                      height: 2.25.rem,
                      decoration: BoxDecoration(
                        color: AppColors.badgeSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.background,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'VS',
                          style: GoogleFonts.poppins(
                            fontSize: 0.6875.rem,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 1.25.rem),
              OutlinedButton(
                onPressed: () => _completeVisit(versusChoice: null),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 1.5.rem,
                    vertical: 0.625.rem,
                  ),
                ),
                child: Text(
                  'Hard to decide',
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SentimentTile extends StatelessWidget {
  final String symbol;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SentimentTile({
    required this.symbol,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? AppColors.primaryAction : AppColors.surface,
      borderRadius: BorderRadius.circular(14.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.0),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.125.rem),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: isSelected ? AppColors.primaryAction : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                symbol,
                style: GoogleFonts.poppins(
                  fontSize: 1.5.rem,
                  fontWeight: FontWeight.w400,
                  color:
                      isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                  height: 1.1,
                ),
              ),
              SizedBox(height: 0.375.rem),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 0.75.rem,
                  fontWeight: FontWeight.w600,
                  color:
                      isSelected ? AppColors.onPrimary : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DetailActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 0.625.rem),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            SizedBox(width: 0.625.rem),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 0.875.rem,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.textPrimary,
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallValueChip extends StatelessWidget {
  final String label;

  const _SmallValueChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 0.625.rem,
        vertical: 0.25.rem,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 0.6875.rem,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _SquareCheckbox extends StatelessWidget {
  final bool isChecked;

  const _SquareCheckbox({required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1.25.rem,
      height: 1.25.rem,
      decoration: BoxDecoration(
        color: isChecked ? AppColors.primaryAction : Colors.transparent,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          color: isChecked ? AppColors.primaryAction : AppColors.border,
          width: 1.2,
        ),
      ),
      child: isChecked
          ? const Icon(
              Icons.check_rounded,
              size: 14,
              color: AppColors.onPrimary,
            )
          : null,
    );
  }
}

class _VersusPlaceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _VersusPlaceCard({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.0),
        child: Container(
          height: double.infinity,
          padding: EdgeInsets.all(1.0.rem),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 1.0625.rem,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                  height: 1.25,
                ),
              ),
              SizedBox(height: 0.375.rem),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 0.75.rem,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

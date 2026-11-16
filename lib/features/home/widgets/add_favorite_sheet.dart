import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';

enum _AddFavoriteStep { main, listPicker, tagsPicker, notesEditor }

/// Resultado devuelto al guardar o quitar un lugar de favoritos (`03 Home/04 agregar favoritos/01.png`).
class AddFavoriteResult {
  final String listName;
  final List<String> tags;
  final String notes;
  final bool removed;

  const AddFavoriteResult({
    required this.listName,
    required this.tags,
    required this.notes,
    this.removed = false,
  });
}

/// Bottom sheet para guardar, visualizar o editar un lugar en favoritos/listas (`03 Home/04 agregar favoritos/01.png`).
class AddFavoriteSheet extends StatefulWidget {
  final String placeName;
  final String placeCategory;
  final String fullLocation;
  final List<String> initialTags;
  final bool isEditing;
  final String? initialList;
  final List<String> initialSelectedTags;
  final String? initialNotes;

  const AddFavoriteSheet({
    super.key,
    required this.placeName,
    required this.placeCategory,
    required this.fullLocation,
    this.initialTags = const [],
    this.isEditing = false,
    this.initialList,
    this.initialSelectedTags = const [],
    this.initialNotes,
  });

  static Future<AddFavoriteResult?> show(
    BuildContext context, {
    required String placeName,
    required String placeCategory,
    required String fullLocation,
    List<String> initialTags = const [],
    bool isEditing = false,
    String? initialList,
    List<String> initialSelectedTags = const [],
    String? initialNotes,
  }) {
    return showModalBottomSheet<AddFavoriteResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => AddFavoriteSheet(
        placeName: placeName,
        placeCategory: placeCategory,
        fullLocation: fullLocation,
        initialTags: initialTags,
        isEditing: isEditing,
        initialList: initialList,
        initialSelectedTags: initialSelectedTags,
        initialNotes: initialNotes,
      ),
    );
  }

  @override
  State<AddFavoriteSheet> createState() => _AddFavoriteSheetState();
}

class _AddFavoriteSheetState extends State<AddFavoriteSheet> {
  static const List<String> _listOptions = [
    'Favorites',
    'Want to try',
    'Gym',
    'Studio',
    'Pilates studio',
    'Yoga studio',
    'Other',
  ];

  static const List<String> _defaultTags = [
    'Fun',
    'Great service',
    'TOP classes',
    'Entertaining',
    'Great place',
    'Atmosphere',
    'Professional',
  ];

  _AddFavoriteStep _step = _AddFavoriteStep.main;
  String _selectedList = 'Favorites';
  late final Set<String> _selectedTags;
  late final List<String> _orderedTags;
  String _notes = '';
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedList = (widget.initialList != null && widget.initialList!.isNotEmpty)
        ? widget.initialList!
        : 'Favorites';
    _orderedTags = <String>{
      ...widget.initialSelectedTags,
      ...widget.initialTags,
      ..._defaultTags,
    }.toList();
    if (widget.isEditing && widget.initialSelectedTags.isNotEmpty) {
      _selectedTags = Set<String>.from(widget.initialSelectedTags);
    } else {
      _selectedTags = {
        _orderedTags.isNotEmpty ? _orderedTags.first : 'Fun',
      };
    }
    _notes = widget.initialNotes ?? '';
    _notesController = TextEditingController(text: _notes);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveFavorite() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(
      AddFavoriteResult(
        listName: _selectedList,
        tags: _selectedTags.toList(),
        notes: _notes.trim(),
      ),
    );
  }

  void _removeFavorite() {
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(
      AddFavoriteResult(
        listName: _selectedList,
        tags: _selectedTags.toList(),
        notes: _notes.trim(),
        removed: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.85;
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
                  _AddFavoriteStep.main => _buildMainStep(),
                  _AddFavoriteStep.listPicker => _buildListPickerStep(),
                  _AddFavoriteStep.tagsPicker => _buildTagsPickerStep(),
                  _AddFavoriteStep.notesEditor => _buildNotesStep(),
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
      padding: EdgeInsets.fromLTRB(1.5.rem, 1.0.rem, 1.5.rem, 1.5.rem),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: Lugar + categoría a la izquierda, ubicación a la derecha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                      widget.placeCategory,
                      style: GoogleFonts.poppins(
                        fontSize: 0.75.rem, // 12 px
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 0.75.rem),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 15,
                        color: AppColors.textSecondary,
                      ),
                      SizedBox(width: 0.25.rem),
                      Flexible(
                        child: Text(
                          widget.fullLocation,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 0.75.rem,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 0.875.rem),
          const Divider(color: AppColors.border, height: 1),
          SizedBox(height: 0.375.rem),

          // Fila: "Which list would you add it to?" ->
          InkWell(
            onTap: () => setState(() => _step = _AddFavoriteStep.listPicker),
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0.625.rem),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Which list would you add it to?',
                          style: GoogleFonts.poppins(
                            fontSize: 0.875.rem,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        SizedBox(height: 0.125.rem),
                        Text(
                          _selectedList,
                          style: GoogleFonts.poppins(
                            fontSize: 0.75.rem,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
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
          ),

          SizedBox(height: 0.5.rem),

          // Fila de Tags: ícono etiqueta + chips horizontales + flecha ->
          Row(
            children: [
              const Icon(
                Icons.local_offer_outlined,
                size: 18,
                color: AppColors.textPrimary,
              ),
              SizedBox(width: 0.625.rem),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _orderedTags.map((tag) {
                      final isSelected = _selectedTags.contains(tag);
                      return Padding(
                        padding: EdgeInsets.only(right: 0.4375.rem),
                        child: ChoiceChip(
                          label: Text(tag),
                          selected: isSelected,
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() {
                              if (isSelected) {
                                _selectedTags.remove(tag);
                              } else {
                                _selectedTags.add(tag);
                              }
                            });
                          },
                          labelStyle: GoogleFonts.poppins(
                            fontSize: 0.75.rem,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.onPrimary
                                : AppColors.textSecondary,
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
              ),
              IconButton(
                tooltip: 'More tags',
                onPressed: () =>
                    setState(() => _step = _AddFavoriteStep.tagsPicker),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),

          SizedBox(height: 0.5.rem),

          // Fila "Add notes"
          InkWell(
            onTap: () {
              _notesController.text = _notes;
              setState(() => _step = _AddFavoriteStep.notesEditor);
            },
            borderRadius: BorderRadius.circular(8.0),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 0.625.rem),
              child: Row(
                children: [
                  const Icon(
                    Icons.note_add_outlined,
                    size: 18,
                    color: AppColors.textPrimary,
                  ),
                  SizedBox(width: 0.625.rem),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add notes',
                          style: GoogleFonts.poppins(
                            fontSize: 0.875.rem,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (_notes.trim().isNotEmpty) ...[
                          SizedBox(height: 0.125.rem),
                          Text(
                            _notes.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 0.75.rem,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 1.0.rem),

          AppButton(
            text: widget.isEditing ? 'Update favorite' : 'Save',
            onPressed: _saveFavorite,
          ),
          if (widget.isEditing) ...[
            SizedBox(height: 0.625.rem),
            Center(
              child: TextButton(
                onPressed: _removeFavorite,
                child: Text(
                  'Remove from favorites',
                  style: GoogleFonts.poppins(
                    fontSize: 0.875.rem,
                    fontWeight: FontWeight.w600,
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubHeader({
    required String title,
    required VoidCallback onBack,
    required VoidCallback onDone,
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
            onPressed: onDone,
            child: Text(
              'Done',
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

  Widget _buildListPickerStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Choose a list',
          onBack: () => setState(() => _step = _AddFavoriteStep.main),
          onDone: () => setState(() => _step = _AddFavoriteStep.main),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
            child: Column(
              children: _listOptions.map((listName) {
                final isSelected = _selectedList == listName;
                return Column(
                  children: [
                    InkWell(
                      onTap: () {
                        setState(() {
                          _selectedList = listName;
                          _step = _AddFavoriteStep.main;
                        });
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 0.875.rem),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                listName,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.875.rem,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_rounded,
                                size: 20,
                                color: AppColors.primaryAction,
                              ),
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

  Widget _buildTagsPickerStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Select tags',
          onBack: () => setState(() => _step = _AddFavoriteStep.main),
          onDone: () => setState(() => _step = _AddFavoriteStep.main),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(1.5.rem, 0.25.rem, 1.5.rem, 1.5.rem),
            child: Column(
              children: _orderedTags.map((tag) {
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
                        padding: EdgeInsets.symmetric(vertical: 0.875.rem),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tag,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.875.rem,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              width: 1.25.rem,
                              height: 1.25.rem,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryAction
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(5.0),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryAction
                                      : AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: AppColors.onPrimary,
                                    )
                                  : null,
                            ),
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

  Widget _buildNotesStep() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSubHeader(
          title: 'Add notes',
          onBack: () => setState(() => _step = _AddFavoriteStep.main),
          onDone: () {
            setState(() {
              _notes = _notesController.text.trim();
              _step = _AddFavoriteStep.main;
            });
          },
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(1.5.rem, 0.5.rem, 1.5.rem, 1.5.rem),
          child: Container(
            height: 10.0.rem,
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
                hintText: 'Add notes about this place...',
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
}

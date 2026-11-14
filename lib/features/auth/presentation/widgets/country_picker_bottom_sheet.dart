import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/country_codes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/app_rem.dart';

/// Modal Bottom Sheet para la selección de prefijos telefónicos internacionales.
///
/// Diseñado con las mejores prácticas para iOS/iPhones:
/// - Banderas con emojis Unicode nativos (Apple Color Emoji).
/// - Físicas inerciales con rebote (`BouncingScrollPhysics`).
/// - Retroalimentación háptica táctil (`HapticFeedback.selectionClick()`).
/// - Buscador en tiempo real por nombre de país o código numérico.
class CountryPickerBottomSheet extends StatefulWidget {
  final CountryCode selectedCountry;

  const CountryPickerBottomSheet({
    super.key,
    required this.selectedCountry,
  });

  /// Método estático de conveniencia para mostrar el modal
  static Future<CountryCode?> show(
    BuildContext context, {
    required CountryCode selectedCountry,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<CountryCode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CountryPickerBottomSheet(
        selectedCountry: selectedCountry,
      ),
    );
  }

  @override
  State<CountryPickerBottomSheet> createState() =>
      _CountryPickerBottomSheetState();
}

class _CountryPickerBottomSheetState extends State<CountryPickerBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<CountryCode> _filteredCountries = CountryCodes.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCountries = CountryCodes.all;
      } else {
        _filteredCountries = CountryCodes.all.where((country) {
          final matchesName = country.name.toLowerCase().contains(query);
          final matchesCode = country.code.toLowerCase().contains(query);
          final matchesDial = country.dialCode.contains(query);
          return matchesName || matchesCode || matchesDial;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final maxHeight = mediaQuery.size.height * 0.75;

    return Material(
      color: AppColors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            SizedBox(height: 0.75.rem), // 12 px

            // Barra de arrastre superior
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            SizedBox(height: 1.0.rem), // 16 px

            // Título centrado
            Text(
              'Select country',
              style: GoogleFonts.poppins(
                fontSize: 1.125.rem, // 18 px
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),

            SizedBox(height: 1.0.rem), // 16 px

            // Buscador en tiempo real
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.25.rem),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF9F9FB),
                  borderRadius: BorderRadius.circular(14.0),
                  border: Border.all(color: const Color(0xFFE5E5EA)),
                ),
                child: TextField(
                  controller: _searchController,
                  style: GoogleFonts.poppins(
                    fontSize: 0.9375.rem,
                    color: AppColors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search country or code...',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 0.875.rem,
                      color: AppColors.textMuted,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.iconSecondary,
                      size: 20,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            color: AppColors.textMuted,
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),

            SizedBox(height: 0.75.rem),

            // Lista deslizable con físicas iOS
            Flexible(
              child: _filteredCountries.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: 2.0.rem),
                      child: Text(
                        'No countries found',
                        style: GoogleFonts.poppins(
                          fontSize: 0.875.rem,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: _filteredCountries.length,
                      separatorBuilder: (_, _) => const Divider(
                        color: Color(0xFFF2F2F7),
                        height: 1,
                        indent: 64,
                      ),
                      itemBuilder: (context, index) {
                        final country = _filteredCountries[index];
                        final isSelected =
                            country.code == widget.selectedCountry.code &&
                                country.dialCode ==
                                    widget.selectedCountry.dialCode;

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 1.5.rem,
                            vertical: 2,
                          ),
                          leading: Text(
                            country.flag,
                            style: const TextStyle(fontSize: 26),
                          ),
                          title: Text(
                            country.name,
                            style: GoogleFonts.poppins(
                              fontSize: 0.9375.rem,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                country.dialCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 0.875.rem,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? AppColors.primaryAction
                                      : AppColors.textSecondary,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.check_circle_rounded,
                                  size: 18,
                                  color: AppColors.primaryAction,
                                ),
                              ],
                            ],
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop(country);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}
}

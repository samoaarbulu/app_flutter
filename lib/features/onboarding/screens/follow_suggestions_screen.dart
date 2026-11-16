import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import '../../../shared/widgets/user_avatar.dart';
import '../../home/screens/home_screen.dart';

class _SuggestedPerson {
  final String id;
  final String name;
  final String initials;
  final String handle;
  final int gymsCount;

  const _SuggestedPerson({
    required this.id,
    required this.name,
    required this.initials,
    required this.handle,
    required this.gymsCount,
  });
}

/// Paso 10 del onboarding: sugerencias sociales (`02 Crear cuenta/10.png`).
class FollowSuggestionsScreen extends StatefulWidget {
  final VoidCallback? onFinish;

  const FollowSuggestionsScreen({
    super.key,
    this.onFinish,
  });

  @override
  State<FollowSuggestionsScreen> createState() =>
      _FollowSuggestionsScreenState();
}

class _FollowSuggestionsScreenState extends State<FollowSuggestionsScreen> {
  static const List<_SuggestedPerson> _people = [
    _SuggestedPerson(
      id: 'p1',
      name: 'Luis Méndez',
      initials: 'LM',
      handle: '@luis.mueve',
      gymsCount: 12,
    ),
    _SuggestedPerson(
      id: 'p2',
      name: 'Sofía Ruiz',
      initials: 'SR',
      handle: '@sofi.fuerza',
      gymsCount: 8,
    ),
    _SuggestedPerson(
      id: 'p3',
      name: 'Diego Pérez',
      initials: 'DP',
      handle: '@diego.activo',
      gymsCount: 15,
    ),
  ];

  int _selectedTab = 0; // 0 = Suggestions, 1 = Invite contacts
  final Set<String> _followingIds = {'p1', 'p2'};

  String get _primaryButtonText {
    final count = _followingIds.length;
    if (count == 0) return 'Go to Home';
    return 'Follow $count and go to Home';
  }

  void _goToHome() {
    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  void _toggleFollow(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_followingIds.contains(id)) {
        _followingIds.remove(id);
      } else {
        _followingIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.textPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 0.75.rem),

              const AppHeader(
                title: 'Training is better together',
                description:
                    'Follow others to discover their favorite places. This step is optional.',
              ),

              SizedBox(height: 1.25.rem),

              // Tabs: Suggestions | Invite contacts
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.inputSurface,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _SegmentTab(
                        label: 'Suggestions',
                        isSelected: _selectedTab == 0,
                        onTap: () => setState(() => _selectedTab = 0),
                      ),
                    ),
                    Expanded(
                      child: _SegmentTab(
                        label: 'Invite contacts',
                        isSelected: _selectedTab == 1,
                        onTap: () => setState(() => _selectedTab = 1),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 1.25.rem),

              Text(
                _selectedTab == 0
                    ? 'PEOPLE WITH SIMILAR ACTIVITIES'
                    : 'INVITE YOUR CONTACTS',
                style: GoogleFonts.poppins(
                  fontSize: 0.75.rem,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                  color: AppColors.textSecondary,
                ),
              ),

              SizedBox(height: 0.5.rem),

              Expanded(
                child: _selectedTab == 0
                    ? ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        itemCount: _people.length,
                        separatorBuilder: (_, _) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (_, index) {
                          final person = _people[index];
                          final isFollowing =
                              _followingIds.contains(person.id);
                          return Padding(
                            padding: EdgeInsets.symmetric(vertical: 0.875.rem),
                            child: Row(
                              children: [
                                UserAvatar(
                                  size: 2.75.rem,
                                  initials: person.initials,
                                ),
                                SizedBox(width: 0.875.rem),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        person.name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 0.9375.rem,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${person.handle} · ${person.gymsCount} gyms',
                                        style: GoogleFonts.poppins(
                                          fontSize: 0.75.rem,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 0.5.rem),
                                GestureDetector(
                                  onTap: () => _toggleFollow(person.id),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 1.0.rem,
                                      vertical: 0.4375.rem,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isFollowing
                                          ? AppColors.primaryAction
                                          : AppColors.surface,
                                      borderRadius: BorderRadius.circular(10.0),
                                      border: Border.all(
                                        color: isFollowing
                                            ? AppColors.primaryAction
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      isFollowing ? 'Following' : 'Follow',
                                      style: GoogleFonts.poppins(
                                        fontSize: 0.8125.rem,
                                        fontWeight: FontWeight.w600,
                                        color: isFollowing
                                            ? AppColors.onPrimary
                                            : AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_add_alt_1_outlined,
                              size: 36,
                              color: AppColors.textSecondary,
                            ),
                            SizedBox(height: 0.75.rem),
                            Text(
                              'Invite friends from your contacts to train together on Creds.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 0.875.rem,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(height: 1.0.rem),
                            OutlinedButton(
                              onPressed: () => AppFeedback.show(
                                context,
                                'Contacts invite coming soon',
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.textPrimary,
                                side: const BorderSide(color: AppColors.border),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Sync contacts'),
                            ),
                          ],
                        ),
                      ),
              ),

              SizedBox(height: 0.75.rem),

              AppButton(
                text: _primaryButtonText,
                variant: AppButtonVariant.primary,
                onPressed: _goToHome,
              ),

              SizedBox(height: 0.5.rem),

              AppLinkButton(
                text: 'Not now, go to Home',
                onPressed: _goToHome,
              ),

              SizedBox(height: 1.0.rem),
            ],
          ),
        ),
      ),
    );
  }
}

class _SegmentTab extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentTab({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 0.5625.rem),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(9.0),
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 0.8125.rem,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color:
                  isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/contacts_service.dart';
import '../../../core/services/creds_api_service.dart';
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
  final String subtitle;
  final String? avatarUrl;

  const _SuggestedPerson({
    required this.id,
    required this.name,
    required this.initials,
    required this.subtitle,
    this.avatarUrl,
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
  static const List<_SuggestedPerson> _fallbackPeople = [
    _SuggestedPerson(
      id: 'p1',
      name: 'Luis Méndez',
      initials: 'LM',
      subtitle: '@luis.mueve · 12 gyms',
    ),
    _SuggestedPerson(
      id: 'p2',
      name: 'Sofía Ruiz',
      initials: 'SR',
      subtitle: '@sofi.fuerza · 8 gyms',
    ),
    _SuggestedPerson(
      id: 'p3',
      name: 'Diego Pérez',
      initials: 'DP',
      subtitle: '@diego.activo · 15 gyms',
    ),
  ];

  List<_SuggestedPerson> _people = const [];
  List<CredsInvitableContact> _invitableContacts = const [];
  final Set<int> _invitedIndices = {};
  String _shareMessage = '';
  int _selectedTab = 0; // 0 = Suggestions, 1 = Invite contacts
  final Set<String> _followingIds = {};
  bool _isLoadingSuggestions = false;
  bool _isSyncingContacts = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (CredsApiService.instance.hasSession) {
      _loadSuggestions();
    } else {
      _people = _fallbackPeople;
      _followingIds.addAll({'p1', 'p2'});
    }
  }

  Future<void> _loadSuggestions() async {
    setState(() => _isLoadingSuggestions = true);
    try {
      final hasContactsPermission =
          CredsApiService.instance.currentUser?.hasContactsPermission == true;
      final deviceContacts = (hasContactsPermission &&
              ContactsService.instance.isSupportedOnPlatform)
          ? await ContactsService.instance.readDeviceContacts()
          : const <CredsContactMatchInput>[];

      final suggestionsFuture = CredsApiService.instance.getSuggestions();
      final matchFuture = deviceContacts.isNotEmpty
          ? CredsApiService.instance.matchContacts(deviceContacts)
          : Future<CredsMatchContactsResponse?>.value(null);

      final items = await suggestionsFuture;
      final matchResponse = await matchFuture;
      if (!mounted) return;

      final mergedPeople = <_SuggestedPerson>[];
      final seenIds = <String>{};
      final following = <String>{};

      if (matchResponse != null) {
        for (final contactUser in matchResponse.onCreds) {
          if (seenIds.add(contactUser.id)) {
            mergedPeople.add(
              _SuggestedPerson(
                id: contactUser.id,
                name: contactUser.displayName,
                initials: contactUser.initials,
                subtitle: contactUser.placesLabel.isNotEmpty
                    ? '${contactUser.placesLabel} · In contacts'
                    : 'In your contacts',
                avatarUrl: contactUser.avatarUrl,
              ),
            );
            if (contactUser.isFollowing) following.add(contactUser.id);
          }
        }
      }

      for (final item in items) {
        if (seenIds.add(item.id)) {
          mergedPeople.add(
            _SuggestedPerson(
              id: item.id,
              name: item.displayName,
              initials: item.initials,
              subtitle: item.placesLabel,
              avatarUrl: item.avatarUrl,
            ),
          );
          if (item.isFollowing) following.add(item.id);
        }
      }

      setState(() {
        _people = mergedPeople;
        if (matchResponse != null) {
          _invitableContacts = matchResponse.toInvite;
          _shareMessage = matchResponse.shareMessage;
        }
        _followingIds
          ..clear()
          ..addAll(following);
        _isLoadingSuggestions = false;
      });
    } on CredsApiException catch (e) {
      if (!mounted) return;
      if (e.isNetworkOrOfflineError) {
        setState(() {
          _people = _fallbackPeople;
          _isLoadingSuggestions = false;
        });
      } else {
        setState(() => _isLoadingSuggestions = false);
        AppFeedback.showError(context, e.message);
      }
    }
  }

  Future<void> _syncContacts() async {
    if (_isSyncingContacts) return;

    if (!CredsApiService.instance.hasSession) {
      AppFeedback.show(context, 'Contacts sync requires an active session.');
      return;
    }

    if (!ContactsService.instance.isSupportedOnPlatform) {
      setState(() => _isSyncingContacts = true);
      try {
        if (_shareMessage.isEmpty) {
          final link = await CredsApiService.instance.getInviteLink();
          _shareMessage = link.shareMessage;
        }
        await Clipboard.setData(ClipboardData(text: _shareMessage));
        if (!mounted) return;
        AppFeedback.showSuccess(
          context,
          'Invite link copied! Share it with your friends.',
        );
      } on CredsApiException catch (e) {
        if (mounted) AppFeedback.showError(context, e.message);
      } finally {
        if (mounted) setState(() => _isSyncingContacts = false);
      }
      return;
    }

    setState(() => _isSyncingContacts = true);
    try {
      final deviceContacts =
          await ContactsService.instance.readDeviceContacts();
      if (!mounted) return;

      if (deviceContacts.isEmpty) {
        setState(() => _isSyncingContacts = false);
        AppFeedback.show(
          context,
          'No contacts found or permission not granted.',
        );
        return;
      }

      final matchResponse =
          await CredsApiService.instance.matchContacts(deviceContacts);
      if (!mounted) return;

      final updatedPeople = <_SuggestedPerson>[];
      final seenIds = <String>{};
      for (final contactUser in matchResponse.onCreds) {
        if (seenIds.add(contactUser.id)) {
          updatedPeople.add(
            _SuggestedPerson(
              id: contactUser.id,
              name: contactUser.displayName,
              initials: contactUser.initials,
              subtitle: contactUser.placesLabel.isNotEmpty
                  ? '${contactUser.placesLabel} · In contacts'
                  : 'In your contacts',
              avatarUrl: contactUser.avatarUrl,
            ),
          );
        }
      }
      for (final existing in _people) {
        if (seenIds.add(existing.id)) {
          updatedPeople.add(existing);
        }
      }

      setState(() {
        _people = updatedPeople;
        _invitableContacts = matchResponse.toInvite;
        _shareMessage = matchResponse.shareMessage;
        _invitedIndices.clear();
        _isSyncingContacts = false;
      });
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _isSyncingContacts = false);
      AppFeedback.showError(context, e.message);
    }
  }

  Future<void> _inviteContact(int index, CredsInvitableContact contact) async {
    if (_invitedIndices.contains(index) || contact.alreadyInvited) return;
    HapticFeedback.selectionClick();

    setState(() => _invitedIndices.add(index));
    try {
      await CredsApiService.instance.createUserInvite(
        contactName: contact.name,
        contactPhone: contact.phoneNumber,
        contactEmail: contact.email,
      );
      if (_shareMessage.isNotEmpty) {
        await Clipboard.setData(ClipboardData(text: _shareMessage));
      }
      if (!mounted) return;
      AppFeedback.showSuccess(
        context,
        'Invite link copied for ${contact.name}.',
      );
    } on CredsApiException catch (e) {
      if (!mounted) return;
      setState(() => _invitedIndices.remove(index));
      AppFeedback.showError(context, e.message);
    }
  }

  String _initialsForName(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'CR';
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String get _primaryButtonText {
    final count = _followingIds.length;
    if (count == 0) return 'Follow and go to Home';
    return 'Follow $count and go to Home';
  }

  Future<void> _finishAndGoHome({required bool skipped}) async {
    if (_isSubmitting) return;

    if (widget.onFinish != null) {
      widget.onFinish!();
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isSubmitting = true);
      try {
        await CredsApiService.instance.completeOnboardingFollows(
          skipped ? const [] : _followingIds.toList(),
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
                    ? _isLoadingSuggestions
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryAction,
                            ),
                          )
                        : _people.isEmpty
                            ? Center(
                                child: Text(
                                  'No suggestions available right now.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 0.875.rem,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _people.length,
                                separatorBuilder: (_, _) => const Divider(
                                    color: AppColors.border, height: 1),
                                itemBuilder: (_, index) {
                                  final person = _people[index];
                                  final isFollowing =
                                      _followingIds.contains(person.id);
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 0.875.rem),
                                    child: Row(
                                      children: [
                                        UserAvatar(
                                          size: 2.75.rem,
                                          initials: person.initials,
                                          photoUrl: person.avatarUrl,
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
                                                person.subtitle,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 0.75.rem,
                                                  color:
                                                      AppColors.textSecondary,
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
                    : _isSyncingContacts
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primaryAction,
                            ),
                          )
                        : _invitableContacts.isNotEmpty
                            ? ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: _invitableContacts.length,
                                separatorBuilder: (_, _) => const Divider(
                                    color: AppColors.border, height: 1),
                                itemBuilder: (_, index) {
                                  final contact = _invitableContacts[index];
                                  final isInvited = contact.alreadyInvited ||
                                      _invitedIndices.contains(index);
                                  final detail = contact.phoneNumber ??
                                      contact.email ??
                                      'Not on Creds yet';
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 0.875.rem),
                                    child: Row(
                                      children: [
                                        UserAvatar(
                                          size: 2.75.rem,
                                          initials:
                                              _initialsForName(contact.name),
                                        ),
                                        SizedBox(width: 0.875.rem),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                contact.name,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 0.9375.rem,
                                                  fontWeight: FontWeight.w700,
                                                  color: AppColors.textPrimary,
                                                ),
                                              ),
                                              Text(
                                                detail,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 0.75.rem,
                                                  color:
                                                      AppColors.textSecondary,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        SizedBox(width: 0.5.rem),
                                        GestureDetector(
                                          onTap: isInvited
                                              ? null
                                              : () => _inviteContact(
                                                  index, contact),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 1.0.rem,
                                              vertical: 0.4375.rem,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isInvited
                                                  ? AppColors.inputSurface
                                                  : AppColors.surface,
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                              border: Border.all(
                                                color: AppColors.border,
                                              ),
                                            ),
                                            child: Text(
                                              isInvited ? 'Invited' : 'Invite',
                                              style: GoogleFonts.poppins(
                                                fontSize: 0.8125.rem,
                                                fontWeight: FontWeight.w600,
                                                color: isInvited
                                                    ? AppColors.textSecondary
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
                                      onPressed: _syncContacts,
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppColors.textPrimary,
                                        side: const BorderSide(
                                            color: AppColors.border),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        ContactsService
                                                .instance.isSupportedOnPlatform
                                            ? 'Sync contacts'
                                            : 'Copy invite link',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
              ),

              SizedBox(height: 0.75.rem),

              AppButton(
                text: _primaryButtonText,
                variant: AppButtonVariant.primary,
                isLoading: _isSubmitting,
                onPressed: (_isSubmitting || _followingIds.isEmpty)
                    ? null
                    : () => _finishAndGoHome(skipped: false),
              ),

              SizedBox(height: 0.5.rem),

              Center(
                child: AppLinkButton(
                  text: 'Not now, go to Home',
                  onPressed: _isSubmitting
                      ? null
                      : () => _finishAndGoHome(skipped: true),
                ),
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

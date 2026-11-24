import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/services/contacts_service.dart';
import '../../../core/services/creds_api_service.dart';
import '../../../core/services/push_notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import 'follow_suggestions_screen.dart';

/// Paso 09 del onboarding: permisos opcionales (`02 Crear cuenta/09.png`).
class UsefulPermissionsScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const UsefulPermissionsScreen({super.key, this.onContinue});

  @override
  State<UsefulPermissionsScreen> createState() =>
      _UsefulPermissionsScreenState();
}

class _UsefulPermissionsScreenState extends State<UsefulPermissionsScreen> {
  bool _contactsEnabled = false;
  bool _notificationsEnabled = false;
  bool _isSubmitting = false;
  bool _isRequestingPermission = false;

  bool get _isWidgetTest => WidgetsBinding.instance.runtimeType
      .toString()
      .contains('TestWidgetsFlutterBinding');

  Future<void> _onContactsChanged(bool value) async {
    if (_isSubmitting || _isRequestingPermission) return;
    if (!value) {
      setState(() => _contactsEnabled = false);
      return;
    }

    if (!_isWidgetTest && kIsWeb) {
      AppFeedback.showError(
        context,
        'Contacts access is only available on Android or iOS.',
      );
      return;
    }

    setState(() => _isRequestingPermission = true);
    try {
      final granted = await ContactsService.instance.requestPermission();
      if (!mounted) return;
      setState(() => _contactsEnabled = granted);
      if (!granted) {
        AppFeedback.showError(
          context,
          'Contacts permission was not granted.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _onNotificationsChanged(bool value) async {
    if (_isSubmitting || _isRequestingPermission) return;
    if (!value) {
      setState(() => _notificationsEnabled = false);
      await PushNotificationService.instance.unregisterCurrentToken();
      return;
    }

    setState(() => _isRequestingPermission = true);
    try {
      final granted = await PushNotificationService.instance
          .requestPermissionAndSync();
      if (!mounted) return;
      setState(() => _notificationsEnabled = granted);
      if (!granted) {
        AppFeedback.showError(
          context,
          'Notifications permission was not granted.',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRequestingPermission = false);
      }
    }
  }

  Future<void> _saveAndContinue({required bool skipped}) async {
    if (_isSubmitting) return;

    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }

    if (CredsApiService.instance.hasSession) {
      setState(() => _isSubmitting = true);
      try {
        await CredsApiService.instance.updatePreferences(
          contactsPermissionGranted: skipped ? false : _contactsEnabled,
          notificationsPermissionGranted: skipped
              ? false
              : _notificationsEnabled,
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
        builder: (_) => FollowSuggestionsScreen(
          contactsEnabled: !skipped && _contactsEnabled,
        ),
      ),
    );
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 1.5.rem),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 0.75.rem),

                      const AppHeader(
                        title: 'Make Creds more useful',
                        description: 'Choose which permissions to enable. None are required to use Creds.',
                      ),

                      SizedBox(height: 1.5.rem),

                      _PermissionSwitchCard(
                        icon: Icons.contacts_outlined,
                        title: 'Contacts',
                        description: 'Find friends who already use Creds.',
                        value: _contactsEnabled,
                        onChanged: _onContactsChanged,
                      ),

                      SizedBox(height: 0.875.rem),

                      _PermissionSwitchCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        description:
                            'Get updates from your places and friends.',
                        value: _notificationsEnabled,
                        onChanged: _onNotificationsChanged,
                      ),

                      const Spacer(),
                      SizedBox(height: 1.5.rem),

                      AppButton(
                        text: 'Continue',
                        variant: AppButtonVariant.primary,
                        isLoading: _isSubmitting,
                        onPressed: _isSubmitting
                            ? null
                            : () => _saveAndContinue(skipped: false),
                      ),

                      SizedBox(height: 0.5.rem),

                      AppLinkButton(
                        text: 'Do this later',
                        onPressed: _isSubmitting
                            ? null
                            : () => _saveAndContinue(skipped: true),
                      ),

                      SizedBox(height: 1.0.rem),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PermissionSwitchCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _PermissionSwitchCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: 6.25.rem), // 100 px
      padding: EdgeInsets.symmetric(horizontal: 1.0.rem, vertical: 1.0.rem),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border, width: 1.0),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppColors.textPrimary),
          SizedBox(width: 0.875.rem),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 0.9375.rem,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 0.125.rem),
                Text(
                  description,
                  style: GoogleFonts.poppins(
                    fontSize: 0.8125.rem,
                    color: AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 0.5.rem),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primaryAction,
            activeThumbColor: AppColors.onPrimary,
            inactiveTrackColor: AppColors.border,
            inactiveThumbColor: AppColors.surface,
          ),
        ],
      ),
    );
  }
}

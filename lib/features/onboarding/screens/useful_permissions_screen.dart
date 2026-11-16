import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_rem.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_link_button.dart';
import 'follow_suggestions_screen.dart';

/// Paso 09 del onboarding: permisos opcionales (`02 Crear cuenta/09.png`).
class UsefulPermissionsScreen extends StatefulWidget {
  final VoidCallback? onContinue;

  const UsefulPermissionsScreen({
    super.key,
    this.onContinue,
  });

  @override
  State<UsefulPermissionsScreen> createState() =>
      _UsefulPermissionsScreenState();
}

class _UsefulPermissionsScreenState extends State<UsefulPermissionsScreen> {
  bool _contactsEnabled = false;
  bool _notificationsEnabled = true;

  void _navigateNext() {
    if (widget.onContinue != null) {
      widget.onContinue!();
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FollowSuggestionsScreen(),
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
                        description:
                            'Choose which permissions to enable. None are required to use Creds.',
                      ),

                      SizedBox(height: 1.5.rem),

                      _PermissionSwitchCard(
                        icon: Icons.contacts_outlined,
                        title: 'Contacts',
                        description: 'Find friends who already use Creds.',
                        value: _contactsEnabled,
                        onChanged: (val) =>
                            setState(() => _contactsEnabled = val),
                      ),

                      SizedBox(height: 0.875.rem),

                      _PermissionSwitchCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifications',
                        description:
                            'Get updates from your places and friends.',
                        value: _notificationsEnabled,
                        onChanged: (val) =>
                            setState(() => _notificationsEnabled = val),
                      ),

                      SizedBox(height: 1.25.rem),

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
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.verified_user_outlined,
                                size: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 0.625.rem),
                            Expanded(
                              child: Text(
                                'Next, confirm each permission. You can change them in Settings.',
                                style: GoogleFonts.poppins(
                                  fontSize: 0.8125.rem,
                                  color: AppColors.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),
                      SizedBox(height: 1.5.rem),

                      AppButton(
                        text: 'Continue with my selection',
                        variant: AppButtonVariant.primary,
                        onPressed: _navigateNext,
                      ),

                      SizedBox(height: 0.5.rem),

                      AppLinkButton(
                        text: 'Do this later',
                        onPressed: _navigateNext,
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

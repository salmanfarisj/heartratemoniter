import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/widgets/pulsex_logo.dart';
import '../../../../core/widgets/segmented_selector.dart';
import '../../../../core/widgets/wahoo_header.dart';
import '../../../home/presentation/bloc/heart_rate_bloc.dart';
import '../../../home/presentation/bloc/heart_rate_state.dart';
import '../../../home/presentation/widgets/device_bottom_sheet.dart';
import '../bloc/settings_bloc.dart';
import '../bloc/settings_event.dart';
import '../bloc/settings_state.dart';

/// Wahoo-style Settings screen — mirrors the HEADWIND device-detail
/// screen from the reference: ALL-CAPS header, a Connected device
/// hero block, and then rows of grouped settings with hairline dividers.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, settingsState) {
        return Scaffold(
          backgroundColor: AppColors.paperWhite,
          appBar: const WahooHeader(
            title: 'Settings',
            showBack: true,
          ),
          body: SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              children: [
                // Device card (mirrors the "HEADWIND 2344" hero on the
                // reference screenshot — Connection status + Name row).
                BlocBuilder<HeartRateBloc, HeartRateState>(
                  builder: (context, hrState) {
                    return _DeviceHeroCard(
deviceName: hrState.connectedDevice?.name ??
                          'PulseX HR Sensor',
                  isConnected: hrState.isConnected,
                  onTap: () => _showDeviceSheet(context),
                );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('Display Mode'),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: SegmentedSelector<_DisplayMode>(
                    selected: _DisplayMode.heartrate,
                    onChanged: (_) {},
                    options: const [
                      SegmentedOption(_DisplayMode.heartrate, 'Heartrate'),
                      SegmentedOption(_DisplayMode.speed, 'Speed'),
                      SegmentedOption(_DisplayMode.control, 'Control'),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('PulseX HR Sensor'),
                const SizedBox(height: AppSpacing.md),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.cake_outlined,
                      label: 'Age',
                      value: '${settingsState.userAge} years',
                      subtitle:
                          'Max HR: ${settingsState.maxHeartRate} BPM',
                      onTap: () =>
                          _showAgeDialog(context, settingsState.userAge),
                    ),
                    _SettingsDivider(),
                    _SettingsRow(
                      icon: Icons.speed,
                      label: 'Max Heart Rate',
                      value: '${settingsState.maxHeartRate} BPM',
                      onTap: () => _showMaxHrDialog(
                        context,
                        settingsState.maxHeartRate,
                      ),
                    ),
                    _SettingsDivider(),
                    _SettingsRow(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      value: settingsState.notificationsEnabled
                          ? 'Enabled'
                          : 'Disabled',
                      trailing: Switch(
                        value: settingsState.notificationsEnabled,
                        onChanged: (value) {
                          context.read<SettingsBloc>().add(
                                UpdateNotifications(value),
                              );
                        },
                      ),
                      onTap: () {
                        context.read<SettingsBloc>().add(
                              UpdateNotifications(
                                !settingsState.notificationsEnabled,
                              ),
                            );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('Data'),
                const SizedBox(height: AppSpacing.md),
                _SettingsGroup(
                  children: [
                    _SettingsRow(
                      icon: Icons.file_download_outlined,
                      label: 'Export Data',
                      value: 'Download as CSV',
                      onTap: () => _showExportDialog(context),
                    ),
                    _SettingsDivider(),
                    _SettingsRow(
                      icon: Icons.delete_outline,
                      label: 'Clear History',
                      value: 'Delete all logged data',
                      destructive: true,
                      onTap: () => _showClearDataDialog(context),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                _SectionLabel('About'),
                const SizedBox(height: AppSpacing.md),
                _SettingsGroup(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.md,
                      ),
                      child: PulseXAboutTile(),
                    ),
                    _SettingsDivider(),
                    _SettingsRow(
                      icon: Icons.info_outline,
                      label: 'Version',
                      value: '1.0.0',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeviceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paperWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const DeviceBottomSheet(),
    );
  }

  void _showAgeDialog(BuildContext context, int currentAge) {
    final controller = TextEditingController(text: currentAge.toString());
    final settingsBloc = context.read<SettingsBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Your Age'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Age',
            suffixText: 'years',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final age = int.tryParse(controller.text);
              if (age != null && age > 0 && age < 120) {
                settingsBloc.add(UpdateUserAge(age));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaxHrDialog(BuildContext context, int currentMaxHr) {
    final controller = TextEditingController(text: currentMaxHr.toString());
    final settingsBloc = context.read<SettingsBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter Max Heart Rate'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Max HR',
            suffixText: 'BPM',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final maxHr = int.tryParse(controller.text);
              if (maxHr != null && maxHr > 100 && maxHr < 250) {
                settingsBloc.add(UpdateMaxHeartRate(maxHr));
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(BuildContext context) {
    final settingsBloc = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Export Data'),
        content: const Text('Choose what to export:'),
        actions: [
          TextButton(
            onPressed: () {
              settingsBloc.add(const ExportData('hr'));
              Navigator.pop(ctx);
              messenger.showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
            child: const Text('Heart Rate'),
          ),
          TextButton(
            onPressed: () {
              settingsBloc.add(const ExportData('activities'));
              Navigator.pop(ctx);
              messenger.showSnackBar(
                const SnackBar(content: Text('Export coming soon')),
              );
            },
            child: const Text('Activities'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context) {
    final settingsBloc = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all heart rate readings and activities. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settingsBloc.add(ClearAllData());
              Navigator.pop(ctx);
              messenger.showSnackBar(
                const SnackBar(content: Text('Data cleared')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.zonePeak),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

// ─── Display mode (segmented selector backing model) ──────────────────
enum _DisplayMode {
  heartrate,
  speed,
  control,
}

// ─── Section label (small caps tracking, matches history) ──────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(label.toUpperCase(), style: AppTypography.sectionHeader);
  }
}

// ─── Device hero card (Wahoo "Wahoo HEADWIND 2344 — Connected") ────────
class _DeviceHeroCard extends StatelessWidget {
  final String deviceName;
  final bool isConnected;
  final VoidCallback onTap;

  const _DeviceHeroCard({
    required this.deviceName,
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cards),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.paperWhite,
            border: Border.all(color: AppColors.hairline),
            borderRadius: BorderRadius.circular(AppRadius.cards),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bluetooth,
                    color: isConnected
                        ? AppColors.brandBlue
                        : AppColors.silverLabel,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: AppTypography.caption.copyWith(
                      color: isConnected
                          ? AppColors.brandBlue
                          : AppColors.silverLabel,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isConnected
                          ? AppColors.successGreen
                          : AppColors.silverLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(deviceName, style: AppTypography.titleLarge),
              const SizedBox(height: 2),
              Text(
                'Tap to manage device',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Settings group container (single white card, hairline borders) ────
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const _SettingsGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paperWhite,
        border: Border.all(color: AppColors.hairline),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColors.hairline,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
    );
  }
}

// ─── Settings row (icon | label + subtitle/value | trailing) ───────────
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String? value;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool destructive;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.trailing,
    this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor =
        destructive ? AppColors.zonePeak : AppColors.inkBlack;
    final iconColor =
        destructive ? AppColors.zonePeak : AppColors.brandBlue;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: AppTypography.caption),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value!,
                style: AppTypography.caption.copyWith(
                  color: AppColors.pewter,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ] else if (onTap != null) ...[
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.chevron_right,
                color: AppColors.pewter,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
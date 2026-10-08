import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../data/services/bluetooth_permission_result.dart';
import '../bloc/heart_rate_bloc.dart';
import '../bloc/heart_rate_event.dart';
import '../bloc/heart_rate_state.dart';

/// Single source of truth for the BLE device picker sheet.
///
/// Re-styled to match the Wahoo device-detail aesthetic — flat white
/// surface, Wahoo-blue accents, blue tint banner for permission recovery.
class DeviceBottomSheet extends StatelessWidget {
  const DeviceBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HeartRateBloc, HeartRateState>(
      builder: (context, state) {
        final hrBloc = context.read<HeartRateBloc>();
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.paperWhite,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle.
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.bone,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.brandBlueTint,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.bluetooth,
                            color: AppColors.brandBlue,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Connect Device',
                                style: AppTypography.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                state.isScanning
                                    ? 'Searching for nearby PulseX sensors…'
                                    : 'Find and pair your PulseX HR sensor',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        if (state.isScanning)
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.brandBlue,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    if (state.permissionResult ==
                            BluetoothPermissionResult.permanentlyDenied ||
                        state.permissionResult ==
                            BluetoothPermissionResult.denied) ...[
                      _PermissionBanner(
                        result: state.permissionResult!,
                        onOpenSettings: () async {
                          await openAppSettings();
                          if (context.mounted) {
                            Navigator.of(context).maybePop();
                          }
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    if (state.isConnected && state.connectedDevice != null) ...[
                      _ConnectedDeviceCard(
                        deviceName: state.connectedDevice!.name,
                        onDisconnect: () {
                          hrBloc.add(DisconnectDevice());
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ] else ...[
                      if (state.discoveredDevices.isEmpty && !state.isScanning)
                        const _EmptyStateWidget()
                      else
                        ...state.discoveredDevices.map(
                          (device) => Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.sm,
                            ),
                            child: _DeviceCard(
                              deviceName: device.name,
                              deviceAddress: device.address,
                              onTap: () {
                                hrBloc.add(ConnectToDevice(device));
                                Navigator.of(context).maybePop();
                              },
                            ),
                          ),
                        ),

                      const SizedBox(height: AppSpacing.md),

                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: state.isScanning
                              ? () => hrBloc.add(StopScan())
                              : () => hrBloc.add(StartScan()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: state.isScanning
                                ? AppColors.pewter
                                : AppColors.brandBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                state.isScanning
                                    ? Icons.stop_rounded
                                    : Icons.radar_rounded,
                                size: 18,
                                color: AppColors.paperWhite,
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                state.isScanning
                                    ? 'Stop Scanning'
                                    : 'Scan for Devices',
                                style: AppTypography.button.copyWith(
                                  color: AppColors.paperWhite,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    if (state.errorMessage != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.zonePeak.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.zonePeak,
                              size: 18,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.zonePeak,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }
}

class _PermissionBanner extends StatelessWidget {
  final BluetoothPermissionResult result;
  final VoidCallback onOpenSettings;

  const _PermissionBanner({
    required this.result,
    required this.onOpenSettings,
  });

  @override
  Widget build(BuildContext context) {
    final isPermanent =
        result == BluetoothPermissionResult.permanentlyDenied;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandBlueTint,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.brandBlue.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.brandBlue,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  isPermanent
                      ? 'Bluetooth permission is permanently denied. Open system settings to enable it.'
                      : 'Bluetooth & Location permissions are required to scan for devices.',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brandBlueDark,
                  ),
                ),
              ),
            ],
          ),
          if (isPermanent) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onOpenSettings,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Open Settings',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.brandBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ConnectedDeviceCard extends StatelessWidget {
  final String deviceName;
  final VoidCallback onDisconnect;

  const _ConnectedDeviceCard({
    required this.deviceName,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.brandBlueTint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.brandBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.paperWhite,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite,
              color: AppColors.brandBlue,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deviceName,
                  style: AppTypography.label,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.successGreen,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Connected',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.successGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onDisconnect,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.zonePeak,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
            ),
            child: const Text(
              'Disconnect',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DeviceCard extends StatelessWidget {
  final String deviceName;
  final String deviceAddress;
  final VoidCallback onTap;

  const _DeviceCard({
    required this.deviceName,
    required this.deviceAddress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.warmLinen,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.hairline),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.paperWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.hairline),
                ),
                child: const Icon(
                  Icons.bluetooth,
                  color: AppColors.charcoal,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      deviceName,
                      style: AppTypography.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      deviceAddress,
                      style: AppTypography.caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.pewter,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              color: AppColors.brandBlueTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.bluetooth_searching,
              size: 40,
              color: AppColors.brandBlue,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No devices found',
            style: AppTypography.label.copyWith(color: AppColors.charcoal),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Make sure your PulseX HR sensor is turned on\nand in pairing mode. Grant Bluetooth &\nLocation permissions if asked.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
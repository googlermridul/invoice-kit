import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_kit/core/di/injection.dart';
import 'package:invoice_kit/core/extensions/context_extensions.dart';
import 'package:invoice_kit/core/theme/app_radius.dart';
import 'package:invoice_kit/core/theme/app_spacing.dart';
import 'package:invoice_kit/features/authentication/domain/repositories/auth_repository.dart';
import 'package:invoice_kit/features/devices/domain/entities/device.dart';
import 'package:invoice_kit/features/devices/presentation/bloc/devices_cubit.dart';

class DevicesScreen extends StatelessWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<DevicesCubit>();
        // Best-effort: load the user's device list as soon as the screen
        // mounts. If the user is not signed in, the load still completes
        // with an empty list so the UI renders a clean empty state.
        sl<AuthRepository>().currentUser().then((user) {
          if (user != null) {
            cubit.load(user.id);
          } else {
            cubit.load('');
          }
        });
        return cubit;
      },
      child: const _DevicesView(),
    );
  }
}

class _DevicesView extends StatelessWidget {
  const _DevicesView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Devices')),
      body: BlocBuilder<DevicesCubit, DevicesState>(
        builder: (context, state) {
          if (state.status == DevicesStatus.loading && state.devices.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.error != null && state.devices.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Center(child: Text(state.error!)),
            );
          }
          if (state.devices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('No devices registered on this account.'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.devices.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, i) => _DeviceTile(
              device: state.devices[i],
              onRemove: (id) => context.read<DevicesCubit>().remove(id),
            ),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.onRemove});

  final Device device;
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: context.colors.outline),
      ),
      child: Row(
        children: [
          Icon(
            device.platform == 'ios' ? Icons.phone_iphone : Icons.devices,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.deviceName,
                  style: context.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${device.platform} · last seen ${_formatDate(device.lastSeenAt)}',
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                if (device.isCurrent) ...[
                  const SizedBox(height: 4),
                  Text(
                    'This device',
                    style: context.textTheme.labelSmall?.copyWith(
                      color: context.colors.primary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Remove device',
            icon: const Icon(Icons.delete_outline),
            onPressed: device.isCurrent
                ? null
                : () => onRemove(device.deviceId),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

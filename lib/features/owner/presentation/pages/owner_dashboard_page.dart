import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/constants/app_env.dart';
import 'package:app_2/features/owner/presentation/providers/owner_dashboard_provider.dart';
import 'package:app_2/features/update/presentation/providers/app_update_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class OwnerDashboardPage extends ConsumerStatefulWidget {
  const OwnerDashboardPage({super.key});

  @override
  ConsumerState<OwnerDashboardPage> createState() => _OwnerDashboardPageState();
}

class _OwnerDashboardPageState extends ConsumerState<OwnerDashboardPage> {
  final _pinController = TextEditingController();
  final _messageController = TextEditingController();
  final _searchController = TextEditingController();
  String? _selectedDirectUserId;
  final _directMessageController = TextEditingController();
  final _updateConfigUrlController = TextEditingController();
  var _isAuthorized = false;
  var _isLoadingUpdateConfig = false;

  @override
  void dispose() {
    _pinController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    _directMessageController.dispose();
    _updateConfigUrlController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUpdateConfig();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Owner Dashboard')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Card(
              child: Padding(
                padding: AppSpacing.p16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Masukkan PIN owner untuk akses dashboard Windows.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Owner PIN'),
                    ),
                    const SizedBox(height: AppSpacing.s12),
                    FilledButton(
                      onPressed: _authorize,
                      child: const Text('Masuk Dashboard Owner'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final dashboardAsync = ref.watch(ownerDashboardProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(ownerDashboardProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Padding(
        padding: AppSpacing.p16,
        child: dashboardAsync.when(
          data: (data) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _StatCard(
                      title: 'Jumlah user terdaftar',
                      value: '${data.userCount}',
                      icon: Icons.group_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s16),
                Card(
                  child: Padding(
                    padding: AppSpacing.p16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Konfigurasi update app',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Isi URL version.json publik agar semua device bisa cek update tanpa ubah kode.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        TextField(
                          controller: _updateConfigUrlController,
                          minLines: 1,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'URL update config (version.json)',
                            hintText:
                                'https://raw.githubusercontent.com/<user>/<repo>/main/version.json',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Default env: ${AppEnv.updateConfigUrl.isEmpty ? '- belum diatur -' : AppEnv.updateConfigUrl}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              onPressed: _isLoadingUpdateConfig
                                  ? null
                                  : _saveUpdateConfig,
                              icon: const Icon(Icons.save_rounded),
                              label: const Text('Simpan URL'),
                            ),
                            OutlinedButton.icon(
                              onPressed: _isLoadingUpdateConfig
                                  ? null
                                  : _resetUpdateConfig,
                              icon: const Icon(Icons.restore_rounded),
                              label: const Text('Reset ke default'),
                            ),
                            TextButton.icon(
                              onPressed: _isLoadingUpdateConfig
                                  ? null
                                  : _checkUpdateNow,
                              icon: const Icon(Icons.system_update_alt_rounded),
                              label: const Text('Cek update sekarang'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Card(
                  child: Padding(
                    padding: AppSpacing.p16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim notif global',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        Text(
                          'Pesan ini akan tampil sebagai info di aplikasi user setelah login.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        TextField(
                          controller: _messageController,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Isi notifikasi',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        FilledButton.icon(
                          onPressed: () async {
                            await ref
                                .read(ownerDashboardProvider.notifier)
                                .sendBroadcast(_messageController.text);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Notifikasi berhasil dikirim'),
                              ),
                            );
                            _messageController.clear();
                          },
                          icon: const Icon(Icons.campaign_rounded),
                          label: const Text('Kirim Notifikasi'),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          data.lastBroadcastMessage == null
                              ? 'Belum ada notifikasi terkirim'
                              : 'Terakhir: ${data.lastBroadcastMessage}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (data.lastBroadcastAt != null)
                          Text(
                            'Waktu: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(data.lastBroadcastAt!)}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Card(
                  child: Padding(
                    padding: AppSpacing.p16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kirim notif ter-target',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.s8),
                        DropdownButtonFormField<String>(
                          initialValue: _selectedDirectUserId,
                          decoration: const InputDecoration(
                            labelText: 'Pilih user tujuan',
                          ),
                          items: data.users
                              .map(
                                (user) => DropdownMenuItem(
                                  value: user.id,
                                  child: Text(user.username),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setState(() => _selectedDirectUserId = value);
                          },
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        TextField(
                          controller: _directMessageController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Isi notifikasi user terpilih',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        FilledButton.icon(
                          onPressed: () async {
                            final targetId = _selectedDirectUserId;
                            OwnerUserItem? target;
                            for (final user in data.users) {
                              if (user.id == targetId) {
                                target = user;
                                break;
                              }
                            }
                            if (target == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Pilih user tujuan terlebih dulu'),
                                ),
                              );
                              return;
                            }
                            await ref
                                .read(ownerDashboardProvider.notifier)
                                .sendDirectNotification(
                                  userId: target.id,
                                  username: target.username,
                                  message: _directMessageController.text,
                                );
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Notifikasi berhasil dikirim ke ${target.username}',
                                ),
                              ),
                            );
                            _directMessageController.clear();
                          },
                          icon: const Icon(Icons.person_pin_circle_rounded),
                          label: const Text('Kirim Notif User Terpilih'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                SizedBox(
                  height: 280,
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.p16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daftar user terdaftar',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              labelText: 'Cari username',
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Expanded(
                            child: _filteredUsers(data).isEmpty
                                ? const Center(
                                    child: Text('Belum ada user terdaftar'),
                                  )
                                : ListView.separated(
                                    itemCount: _filteredUsers(data).length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final user = _filteredUsers(data)[index];
                                      return ListTile(
                                        leading: const CircleAvatar(
                                          child: Icon(Icons.person_rounded),
                                        ),
                                        title: Text(user.username),
                                        subtitle: Text(
                                          user.createdAt == null
                                              ? 'Tanggal daftar tidak tersedia'
                                              : 'Daftar: ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(user.createdAt!)}',
                                        ),
                                        trailing: Text(
                                          user.id,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s16),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: AppSpacing.p16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Riwayat notifikasi owner',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Expanded(
                            child: data.history.isEmpty
                                ? const Center(
                                    child: Text('Belum ada riwayat notifikasi'),
                                  )
                                : ListView.separated(
                                    itemCount: data.history.length,
                                    separatorBuilder: (_, _) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, index) {
                                      final item = data.history[index];
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          item.target ==
                                                  OwnerNotificationTarget.global
                                              ? Icons.campaign_rounded
                                              : Icons.person_pin_circle_rounded,
                                        ),
                                        title: Text(item.message),
                                        subtitle: Text(
                                          item.target ==
                                                  OwnerNotificationTarget.global
                                              ? 'Global • ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(item.createdAt)}'
                                              : 'Ke ${item.targetUsername ?? '-'} • ${DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(item.createdAt)}',
                                        ),
                                      );
                                    },
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          error: (error, _) => Center(child: Text('Terjadi error: $error')),
          loading: () => const Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Future<void> _loadUpdateConfig() async {
    setState(() => _isLoadingUpdateConfig = true);
    try {
      final configured = await ref
          .read(appUpdateProvider.notifier)
          .getConfiguredUpdateUrl();
      if (!mounted) {
        return;
      }
      _updateConfigUrlController.text = configured ?? '';
    } finally {
      if (mounted) {
        setState(() => _isLoadingUpdateConfig = false);
      }
    }
  }

  Future<void> _saveUpdateConfig() async {
    setState(() => _isLoadingUpdateConfig = true);
    try {
      await ref
          .read(appUpdateProvider.notifier)
          .saveConfiguredUpdateUrl(_updateConfigUrlController.text);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL update berhasil disimpan')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingUpdateConfig = false);
      }
    }
  }

  Future<void> _resetUpdateConfig() async {
    setState(() => _isLoadingUpdateConfig = true);
    try {
      await ref.read(appUpdateProvider.notifier).saveConfiguredUpdateUrl(null);
      if (!mounted) {
        return;
      }
      _updateConfigUrlController.text = AppEnv.updateConfigUrl;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('URL update dikembalikan ke default env')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingUpdateConfig = false);
      }
    }
  }

  Future<void> _checkUpdateNow() async {
    setState(() => _isLoadingUpdateConfig = true);
    try {
      await ref.read(appUpdateProvider.notifier).checkNow();
      if (!mounted) {
        return;
      }
      final latest = ref.read(appUpdateProvider).valueOrNull;
      final hasUpdate = latest?.hasUpdate ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            hasUpdate
                ? 'Update tersedia: v${latest?.latestVersion}'
                : 'Belum ada update baru',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingUpdateConfig = false);
      }
    }
  }

  void _authorize() {
    final pin = _pinController.text.trim();
    if (pin == AppEnv.ownerDashboardPin) {
      setState(() => _isAuthorized = true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('PIN owner tidak valid')),
    );
  }

  List<OwnerUserItem> _filteredUsers(OwnerDashboardState data) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return data.users;
    }
    return data.users
        .where((user) => user.username.toLowerCase().contains(query))
        .toList();
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: Card(
        child: Padding(
          padding: AppSpacing.p16,
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                child: Icon(icon, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(width: AppSpacing.s12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.bodySmall),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

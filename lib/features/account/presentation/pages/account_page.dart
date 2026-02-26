import 'package:app_2/core/constants/app_spacing.dart';
import 'package:app_2/core/utils/local_image_preview.dart';
import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/finance/presentation/providers/backup_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authControllerProvider).valueOrNull;
    final username = session?.identifier ?? 'User';
    final profilePhotoPath = ref
        .read(authControllerProvider.notifier)
        .currentProfilePhotoPath();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(title: const Text('Akun Saya')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF7FBFC), Color(0xFFEFF3FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
          children: [
            _ProfileHeroCard(
              username: username,
              profilePhotoPath: profilePhotoPath,
              onPickPhoto: () => _pickProfilePhoto(context, ref),
              onRemovePhoto: profilePhotoPath == null
                  ? null
                  : () => _removeProfilePhoto(context, ref),
            ),
            const SizedBox(height: 14),
            _AccountActionCard(
              title: 'Backup Data',
              subtitle: 'Ekspor atau impor backup JSON akun Anda.',
              icon: Icons.backup_rounded,
              children: [
                FilledButton.icon(
                  onPressed: () => _exportBackup(context, ref),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Ekspor JSON'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _importBackup(context, ref),
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Impor JSON'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _AccountActionCard(
              title: 'Sesi',
              subtitle: 'Keluar dari akun saat ini.',
              icon: Icons.manage_accounts_rounded,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (!context.mounted) {
                      return;
                    }
                    context.go('/');
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Logout'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, WidgetRef ref) async {
    try {
      final path = await ref.read(backupControllerProvider).exportCurrentUserData();
      if (!context.mounted || path == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup berhasil disimpan: $path')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ekspor backup: $error')));
    }
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Impor backup'),
          content: const Text(
            'Impor akan menimpa seluruh akun, kategori, dan transaksi user yang sedang login. Lanjutkan?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Lanjut impor'),
            ),
          ],
        );
      },
    );
    if (confirmed != true) {
      return;
    }

    try {
      final path = await ref.read(backupControllerProvider).importCurrentUserData();
      if (!context.mounted || path == null) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup berhasil diimpor dari: $path')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal impor backup: $error')));
    }
  }

  Future<void> _pickProfilePhoto(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final path = picked.files.single.path;
    if (path == null || path.trim().isEmpty) {
      return;
    }

    await ref
        .read(authControllerProvider.notifier)
        .updateCurrentProfilePhotoPath(path);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Foto profil diperbarui')));
  }

  Future<void> _removeProfilePhoto(BuildContext context, WidgetRef ref) async {
    await ref.read(authControllerProvider.notifier).updateCurrentProfilePhotoPath(
      null,
    );
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Foto profil dihapus')));
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.username,
    required this.profilePhotoPath,
    required this.onPickPhoto,
    this.onRemovePhoto,
  });

  final String username;
  final String? profilePhotoPath;
  final VoidCallback onPickPhoto;
  final VoidCallback? onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F756D), Color(0xFF1E3A8A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x290F766E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: ClipOval(
                  child: profilePhotoPath == null
                      ? CircleAvatar(
                          backgroundColor: const Color(0xFF0B4B46),
                          child: Text(
                            username.isEmpty ? 'U' : username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                      : buildLocalImageThumbnail(
                          path: profilePhotoPath!,
                          width: 72,
                          height: 72,
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Profil Hmatt',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFFDCEEFF),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: onPickPhoto,
                  icon: const Icon(Icons.photo_camera_back_rounded),
                  label: const Text('Ganti foto'),
                ),
              ),
              if (onRemovePhoto != null) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRemovePhoto,
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text('Hapus foto'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _AccountActionCard extends StatelessWidget {
  const _AccountActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.p16,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE6EDF5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFF0F766E).withValues(alpha: 0.12),
                child: Icon(icon, color: const Color(0xFF0F766E)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

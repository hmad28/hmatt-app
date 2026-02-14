import 'dart:convert';

import 'package:app_2/core/constants/app_env.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateInfo {
  const UpdateInfo({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateMessage,
    required this.updateUrl,
    required this.dismissed,
  });

  final String currentVersion;
  final String latestVersion;
  final String updateMessage;
  final String? updateUrl;
  final bool dismissed;

  bool get hasUpdate {
    final comparison = _compareSemVer(latestVersion, currentVersion);
    return comparison > 0;
  }

  bool get shouldShowBanner => hasUpdate && !dismissed;

  UpdateInfo copyWith({
    String? currentVersion,
    String? latestVersion,
    String? updateMessage,
    String? updateUrl,
    bool? dismissed,
  }) {
    return UpdateInfo(
      currentVersion: currentVersion ?? this.currentVersion,
      latestVersion: latestVersion ?? this.latestVersion,
      updateMessage: updateMessage ?? this.updateMessage,
      updateUrl: updateUrl ?? this.updateUrl,
      dismissed: dismissed ?? this.dismissed,
    );
  }
}

final appUpdateProvider =
    AsyncNotifierProvider<AppUpdateController, UpdateInfo>(
      AppUpdateController.new,
    );

class AppUpdateController extends AsyncNotifier<UpdateInfo> {
  static const _configKey = 'app_update_config';
  static const _sessionFetchFlagKey = 'app_update_checked_in_session';
  static const _customConfigUrlKey = 'app_update_config_url';

  @override
  Future<UpdateInfo> build() async {
    final currentVersion = await _readCurrentAppVersion();
    await _readLocalConfig(currentVersion: currentVersion);
    await _ensureSingleFetchPerSession();
    return _readLocalConfig(currentVersion: currentVersion);
  }

  Future<void> checkNow() async {
    await _refreshFromRemote(force: true);
  }

  Future<String?> getConfiguredUpdateUrl() async {
    return _resolveConfigUrl();
  }

  Future<void> saveConfiguredUpdateUrl(String? value) async {
    final clean = value?.trim() ?? '';
    if (!Hive.isBoxOpen('auth_box')) {
      return;
    }

    final box = Hive.box<Map>('auth_box');
    if (clean.isEmpty) {
      await box.delete(_customConfigUrlKey);
    } else {
      await box.put(_customConfigUrlKey, {'value': clean});
    }
    await _refreshFromRemote(force: true);
  }

  Future<void> dismissBanner() async {
    final current = state.valueOrNull;
    if (current == null || !Hive.isBoxOpen('auth_box')) {
      return;
    }
    final updated = current.copyWith(dismissed: true);
    await _saveLocalConfig(updated);
    state = AsyncData(updated);
  }

  Future<void> openUpdateUrl() async {
    final current = state.valueOrNull;
    final rawUrl = current?.updateUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return;
    }

    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      return;
    }

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _ensureSingleFetchPerSession() async {
    if (!Hive.isBoxOpen('auth_box')) {
      return;
    }

    final box = Hive.box<Map>('auth_box');
    final checked = box.get(_sessionFetchFlagKey);
    final hasChecked = checked?['done'] as bool? ?? false;
    if (hasChecked) {
      return;
    }

    await box.put(_sessionFetchFlagKey, {'done': true});
    await _refreshFromRemote(force: false);
  }

  Future<void> _refreshFromRemote({required bool force}) async {
    final current = state.valueOrNull;
    final local = current ??
        await _readLocalConfig(currentVersion: await _readCurrentAppVersion());
    final remote = await _fetchRemoteUpdateConfig();
    if (remote == null) {
      return;
    }

    final merged = local.copyWith(
      latestVersion: remote.latestVersion,
      updateMessage: remote.updateMessage,
      updateUrl: remote.updateUrl,
      dismissed: force ? false : local.dismissed,
    );
    await _saveLocalConfig(merged);
    state = AsyncData(merged);
  }

  Future<UpdateInfo> _readLocalConfig({required String currentVersion}) async {
    if (!Hive.isBoxOpen('auth_box')) {
      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        updateMessage: 'Aplikasi sudah versi terbaru',
        updateUrl: null,
        dismissed: false,
      );
    }

    final box = Hive.box<Map>('auth_box');
    final raw = box.get(_configKey);
    if (raw == null) {
      final initial = UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: currentVersion,
        updateMessage: 'Aplikasi sudah versi terbaru',
        updateUrl: null,
        dismissed: false,
      );
      await _saveLocalConfig(initial);
      return initial;
    }

    final local = UpdateInfo(
      currentVersion: currentVersion,
      latestVersion: (raw['latestVersion'] as String?) ?? currentVersion,
      updateMessage:
          (raw['updateMessage'] as String?) ?? 'Versi baru tersedia untuk Hmatt.',
      updateUrl: raw['updateUrl'] as String?,
      dismissed: raw['dismissed'] as bool? ?? false,
    );

    if (!local.hasUpdate && local.latestVersion != currentVersion) {
      final normalized = local.copyWith(
        latestVersion: currentVersion,
        dismissed: false,
      );
      await _saveLocalConfig(normalized);
      return normalized;
    }

    return local;
  }

  Future<void> _saveLocalConfig(UpdateInfo config) async {
    if (!Hive.isBoxOpen('auth_box')) {
      return;
    }
    await Hive.box<Map>('auth_box').put(_configKey, {
      'latestVersion': config.latestVersion,
      'updateMessage': config.updateMessage,
      'updateUrl': config.updateUrl,
      'dismissed': config.dismissed,
    });
  }

  Future<UpdateInfo?> _fetchRemoteUpdateConfig() async {
    final url = (await _resolveConfigUrl())?.trim() ?? '';
    if (url.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(url);
    if (uri == null) {
      return null;
    }

    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final latestVersion = (decoded['latest_version'] as String?)?.trim();
      final updateMessage = (decoded['update_message'] as String?)?.trim();
      final updateUrl = (decoded['update_url'] as String?)?.trim();
      if (latestVersion == null || latestVersion.isEmpty) {
        return null;
      }

      final currentVersion = await _readCurrentAppVersion();
      return UpdateInfo(
        currentVersion: currentVersion,
        latestVersion: latestVersion,
        updateMessage: (updateMessage == null || updateMessage.isEmpty)
            ? 'Versi baru tersedia untuk Hmatt.'
            : updateMessage,
        updateUrl: updateUrl,
        dismissed: false,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveConfigUrl() async {
    String? custom;
    if (Hive.isBoxOpen('auth_box')) {
      final raw = Hive.box<Map>('auth_box').get(_customConfigUrlKey);
      custom = (raw?['value'] as String?)?.trim();
    }

    final selected =
        (custom != null && custom.isNotEmpty) ? custom : AppEnv.updateConfigUrl.trim();
    if (selected.isEmpty) {
      return null;
    }
    if (selected.contains('example.com') ||
        selected.contains('your-github-username')) {
      return null;
    }
    return selected;
  }

  Future<String> _readCurrentAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      if (version.isNotEmpty) {
        return version;
      }
      return '1.0.0';
    } catch (_) {
      return '1.0.0';
    }
  }
}

int _compareSemVer(String left, String right) {
  final l = _parseSemVer(left);
  final r = _parseSemVer(right);
  for (var i = 0; i < 3; i++) {
    final delta = l[i] - r[i];
    if (delta != 0) {
      return delta;
    }
  }
  return 0;
}

List<int> _parseSemVer(String value) {
  final clean = value.split('+').first.trim();
  final parts = clean.split('.');
  return List<int>.generate(3, (index) {
    if (index >= parts.length) {
      return 0;
    }
    return int.tryParse(parts[index]) ?? 0;
  });
}

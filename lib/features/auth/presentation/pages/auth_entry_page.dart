import 'package:app_2/features/auth/domain/models/auth_models.dart';
import 'package:app_2/features/auth/presentation/providers/auth_providers.dart';
import 'package:app_2/features/owner/presentation/providers/owner_dashboard_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

class AuthEntryPage extends ConsumerStatefulWidget {
  const AuthEntryPage({super.key});

  @override
  ConsumerState<AuthEntryPage> createState() => _AuthEntryPageState();
}

class _AuthEntryPageState extends ConsumerState<AuthEntryPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loginUsernameController = TextEditingController();
  final _loginPasswordController = TextEditingController();
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerSecurityQuestionController = TextEditingController();
  final _registerSecurityAnswerController = TextEditingController();
  String? _lastOwnerMessageShown;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginUsernameController.dispose();
    _loginPasswordController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _registerSecurityQuestionController.dispose();
    _registerSecurityAnswerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authControllerProvider);
    final isLoading = authAsync.isLoading;
    final ownerState = ref.watch(ownerDashboardProvider).valueOrNull;
    final session = authAsync.valueOrNull;
    final ownerBroadcast = _resolveVisibleOwnerMessage(
      ownerState,
      session?.userId,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          ownerBroadcast == null ||
          ownerBroadcast.isEmpty ||
          ownerBroadcast == _lastOwnerMessageShown) {
        return;
      }
      _lastOwnerMessageShown = ownerBroadcast;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('Notifikasi owner: $ownerBroadcast'),
          duration: const Duration(seconds: 5),
        ),
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F766E), Color(0xFF1E3A8A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hmatt',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Aplikasi offline sederhana. Login pakai username dan password.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            TabBar(
                              controller: _tabController,
                              tabs: const [
                                Tab(text: 'Masuk'),
                                Tab(text: 'Daftar'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 320,
                              child: TabBarView(
                                controller: _tabController,
                                children: [
                                  _LoginForm(
                                    usernameController:
                                        _loginUsernameController,
                                    passwordController:
                                        _loginPasswordController,
                                  ),
                                  _RegisterForm(
                                    usernameController:
                                        _registerUsernameController,
                                    passwordController:
                                        _registerPasswordController,
                                    securityQuestionController:
                                        _registerSecurityQuestionController,
                                    securityAnswerController:
                                        _registerSecurityAnswerController,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final router = GoRouter.of(context);

                              if (_tabController.index == 0) {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .login(
                                      identifier: _loginUsernameController.text,
                                      password: _loginPasswordController.text,
                                    );
                              } else {
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .register(
                                      username: _registerUsernameController.text,
                                      password: _registerPasswordController.text,
                                      securityQuestion:
                                          _registerSecurityQuestionController.text,
                                      securityAnswer:
                                          _registerSecurityAnswerController.text,
                                    );
                              }

                              if (!mounted) {
                                return;
                              }

                              final auth = ref.read(authControllerProvider).value;
                              if (auth?.status == AuthStatus.authenticated) {
                                router.go('/home');
                                return;
                              }

                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Username/password tidak valid'),
                                ),
                              );
                            },
                      child: Text(
                        isLoading
                            ? 'Memproses...'
                            : _tabController.index == 0
                            ? 'Masuk'
                            : 'Daftar',
                      ),
                    ),
                    if (defaultTargetPlatform == TargetPlatform.windows) ...[
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/owner'),
                        icon: const Icon(Icons.admin_panel_settings_rounded),
                        label: const Text('Owner Dashboard (Windows)'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String? _resolveVisibleOwnerMessage(
    OwnerDashboardState? state,
    String? currentUserId,
  ) {
    if (state == null) {
      return null;
    }
    final message = state.lastBroadcastMessage;
    if (message == null || message.isEmpty) {
      return null;
    }
    final target = state.lastBroadcastTarget;
    if (target == OwnerNotificationTarget.global) {
      return message;
    }
    if (target == OwnerNotificationTarget.direct &&
        currentUserId != null &&
        state.lastBroadcastTargetUserId == currentUserId) {
      return message;
    }
    return null;
  }
}

class _LoginForm extends StatelessWidget {
  const _LoginForm({
    required this.usernameController,
    required this.passwordController,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
        ),
      ],
    );
  }
}

class _RegisterForm extends StatelessWidget {
  const _RegisterForm({
    required this.usernameController,
    required this.passwordController,
    required this.securityQuestionController,
    required this.securityAnswerController,
  });

  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final TextEditingController securityQuestionController;
  final TextEditingController securityAnswerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username baru'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password (minimal 4 karakter)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: securityQuestionController,
          decoration: const InputDecoration(
            labelText: 'Security question (opsional)',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: securityAnswerController,
          decoration: const InputDecoration(
            labelText: 'Jawaban security question (opsional)',
          ),
        ),
      ],
    );
  }
}

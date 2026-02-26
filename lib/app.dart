import 'package:app_2/core/router/app_router.dart';
import 'package:app_2/core/theme/app_theme.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Hmatt',
      theme: AppTheme.light(),
      routerConfig: AppRouter.router,
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      debugShowCheckedModeBanner: false,
    );
  }
}

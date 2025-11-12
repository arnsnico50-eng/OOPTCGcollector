import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ooptcgcollector/app/router/app_router.dart';
import 'package:ooptcgcollector/app/theme/app_theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: OnePieceTCGApp(),
    ),
  );
}

class OnePieceTCGApp extends ConsumerWidget {
  const OnePieceTCGApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'One Piece TCG Collector',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
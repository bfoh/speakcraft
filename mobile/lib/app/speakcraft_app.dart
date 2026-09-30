import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/components.dart';
import 'router.dart';
import 'services.dart';
import 'theme.dart';

class SpeakCraftBootstrap extends ConsumerWidget {
  const SpeakCraftBootstrap({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(bootstrapProvider)
      .when(
        data: (services) => ProviderScope(
          overrides: [servicesProvider.overrideWithValue(services)],
          child: const SpeakCraftApp(),
        ),
        loading: () => MaterialApp(
          theme: SpeakCraftTheme.light,
          home: const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                semanticsLabel: 'Opening SpeakCraft',
              ),
            ),
          ),
        ),
        error: (error, stack) => MaterialApp(
          theme: SpeakCraftTheme.light,
          home: SpeakCraftPage(
            title: 'Let’s try again',
            children: [
              const Text(
                "We couldn't open your saved practice. Check that your phone has free space, then try again.",
              ),
              SpeakCraftButton(
                label: 'Try again',
                icon: Icons.refresh,
                onPressed: () => ref.invalidate(bootstrapProvider),
              ),
            ],
          ),
        ),
      );
}

class SpeakCraftApp extends ConsumerWidget {
  const SpeakCraftApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp.router(
    title: 'SpeakCraft',
    debugShowCheckedModeBanner: false,
    theme: SpeakCraftTheme.light,
    routerConfig: ref.watch(routerProvider),
  );
}

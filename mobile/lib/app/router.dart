import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/conversation/conversation_screen.dart';
import '../features/help_me_say_it/expression_screen.dart';
import '../features/lesson/lesson_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../shared/components.dart';
import 'services.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final session = ref.watch(sessionProvider);
  final router = GoRouter(
    initialLocation: session.progress.onboarded
        ? '/home'
        : onboardingPaths[session.progress.onboardingStep],
    refreshListenable: session,
    redirect: (context, state) {
      final location = state.uri.path;
      final step = onboardingPaths.indexOf(location);
      if (session.progress.onboarded) return step >= 0 ? '/home' : null;
      if (step == -1 || step > session.progress.onboardingStep) {
        return onboardingPaths[session.progress.onboardingStep];
      }
      return null;
    },
    routes: [
      for (var step = 0; step < onboardingPaths.length; step++)
        GoRoute(
          path: onboardingPaths[step],
          builder: (context, state) => OnboardingScreen(step: step),
        ),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      for (var day = 1; day <= 5; day++)
        GoRoute(
          path: '/lesson/day-$day',
          builder: (context, state) => LessonScreen(day: day),
        ),
      GoRoute(
        path: '/conversation/day-1',
        builder: (context, state) => const ConversationScreen(),
      ),
      GoRoute(
        path: '/salon/first',
        builder: (context, state) => const ConversationScreen(salon: true),
      ),
      GoRoute(
        path: '/help-me-say-it',
        builder: (context, state) => const ExpressionScreen(),
      ),
    ],
    errorBuilder: (context, state) => SpeakCraftPage(
      title: 'Let’s go back',
      children: [
        const Text('This page is not available.'),
        SpeakCraftButton(
          label: 'Go to Home',
          icon: Icons.home_outlined,
          onPressed: () => context.go('/home'),
        ),
      ],
    ),
  );
  ref.onDispose(router.dispose);
  return router;
}, dependencies: [sessionProvider]);

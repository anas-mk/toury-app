import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

import '../../features/tourist/features/auth/presentation/pages/login_page.dart';
import '../../features/tourist/features/home/presentation/pages/home_layout.dart';


class AppRouter {
  static const String login = '/login';
  static const String home = '/home';

  static final GoRouter router = GoRouter(
    initialLocation: login,
    routes: [
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeLayout(),
      ),
    ],
    errorBuilder:
        (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(login),
              child: const Text('Go to Login'),
            ),
          ],
        ),
      ),
    ),
  );
}


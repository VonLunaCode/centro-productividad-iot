import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/profiles/profile_list_screen.dart';
import '../../features/profiles/profile_detail_screen.dart';
import '../../features/profiles/calibration_screen.dart';
import '../../features/session/active_session_screen.dart';
import '../../features/history/history_list_screen.dart';
import '../../features/history/session_detail_screen.dart';
import '../../features/history/models/session_history.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/profiles/models/profile.dart';
import 'router_guards.dart';

class AppRoutes {
  static const home = '/';
  static const login = '/login';
  static const profiles = '/profiles';
  static const profileDetail = '/profile-detail';
  static const calibration = '/calibration';
  static const session = '/session';
  static const history = '/history';
  static const sessionDetail = '/session-detail';
  static const onboarding = '/onboarding';
  static const settings = '/settings';
  static const register = '/register';
}

CustomTransitionPage<void> _page(LocalKey key, Widget child) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) {
      final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
          .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
      return FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(position: slideAnim, child: child),
      );
    },
  );
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const HomeScreen()),
    ),
    GoRoute(
      path: AppRoutes.login,
      redirect: RouterGuards.redirectIfAuthenticated,
      pageBuilder: (context, state) => _page(state.pageKey, const LoginScreen()),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const ProfileListScreen()),
    ),
    GoRoute(
      path: AppRoutes.profileDetail,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) {
        final profile = state.extra as Profile;
        return _page(state.pageKey, ProfileDetailScreen(profile: profile));
      },
    ),
    GoRoute(
      path: AppRoutes.calibration,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) {
        final profile = state.extra as Profile;
        return _page(state.pageKey, CalibrationScreen(profile: profile));
      },
    ),
    GoRoute(
      path: AppRoutes.session,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const ActiveSessionScreen()),
    ),
    GoRoute(
      path: AppRoutes.history,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const HistoryListScreen()),
    ),
    GoRoute(
      path: AppRoutes.sessionDetail,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) {
        final session = state.extra as SessionHistory;
        return _page(state.pageKey, SessionDetailScreen(session: session));
      },
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const OnboardingScreen()),
    ),
    GoRoute(
      path: AppRoutes.settings,
      redirect: RouterGuards.requiresAuth,
      pageBuilder: (context, state) => _page(state.pageKey, const SettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.register,
      pageBuilder: (context, state) => _page(state.pageKey, const RegisterScreen()),
    ),
  ],
);

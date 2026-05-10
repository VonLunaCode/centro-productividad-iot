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

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(
      path: AppRoutes.home,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.login,
      redirect: RouterGuards.redirectIfAuthenticated,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.profiles,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const ProfileListScreen(),
    ),
    GoRoute(
      path: AppRoutes.profileDetail,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) {
        final profile = state.extra as Profile;
        return ProfileDetailScreen(profile: profile);
      },
    ),
    GoRoute(
      path: AppRoutes.calibration,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) {
        final profile = state.extra as Profile;
        return CalibrationScreen(profile: profile);
      },
    ),
    GoRoute(
      path: AppRoutes.session,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const ActiveSessionScreen(),
    ),
    GoRoute(
      path: AppRoutes.history,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const HistoryListScreen(),
    ),
    GoRoute(
      path: AppRoutes.sessionDetail,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) {
        final session = state.extra as SessionHistory;
        return SessionDetailScreen(session: session);
      },
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      redirect: RouterGuards.requiresAuth,
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
    ),
  ],
);

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mumo_mobile/features/Auth/Presentation/RegisterOne_page.dart';
import 'package:mumo_mobile/features/Auth/Presentation/Register_page.dart';
import 'package:mumo_mobile/features/Auth/Presentation/choose_workspace_page.dart';
import 'package:mumo_mobile/features/Auth/Presentation/login_page.dart';
import 'package:mumo_mobile/features/Manage_Agency/Presentation/manager_home.dart';
import 'package:mumo_mobile/features/Manage_Agency/Presentation/agency_registerpage.dart';
import 'package:mumo_mobile/features/Manage_Agency/Presentation/agency_edit_page.dart';
import 'package:mumo_mobile/features/Manage_Agency/Presentation/ManagerReport_page.dart';
import 'package:mumo_mobile/features/Auth/Presentation/edit_profile_page.dart';
import 'package:mumo_mobile/features/Auth/Presentation/edit_security.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/splash/splashcreen_page.dart';
import '../features/Agent/Presentation/AgentMainScreen_page.dart';
import '../features/Manage_Agency/Presentation/ManagerMainScreen_page.dart';
import '../features/debug/presentation/debug_logs_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingPage(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/choose-workspace',
        builder: (context, state) => const ChooseWorkspacePage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterStepOne(),
      ),
      GoRoute(
        path: '/register2',
        builder: (context, state) => const RegisterStepTwoPage(),
      ),
      GoRoute(
        path: '/agent-home',
        builder: (context, state) => const AgentmainscreenPage(),
      ),
      GoRoute(
        path: '/manager-home',
        builder: (context, state) => const ManagerHome(),
      ),
      GoRoute(
        path: '/create-agency',
        builder: (context, state) => const CreateAgencyPage(),
      ),
      GoRoute(
        path: '/edit-agency',
        builder: (context, state) => const EditAgencyPage(),
      ),
      GoRoute(
        path: '/edit-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/manage-agency',
        builder: (context, state) => const ManagerMainScreen(),
      ),
      GoRoute(
        path: '/manager-reports',
        builder: (context, state) => const ManagerReportPage(),
      ),
      GoRoute(
        path: '/edit-security',
        builder: (context, state) => const EditSecurityPage(),
      ),
      GoRoute(
        path: '/debug-logs',
        builder: (context, state) => const DebugLogsPage(),
      ),
    ],
  );
});

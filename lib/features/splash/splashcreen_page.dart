import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/token_storage.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../features/Auth/Controller/login_controller.dart';
import '../../features/Manage_Agency/Controller/agency_check_controller.dart';
import '../../features/Manage_Agency/data/agency_check_state_model.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with TickerProviderStateMixin {
  bool _navigationHandled = false;
  String? _startupError;
  late final ProviderSubscription _agencyCheckSub;

  // Retry button state
  bool _isRetrying = false;

  static const _mumoRed = Color(0xFFD30022);
  static const Set<String> _managerRoles = {'admin'};

  late final AnimationController _entryCtrl;
  late final AnimationController _dotsCtrl;

  // Refresh button rotation
  late final AnimationController _refreshCtrl;
  late final Animation<double> _refreshRotation;

  // ── Entry (utilisés avec FadeTransition / SlideTransition) ───
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _titleFade;
  late final Animation<Offset> _subSlide;
  late final Animation<double> _subFade;
  late final Animation<double> _dotsFade;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();

    //gère la redirection de l'utilisateur au démarrage de l'application
    _agencyCheckSub = ref.listenManual(agencyCheckControllerProvider, (
      previous,
      next,
    ) async {
      if (_navigationHandled || !next.isChecked) {
        return;
      }

      if (!mounted) {
        return;
      }

      if (next.statusCode == 401) {
        _navigationHandled = true;
        await ref.read(tokenStorageProvider).clear();
        if (mounted) {
          _handleRedirection('/login');
        }
        return;
      }

      final targetRoute = _resolveRoute(next);
      if (targetRoute != null) {
        _navigationHandled = true;
        if (mounted) {
          _handleRedirection(targetRoute);
        }
        return;
      }

      if (mounted) {
        setState(() {
          _startupError =
              next.errorMessage ??
              'Connexion etablie, mais impossible de verifier votre espace pour le moment.';
        });
      }
    });
  }

  void _handleRedirection(String route) {
    if (!mounted) return;
    context.go(route);
  }

  String? _resolveRoute(AgencyCheckStateModel next) {
    final user = ref.read(authControllerProvider).user;
    final role = user?.role?.trim().toLowerCase();
    final contexts = user?.contexts ?? const [];
    if (contexts.length > 1) {
      return '/choose-workspace';
    }
    if (contexts.length == 1) {
      final contextRole = contexts.first.role?.trim().toLowerCase();
      if (contextRole == 'agent' || contextRole == 'user') {
        return '/agent-home';
      }
      if (_managerRoles.contains(contextRole)) {
        if (next.hasAgency) {
          return '/manage-agency';
        }
        if (next.statusCode == 404) {
          return '/create-agency';
        }
      }
    }

    final isManager = role != null && _managerRoles.contains(role);
    final isAgent = role == 'agent' || role == 'user';

    final mustChange =
        ref.read(authControllerProvider).user?.mustChangePassword ?? false;
    if (mustChange) {
      return '/edit-security';
    }

    if (isAgent) {
      return '/agent-home';
    }

    if (role == null || role.isEmpty) {
      return '/choose-workspace';
    }

    if (isManager) {
      if (next.hasAgency) {
        return '/manage-agency';
      }
      if (next.statusCode == 404) {
        return '/create-agency';
      }
      if (next.errorMessage != null) {
        return null;
      }
      return '/create-agency';
    }

    if (next.hasAgency) {
      return '/manage-agency';
    }
    if (next.statusCode == 404) {
      return '/create-agency';
    }
    if (next.errorMessage != null) {
      return null;
    }
    return '/login';
  }

  Future<void> _bootstrapSessionAndCheckAgency() async {
    final token = await ref.read(tokenStorageProvider).readToken();
    if (!mounted || _navigationHandled) {
      return;
    }

    if (token == null || token.isEmpty) {
      //await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_navigationHandled) {
        _handleRedirection('/onboarding');
      }
      return;
    }

    final authNotifier = ref.read(authControllerProvider.notifier);
    await authNotifier.ensureUserLoaded();
    if (!mounted || _navigationHandled) {
      return;
    }

    if (ref.read(authControllerProvider).user == null) {
      await authNotifier.fetchCurrentUser();
      if (!mounted || _navigationHandled) {
        return;
      }
    }

    final role = ref
        .read(authControllerProvider)
        .user
        ?.role
        ?.trim()
        .toLowerCase();
    final contexts =
        ref.read(authControllerProvider).user?.contexts ?? const [];
    if (contexts.length > 1) {
      //await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_navigationHandled) {
        _handleRedirection('/choose-workspace');
      }
      return;
    }
    if (contexts.isEmpty && (role == null || role.isEmpty)) {
      //await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_navigationHandled) {
        _handleRedirection('/choose-workspace');
      }
      return;
    }

    final isManager = role != null && _managerRoles.contains(role);
    if (!isManager) {
      //await Future.delayed(const Duration(milliseconds: 900));
      if (mounted && !_navigationHandled) {
        final mustChange =
            ref.read(authControllerProvider).user?.mustChangePassword ?? false;
        _handleRedirection(mustChange ? '/edit-security' : '/agent-home');
      }
      return;
    }

    if (mounted) {
      setState(() {
        _startupError = null;
      });
    }
    ref.read(agencyCheckControllerProvider.notifier).checkAgency();
  }

  Future<void> _retryCheck() async {
    if (!mounted || _navigationHandled) return;
    setState(() {
      _isRetrying = true;
      _startupError = null;
    });
    _refreshCtrl.repeat();
    try {
      _navigationHandled = false;
      await _bootstrapSessionAndCheckAgency();
    } finally {
      if (mounted) {
        _refreshCtrl.stop();
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  void _setupAnimations() {
    // ── Entry (750 ms, one-shot) ──────────────────────────────
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Titre — SlideTransition en unités fractionnaires
    _titleSlide = Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.3, 0.75, curve: Curves.easeOutCubic),
          ),
        );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.3, 0.7, curve: Curves.easeOut),
      ),
    );

    // Sous-titre
    _subSlide = Tween<Offset>(begin: const Offset(0, 0.7), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _entryCtrl,
            curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic),
          ),
        );
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.5, 0.85, curve: Curves.easeOut),
      ),
    );

    // Dots + divider
    _dotsFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: const Interval(0.72, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Dots bounce (1.4 s, repeat) ───────────────────────────
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Refresh icon rotation (used when user taps "reessayer")
    _refreshCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _refreshRotation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _refreshCtrl, curve: Curves.linear));
  }

  Future<void> _startSequence() async {
    //await Future.delayed(const Duration(milliseconds: 180));
    if (mounted) _entryCtrl.forward();

    await _bootstrapSessionAndCheckAgency();
  }

  @override
  void dispose() {
    _agencyCheckSub.close();
    _entryCtrl.dispose();
    _dotsCtrl.dispose();
    _refreshCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Logo statique ────────────────────────────────
              const _StaticLogo(color: _mumoRed),

              const SizedBox(height: 32),

              // ── Titre ─────────────────────────────────────────
              // ClipRect nécessaire pour que SlideTransition
              // ne déborde pas hors de sa zone
              ClipRect(
                child: SlideTransition(
                  position: _titleSlide,
                  child: FadeTransition(
                    opacity: _titleFade,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                        children: [
                          TextSpan(
                            text: 'Mumo',
                            style: TextStyle(color: colors.textPrimary),
                          ),
                          const TextSpan(
                            text: 'Agent',
                            style: TextStyle(color: _mumoRed),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Sous-titre ────────────────────────────────────
              ClipRect(
                child: SlideTransition(
                  position: _subSlide,
                  child: FadeTransition(
                    opacity: _subFade,
                    child: Text(
                      'AGENCE MULTI-CABINES MOBILE MONEY',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        letterSpacing: 0.8,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Divider décoratif ─────────────────────────────
              FadeTransition(
                opacity: _dotsFade,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 28, height: 1, color: colors.border),
                    const SizedBox(width: 8),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _mumoRed.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 28, height: 1, color: colors.border),
                  ],
                ),
              ),

              const SizedBox(height: 52),

              // ── Dots bounce ───────────────────────────────────
              FadeTransition(
                opacity: _dotsFade,
                child: _BouncingDots(ctrl: _dotsCtrl, color: _mumoRed),
              ),

              if (_startupError != null) ...[
                const SizedBox(height: 24),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: Material(
                          color: Colors.transparent,
                          child: InkResponse(
                            onTap: _retryCheck,
                            radius: 30,
                            splashColor: _mumoRed.withOpacity(0.15),
                            highlightColor: _mumoRed.withOpacity(0.08),
                            child: Center(
                              child: RotationTransition(
                                turns: _refreshRotation,
                                child: Icon(
                                  Icons.refresh,
                                  color: _isRetrying
                                      ? const Color(0xFFBFC5CC)
                                      : _mumoRed,
                                  size: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _startupError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFF7A7F86),
                          fontSize: 11,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Logo fixe de l'écran de démarrage
// ─────────────────────────────────────────────────────────────────
class _StaticLogo extends StatelessWidget {
  const _StaticLogo({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: const Text(
        'M',
        style: TextStyle(
          color: Colors.white,
          fontSize: 52,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
//  Dots bouncing — widget isolé, n'écoute que _dotsCtrl
// ─────────────────────────────────────────────────────────────────
class _BouncingDots extends StatelessWidget {
  const _BouncingDots({required this.ctrl, required this.color});

  final AnimationController ctrl;
  final Color color;

  Animation<double> _bounce(int index) {
    final start = (index * 0.22).clamp(0.0, 1.0);
    final end = (start + 0.45).clamp(0.0, 1.0);
    return Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(
        parent: ctrl,
        curve: Interval(start, end, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      // Le child statique est passé en paramètre → pas rebuild
      builder: (_, __) => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (i) {
          return Padding(
            padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
            child: Transform.translate(
              offset: Offset(0, _bounce(i).value),
              child: Container(
                width: i == 0 ? 10 : 8,
                height: i == 0 ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == 0 ? color : Colors.grey.withAlpha(77),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

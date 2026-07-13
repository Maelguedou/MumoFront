import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../Auth/Controller/login_controller.dart';
import '../../Auth/domain/entities/auth_user.dart';
import '../Controller/service_point_controller.dart';
import '../domain/entities/service_point_daily_recap.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Timer? _dailyRecapTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(servicePointControllerProvider.notifier).fetchDailyRecap();
      _dailyRecapTimer = Timer.periodic(const Duration(seconds: 60), (_) {
        if (!mounted) return;
        ref
            .read(servicePointControllerProvider.notifier)
            .fetchDailyRecap(showLoading: false);
      });
    });
  }

  Future<void> _refreshDashboard() {
    return ref.read(servicePointControllerProvider.notifier).fetchDailyRecap();
  }

  @override
  void dispose() {
    _dailyRecapTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final user = ref.watch(authControllerProvider).user;
    final servicePointState = ref.watch(servicePointControllerProvider);
    final dailyStats = _AdminDailyStats.from(servicePointState.dailyRecap);
    final managerContext = _managerContext(user);
    final agencyName = managerContext?.agencyName?.trim().isNotEmpty == true
        ? managerContext!.agencyName!.trim()
        : 'Agence';
    final adminName = _displayName(user);
    final initials = _initials(adminName);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _DashboardAppBar(
        colors: colors,
        agencyName: agencyName,
        initials: initials,
      ),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _refreshDashboard,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            _TodayOverview(
              stats: dailyStats,
              isLoading: servicePointState.isLoadingDailyRecap,
            ),
            const SizedBox(height: AppSpacing.lg),
            _MetricGrid(
              stats: dailyStats,
              isLoading: servicePointState.isLoadingDailyRecap,
            ),
            const SizedBox(height: AppSpacing.xxl),
            _CabinPerformance(
              items: servicePointState.dailyRecap,
              isLoading: servicePointState.isLoadingDailyRecap,
              errorMessage: servicePointState.dailyRecapErrorMessage,
              onRetry: _refreshDashboard,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _RecentActivity(),
          ],
        ),
      ),
    );
  }

  AuthContext? _managerContext(AuthUser? user) {
    for (final context in user?.contexts ?? const <AuthContext>[]) {
      if (context.isManager) return context;
    }
    return null;
  }

  String _displayName(AuthUser? user) {
    final parts = [
      user?.name?.trim(),
      user?.lastname?.trim(),
    ].where((part) => part != null && part.isNotEmpty).toList();

    if (parts.isNotEmpty) return parts.join(' ');
    return 'Admin';
  }

  String _initials(String name) {
    final parts = name
        .split(RegExp(r'\s+'))
        .where((part) => part.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) return 'AD';
    if (parts.length == 1) {
      final value = parts.first;
      return value.substring(0, value.length >= 2 ? 2 : 1).toUpperCase();
    }

    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }
}

class _AdminDailyStats {
  const _AdminDailyStats({
    required this.depots,
    required this.retraits,
    required this.transferts,
    required this.totalOperations,
    required this.totalAmount,
    required this.totalCommission,
    required this.cabinesCount,
  });

  final int depots;
  final int retraits;
  final int transferts;
  final int totalOperations;
  final double totalAmount;
  final double totalCommission;
  final int cabinesCount;

  factory _AdminDailyStats.from(List<ServicePointDailyRecap> items) {
    var depots = 0;
    var retraits = 0;
    var transferts = 0;
    var totalOperations = 0;
    var totalAmount = 0.0;
    var totalCommission = 0.0;

    for (final item in items) {
      depots += item.depots;
      retraits += item.retraits;
      transferts += item.transferts;
      totalOperations += item.totalOperations;
      totalAmount += item.totalAmount;
      totalCommission += item.totalCommission;
    }

    return _AdminDailyStats(
      depots: depots,
      retraits: retraits,
      transferts: transferts,
      totalOperations: totalOperations,
      totalAmount: totalAmount,
      totalCommission: totalCommission,
      cabinesCount: items.length,
    );
  }
}

class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _DashboardAppBar({
    required this.colors,
    required this.agencyName,
    required this.initials,
  });

  final AppThemeColors colors;
  final String agencyName;
  final String initials;

  @override
  Size get preferredSize => const Size.fromHeight(76);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      titleSpacing: AppSpacing.xl,
      shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Espace Agence',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            agencyName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: Center(
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initials,
                  maxLines: 1,
                  overflow: TextOverflow.clip,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TodayOverview extends StatelessWidget {
  const _TodayOverview({required this.stats, required this.isLoading});

  final _AdminDailyStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final amount = isLoading ? '...' : _formatAmount(stats.totalAmount);
    final operations = isLoading ? '...' : stats.totalOperations.toString();
    final cabines = isLoading ? '...' : stats.cabinesCount.toString();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.isDark ? colors.surfaceElevated : AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: colors.isDark
            ? Border.all(color: AppColors.primarySoftBorderDark)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Vue du jour',
                  style: TextStyle(
                    color: colors.isDark
                        ? colors.textSecondary
                        : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _StatusPill(
                label: '$cabines cabines',
                color: colors.isDark ? colors.primary : Colors.white,
                background: colors.isDark
                    ? colors.primarySoft
                    : Colors.white.withValues(alpha: 0.14),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Center(
            child: Text(
              amount,
              style: TextStyle(
                color: colors.isDark ? colors.textPrimary : Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.sm),
          Center(
            child: Text(
              '$operations opérations enregistrées aujourd’hui',
              style: TextStyle(
                color: colors.isDark ? colors.textSecondary : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.stats, required this.isLoading});

  final _AdminDailyStats stats;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final depots = isLoading ? '...' : stats.depots.toString();
    final retraits = isLoading ? '...' : stats.retraits.toString();
    final transferts = isLoading ? '...' : stats.transferts.toString();
    final commission = isLoading ? '...' : _formatAmount(stats.totalCommission);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 158,
          child: Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Dépôts',
                  value: depots,
                  subtitle: 'Aujourd’hui',
                  icon: Icons.south_west_rounded,
                  color: AppColors.operationDeposit,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Retraits',
                  value: retraits,
                  subtitle: 'Aujourd’hui',
                  icon: Icons.north_east_rounded,
                  color: AppColors.operationWithdrawal,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 136,
          child: Row(
            children: [
              Expanded(
                child: _MetricCard(
                  title: 'Transferts',
                  value: transferts,
                  subtitle: 'Aujourd’hui',
                  icon: Icons.east_rounded,
                  color: AppColors.operationTransfer,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  title: 'Commission',
                  value: commission,
                  subtitle: 'Aujourd’hui',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final softColor = _softColor(context, color);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: softColor,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    title,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: colors.textPrimary,
                    height: 1,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: softColor,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CabinPerformance extends StatelessWidget {
  const _CabinPerformance({
    required this.items,
    required this.isLoading,
    required this.onRetry,
    this.errorMessage,
  });

  final List<ServicePointDailyRecap> items;
  final bool isLoading;
  final VoidCallback onRetry;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final maxOperations = items.fold<int>(
      1,
      (current, item) =>
          item.totalOperations > current ? item.totalOperations : current,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(child: _SectionHeader(title: 'Récap journalier')),
            const SizedBox(width: AppSpacing.md),
            _ReportButton(onTap: () => context.push('/manager-reports')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (isLoading)
          const _PerformanceStatePanel(
            message: 'Chargement du récap journalier...',
            showLoader: true,
          )
        else if (errorMessage != null)
          _PerformanceStatePanel(
            message: errorMessage!,
            icon: Icons.error_outline_rounded,
            color: AppColors.error,
            actionLabel: 'Réessayer',
            onAction: onRetry,
          )
        else if (items.isEmpty)
          const _PerformanceStatePanel(
            message: 'Aucune cabine à afficher pour cette agence.',
            icon: Icons.store_mall_directory_outlined,
          )
        else
          _Panel(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                if (index > 0) const _PanelDivider(),
                _CabinRow(
                  name: items[index].servicePointName,
                  agent: _agentLabel(items[index]),
                  amount: _formatAmount(items[index].totalAmount),
                  commission: _formatAmount(items[index].totalCommission),
                  depots: items[index].depots,
                  retraits: items[index].retraits,
                  transferts: items[index].transferts,
                  totalOperations: items[index].totalOperations,
                  isActive: items[index].isActive,
                  progress: items[index].totalOperations == 0
                      ? 0
                      : items[index].totalOperations / maxOperations,
                  statusColor: _statusColor(items[index]),
                ),
              ],
            ],
          ),
        const SizedBox(height: AppSpacing.sm),
      ],
    );
  }

  String _agentLabel(ServicePointDailyRecap item) {
    final agent = item.agentName?.trim();
    if (agent == null || agent.isEmpty) return 'Aucun agent';
    return agent;
  }

  Color _statusColor(ServicePointDailyRecap item) {
    if (!item.isActive) return AppColors.error;
    if (item.totalOperations == 0) return AppColors.warning;
    return AppColors.success;
  }
}

class _CabinRow extends StatelessWidget {
  const _CabinRow({
    required this.name,
    required this.agent,
    required this.amount,
    required this.commission,
    required this.depots,
    required this.retraits,
    required this.transferts,
    required this.totalOperations,
    required this.isActive,
    required this.progress,
    required this.statusColor,
  });

  final String name;
  final String agent;
  final String amount;
  final String commission;
  final int depots;
  final int retraits;
  final int transferts;
  final int totalOperations;
  final bool isActive;
  final double progress;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _softColor(context, statusColor),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  isActive
                      ? Icons.storefront_rounded
                      : Icons.lock_outline_rounded,
                  color: statusColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Agent: $agent',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _StatusPill(
                label: isActive ? 'Active' : 'Bloquée',
                color: statusColor,
                background: _softColor(context, statusColor),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _CabinSummaryValue(
                  label: 'Montant du jour',
                  value: amount,
                  align: CrossAxisAlignment.start,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _CabinSummaryValue(
                label: 'Commission',
                value: commission,
                align: CrossAxisAlignment.end,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: progress.clamp(0, 1),
              backgroundColor: colors.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _OperationCountChip(
                  label: 'Dépôts',
                  value: depots,
                  color: AppColors.operationDeposit,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OperationCountChip(
                  label: 'Retraits',
                  value: retraits,
                  color: AppColors.operationWithdrawal,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _OperationCountChip(
                  label: 'Transferts',
                  value: transferts,
                  color: AppColors.operationTransfer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CabinSummaryValue extends StatelessWidget {
  const _CabinSummaryValue({
    required this.label,
    required this.value,
    required this.align,
  });

  final String label;
  final String value;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: align == CrossAxisAlignment.end
              ? Alignment.centerRight
              : Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

class _OperationCountChip extends StatelessWidget {
  const _OperationCountChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: _softColor(context, color),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: colors.isDark ? Border.all(color: colors.border) : null,
      ),
      child: Column(
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.toString(),
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PerformanceStatePanel extends StatelessWidget {
  const _PerformanceStatePanel({
    required this.message,
    this.icon = Icons.insights_outlined,
    this.color,
    this.showLoader = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Color? color;
  final bool showLoader;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final accent = color ?? colors.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        children: [
          if (showLoader)
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: colors.primary,
              ),
            )
          else
            Icon(icon, color: accent, size: 28),
          const SizedBox(height: AppSpacing.md),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'À vérifier'),
        const SizedBox(height: AppSpacing.md),
        _Panel(
          children: const [
            _AlertRow(
              icon: Icons.trending_down_rounded,
              title: 'Cabine Calavi sous son rythme habituel',
              subtitle: 'Activité faible depuis 3 heures',
              color: AppColors.warning,
            ),
            _PanelDivider(),
            _AlertRow(
              icon: Icons.lock_outline_rounded,
              title: 'Cabine D inactive',
              subtitle: 'Aucune opération possible tant qu’elle reste bloquée',
              color: AppColors.error,
            ),
          ],
        ),
      ],
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _softColor(context, color),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: AppSpacing.lg,
      endIndent: AppSpacing.lg,
      color: AppThemeColors(context).border,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Text(
      title,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _ReportButton extends StatelessWidget {
  const _ReportButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: colors.primarySoftBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined, size: 17, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Rapport',
                style: TextStyle(
                  color: colors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.color,
    required this.background,
  });

  final String label;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

String _formatAmount(double value) {
  final rounded = value.round().toString();
  final buffer = StringBuffer();
  for (var index = 0; index < rounded.length; index++) {
    final remaining = rounded.length - index;
    buffer.write(rounded[index]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write(' ');
    }
  }
  return '${buffer.toString()} F';
}

Color _softColor(BuildContext context, Color color) {
  final colors = AppThemeColors(context);

  if (color == AppColors.success) return colors.successBg;
  if (color == AppColors.error) return colors.errorBg;
  if (color == AppColors.warning) return colors.warningBg;
  if (color == AppColors.info) return colors.infoBg;
  return colors.primarySoft;
}

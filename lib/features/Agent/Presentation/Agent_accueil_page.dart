import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../Manage_Agency/Controller/service_point_controller.dart';
import '../../Manage_Agency/domain/entities/service_point_operation_stats.dart';
import '../../Operations/Controller/operation_controller.dart';
import '../../Operations/Presentation/operation_form_page.dart';
import '../../Operations/data/models/operation_history_model.dart';

class AgentAccueilPage extends ConsumerStatefulWidget {
  final VoidCallback? onViewHistory;

  const AgentAccueilPage({super.key, this.onViewHistory});

  @override
  ConsumerState<AgentAccueilPage> createState() => _AgentAccueilPageState();
}

class _AgentAccueilPageState extends ConsumerState<AgentAccueilPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshCabinData();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshCabinData();
    }
  }

  Future<void> _refreshCabinData() async {
    final state = ref.read(servicePointControllerProvider);
    final notifier = ref.read(servicePointControllerProvider.notifier);

    if (state.myServicePoint == null && !state.isLoading) {
      await notifier.fetchMyServicePoint();
      await ref.read(operationControllerProvider.notifier).getHistory();
      return;
    }

    final servicePointId = state.myServicePoint?.id;
    if (servicePointId != null && servicePointId.isNotEmpty) {
      await notifier.fetchOperationStats(servicePointId);
    }

    await ref.read(operationControllerProvider.notifier).getHistory();
  }

  void _showOperationForm(BuildContext context, String type) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: OperationFormPage(operationType: type),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final servicePointState = ref.watch(servicePointControllerProvider);
    final servicePoint = servicePointState.myServicePoint;
    final isCabinActive = servicePoint?.status == true;
    final cabinName = servicePoint?.name?.trim().isNotEmpty == true
        ? servicePoint!.name!.trim()
        : servicePointState.isLoading
        ? "Chargement..."
        : "Cabine";
    final stats =
        servicePointState.operationStats ?? const ServicePointOperationStats();
    final operationState = ref.watch(operationControllerProvider);
    final latestTransactions = operationState.history.take(4).toList();
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(
        cabinName: cabinName,
        isActive: servicePoint?.status,
      ),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _refreshCabinData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.xl),
              _buildMainCard(
                cabinName: cabinName,
                stats: stats,
                isLoading: servicePointState.isLoadingOperationStats,
              ),
              const SizedBox(height: 20),
              _buildStatGrid(
                stats: stats,
                isLoading: servicePointState.isLoadingOperationStats,
              ),
              if (servicePoint != null && !isCabinActive) ...[
                const SizedBox(height: AppSpacing.lg),
                _buildInactiveCabinNotice(),
              ],
              if (isCabinActive &&
                  servicePointState.operationStatsErrorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  servicePointState.operationStatsErrorMessage!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: 25),
              _buildSectionTitle("Action rapide"),
              const SizedBox(height: 15),
              _buildQuickActions(context, isEnabled: isCabinActive),
              const SizedBox(height: 25),
              _buildSectionTitle("Dernières transactions"),
              const SizedBox(height: 15),
              _buildTransactionList(
                latestTransactions,
                isLoading: operationState.isLoadingHistory,
                error: operationState.historyError,
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: widget.onViewHistory,
                  child: Text(
                    "Voir tout l'historique",
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // --- COMPOSANTS DE L'INTERFACE ---

  PreferredSizeWidget _buildAppBar({
    required String cabinName,
    required bool? isActive,
  }) {
    final colors = AppThemeColors(context);
    final statusLabel = isActive == null
        ? "Chargement"
        : isActive
        ? "Active"
        : "Inactive";
    final statusColor = isActive == null
        ? AppColors.info
        : isActive
        ? AppColors.success
        : AppColors.warning;
    final statusBg = isActive == null
        ? colors.infoBg
        : isActive
        ? colors.successBg
        : colors.warningBg;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: AppSpacing.xl,
      shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      title: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Espace Cabine",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cabinName,
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
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainCard({
    required String cabinName,
    required ServicePointOperationStats stats,
    required bool isLoading,
  }) {
    final colors = AppThemeColors(context);
    final totalLabel = isLoading ? "..." : stats.total.toString();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
          Text(
            "Récap des opérations - $cabinName",
            style: TextStyle(
              color: colors.isDark ? colors.textSecondary : Colors.white70,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            totalLabel,
            style: TextStyle(
              color: colors.isDark ? colors.primary : Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(width: 5),
                    Text(
                      "${stats.depots} dépôts · ${stats.retraits} retraits · ${stats.transferts} transferts",
                      style: TextStyle(
                        color: colors.isDark
                            ? colors.textPrimary
                            : Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid({
    required ServicePointOperationStats stats,
    required bool isLoading,
  }) {
    final retraits = isLoading ? "..." : stats.retraits.toString();
    final depots = isLoading ? "..." : stats.depots.toString();
    final transferts = isLoading ? "..." : stats.transferts.toString();
    final commission = isLoading
        ? "..."
        : "${NumberFormat.decimalPattern().format(stats.commission)} F";

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildStatItem(
          "Retraits",
          retraits,
          "Aujourd'hui",
          AppColors.operationWithdrawal,
        ),
        _buildStatItem(
          "Dépôts",
          depots,
          "Aujourd'hui",
          AppColors.operationDeposit,
        ),
        _buildStatItem(
          "Transferts",
          transferts,
          "Aujourd'hui",
          AppColors.operationTransfer,
        ),
        _buildStatItem(
          "Commission",
          commission,
          "Aujourd'hui",
          AppColors.primary,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String sub,
    Color subColor,
  ) {
    final colors = AppThemeColors(context);
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              color: subColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = AppThemeColors(context);
    return Text(
      title,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildInactiveCabinNotice() {
    final colors = AppThemeColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.warningBg,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: AppColors.warning,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Cabine temporairement bloquée",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Les opérations sont désactivées. Contactez votre responsable pour la réactivation.",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, {required bool isEnabled}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildActionButton(
          context,
          "Retrait",
          Icons.arrow_upward,
          isEnabled: isEnabled,
        ),
        _buildActionButton(
          context,
          "Dépôt",
          Icons.arrow_downward,
          isEnabled: isEnabled,
        ),
        _buildActionButton(
          context,
          "Transfert",
          Icons.arrow_forward,
          isEnabled: isEnabled,
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon, {
    required bool isEnabled,
  }) {
    final colors = AppThemeColors(context);
    final operationColor = _quickActionColor(label);
    final iconBackground = isEnabled ? operationColor : colors.surfaceAlt;
    final iconColor = isEnabled ? Colors.white : colors.textTertiary;
    final textColor = isEnabled ? colors.textPrimary : colors.textTertiary;
    return InkWell(
      onTap: isEnabled
          ? () => _showOperationForm(context, label)
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "Cette cabine est inactive. Les opérations sont bloquées.",
                  ),
                  backgroundColor: AppColors.warning,
                ),
              );
            },
      borderRadius: BorderRadius.circular(AppRadii.lg),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconBackground,
                borderRadius: BorderRadius.circular(AppRadii.md),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _quickActionColor(String label) {
    return switch (label.toLowerCase()) {
      'dépôt' || 'depot' => AppColors.operationDeposit,
      'retrait' => AppColors.operationWithdrawal,
      'transfert' => AppColors.operationTransfer,
      _ => AppColors.primary,
    };
  }

  Widget _buildTransactionList(
    List<OperationHistoryItem> transactions, {
    required bool isLoading,
    String? error,
  }) {
    if (isLoading && transactions.isEmpty) {
      return _buildTransactionShell(
        const Padding(
          padding: EdgeInsets.all(AppSpacing.xxl),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (error != null && transactions.isEmpty) {
      return _buildTransactionShell(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: _refreshCabinData,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: TextButton.styleFrom(
                  foregroundColor: AppThemeColors(context).primary,
                  textStyle: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (transactions.isEmpty) {
      return _buildTransactionShell(
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            "Aucune opération récente.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppThemeColors(context).textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return _buildTransactionShell(
      Column(
        children: [
          for (var index = 0; index < transactions.length; index++) ...[
            _buildTransactionItemFromOperation(transactions[index]),
            if (index != transactions.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionShell(Widget child) {
    final colors = AppThemeColors(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: child,
    );
  }

  Widget _buildTransactionItemFromOperation(OperationHistoryItem operation) {
    final visual = _visualFor(operation);
    return _buildTransactionItem(
      _titleFor(operation),
      _subtitleFor(operation),
      _formatAmount(operation.amount),
      _statusLabel(operation.status),
      visual.statusColor,
      visual.icon,
      visual.iconBg,
      visual.iconColor,
    );
  }

  Widget _buildTransactionItem(
    String title,
    String subtitle,
    String amount,
    String status,
    Color statusColor,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) {
    final colors = AppThemeColors(context);
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _titleFor(OperationHistoryItem operation) {
    final type = switch (operation.type) {
      'depot' => 'Dépôt',
      'retrait' => 'Retrait',
      'transfert' => 'Transfert',
      _ => 'Opération',
    };
    final operator = operation.operatorName ?? '';
    final label = operation.ussdLabel;
    if (operation.type == 'transfert' && label != null && label.isNotEmpty) {
      return '$type $operator - $label';
    }
    return '$type $operator'.trim();
  }

  String _subtitleFor(OperationHistoryItem operation) {
    final message = operation.message?.trim();
    if (message != null && message.isNotEmpty) return message;
    return operation.localTime ?? 'Heure inconnue';
  }

  String _formatAmount(double value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i;
      buffer.write(raw[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write(' ');
      }
    }
    return '${buffer.toString()} F';
  }

  String _statusLabel(String status) {
    return switch (status) {
      'PAID' => 'Réussie',
      'PENDING' => 'En attente',
      'FAILED' => 'Échouée',
      _ => status,
    };
  }

  _OperationVisual _visualFor(OperationHistoryItem operation) {
    final icon = switch (operation.type) {
      'depot' => Icons.arrow_downward,
      'retrait' => Icons.arrow_upward,
      'transfert' => Icons.arrow_forward,
      _ => Icons.receipt_long_outlined,
    };

    final statusColor = switch (operation.status) {
      'PAID' => AppColors.success,
      'PENDING' => AppColors.pending,
      'FAILED' => AppColors.error,
      _ => AppThemeColors(context).textSecondary,
    };

    final operationColors = _operationColors(operation.type);
    return _OperationVisual(
      icon: icon,
      statusColor: statusColor,
      iconBg: operationColors.background,
      iconColor: operationColors.foreground,
    );
  }

  _OperationTypeColors _operationColors(String type) {
    final colors = AppThemeColors(context);
    final foreground = switch (type) {
      'depot' => AppColors.operationDeposit,
      'retrait' => AppColors.operationWithdrawal,
      'transfert' => AppColors.operationTransfer,
      _ => colors.textPrimary,
    };
    final background = switch (type) {
      'depot' => colors.infoBg,
      'retrait' => colors.warningBg,
      'transfert' => colors.successBg,
      _ => colors.surfaceAlt,
    };

    return _OperationTypeColors(background: background, foreground: foreground);
  }
}

class _OperationVisual {
  final IconData icon;
  final Color statusColor;
  final Color iconBg;
  final Color iconColor;

  const _OperationVisual({
    required this.icon,
    required this.statusColor,
    required this.iconBg,
    required this.iconColor,
  });
}

class _OperationTypeColors {
  final Color background;
  final Color foreground;

  const _OperationTypeColors({
    required this.background,
    required this.foreground,
  });
}

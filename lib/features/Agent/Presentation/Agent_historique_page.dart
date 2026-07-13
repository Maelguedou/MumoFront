import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../Operations/Controller/operation_controller.dart';
import '../../Operations/data/models/operation_history_model.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String selectedFilter = "Tout";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() {
    return ref.read(operationControllerProvider.notifier).getHistory();
  }

  String? _typeForFilter(String filter) {
    return switch (filter) {
      'Retrait' => 'retrait',
      'Dépôt' => 'depot',
      'Transfert' => 'transfert',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(operationControllerProvider);
    final visibleHistory = _filterHistory(operationState.history);
    final grouped = _groupByDate(visibleHistory);
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(operationState.isLoadingHistory),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.lg),
          _buildFilterBar(),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: RefreshIndicator(
              color: colors.primary,
              onRefresh: _fetchHistory,
              child: _buildBody(operationState, grouped),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    OperationState state,
    Map<String, List<OperationHistoryItem>> grouped,
  ) {
    if (state.isLoadingHistory && state.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.historyError != null && state.history.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          _emptyState(
            icon: Icons.error_outline,
            title: "Impossible de charger l'historique",
            subtitle: state.historyError!,
          ),
        ],
      );
    }

    if (grouped.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        children: [
          _emptyState(
            icon: Icons.receipt_long_outlined,
            title: "Aucune opération",
            subtitle: selectedFilter == 'Tout'
                ? "Les opérations de cette cabine apparaîtront ici."
                : "Aucune opération ne correspond à ce filtre.",
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      children: [
        for (final entry in grouped.entries) ...[
          _buildSectionTitle(_sectionTitle(entry.key)),
          const SizedBox(height: 10),
          _buildTransactionGroup(entry.value.map(_itemFromOperation).toList()),
          const SizedBox(height: 25),
        ],
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(bool isLoading) {
    final colors = AppThemeColors(context);
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      elevation: 0,
      toolbarHeight: 76,
      titleSpacing: AppSpacing.xl,
      shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      title: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Historique",
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 2),
          Text(
            "Opérations de la cabine",
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : _buildHeaderButton(Icons.refresh, null, onTap: _fetchHistory),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(
    IconData icon,
    String? label, {
    VoidCallback? onTap,
  }) {
    final colors = AppThemeColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: label != null ? 12 : 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            if (label != null) ...[
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 5),
            ],
            Icon(icon, size: 18, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    final colors = AppThemeColors(context);
    final filters = ["Tout", "Retrait", "Dépôt", "Transfert"];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Container(
        height: 44,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.lg),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            for (final filter in filters)
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => selectedFilter = filter),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selectedFilter == filter
                          ? colors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    child: Text(
                      filter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedFilter == filter
                            ? Colors.white
                            : colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colors = AppThemeColors(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.xs),
      child: Text(
        title,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTransactionGroup(List<Widget> children) {
    final colors = AppThemeColors(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(children: children),
    );
  }

  Widget _itemFromOperation(OperationHistoryItem operation) {
    final visual = _visualFor(operation);
    return _item(
      _titleFor(operation),
      _subtitleFor(operation),
      _formatAmount(operation.amount),
      _statusLabel(operation.status),
      operation.localTime ?? '--:--',
      visual.statusColor,
      visual.icon,
      visual.iconBg,
      visual.iconColor,
    );
  }

  Widget _item(
    String title,
    String subtitle,
    String amount,
    String status,
    String time,
    Color statusColor,
    IconData icon,
    Color iconBg,
    Color iconColor,
  ) {
    final colors = AppThemeColors(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(icon, size: 20, color: iconColor),
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
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 12,
                      height: 1.35,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _statusBackground(status),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                time,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = AppThemeColors(context);
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: colors.textTertiary, size: 32),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: colors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Map<String, List<OperationHistoryItem>> _groupByDate(
    List<OperationHistoryItem> items,
  ) {
    final grouped = <String, List<OperationHistoryItem>>{};
    for (final item in items) {
      final key = item.localDate ?? 'unknown';
      grouped.putIfAbsent(key, () => []).add(item);
    }
    return grouped;
  }

  List<OperationHistoryItem> _filterHistory(List<OperationHistoryItem> items) {
    final type = _typeForFilter(selectedFilter);
    if (type == null) return items;
    return items.where((item) => item.type == type).toList();
  }

  String _sectionTitle(String date) {
    final now = DateTime.now();
    final today =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final yesterday =
        '${yesterdayDate.year.toString().padLeft(4, '0')}-${yesterdayDate.month.toString().padLeft(2, '0')}-${yesterdayDate.day.toString().padLeft(2, '0')}';

    if (date == today) return "Aujourd'hui";
    if (date == yesterday) return "Hier";
    if (date == 'unknown') return "Date inconnue";
    return date;
  }

  String _titleFor(OperationHistoryItem operation) {
    final type = switch (operation.type) {
      'depot' => 'Dépôt',
      'retrait' => 'Retrait',
      'transfert' => 'Transfert',
      _ => 'Opération',
    };
    final operator = operation.operatorName ?? '';
    final service = operation.ussdLabel;
    if (operation.type == 'transfert' &&
        service != null &&
        service.isNotEmpty) {
      return '$type $operator - $service';
    }
    return '$type $operator'.trim();
  }

  String _subtitleFor(OperationHistoryItem operation) {
    final message = operation.message?.trim();
    if (message != null && message.isNotEmpty) {
      return message;
    }
    final reference = operation.reference ?? operation.generatedReference;
    if (reference != null && reference.isNotEmpty) {
      return 'Référence: $reference';
    }
    return 'Aucun message associé à cette opération.';
  }

  String _formatAmount(double value) {
    final intValue = value.round();
    final raw = intValue.toString();
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

  Color _statusBackground(String statusLabel) {
    final colors = AppThemeColors(context);
    return switch (statusLabel) {
      'Réussie' => colors.successBg,
      'En attente' => colors.pendingBg,
      'Échouée' => colors.errorBg,
      _ => colors.surfaceAlt,
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/agency_stats_controller.dart';
import '../data/agency_stats_state_model.dart';
import '../domain/entities/agency_stats.dart';

class StatsPage extends ConsumerStatefulWidget {
  const StatsPage({super.key});

  @override
  ConsumerState<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends ConsumerState<StatsPage> {
  final _amountFormat = NumberFormat.decimalPattern();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(agencyStatsControllerProvider.notifier).load();
    });
  }

  Future<void> _refresh() {
    return ref.read(agencyStatsControllerProvider.notifier).load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final state = ref.watch(agencyStatsControllerProvider);
    final dashboard = state.dashboard;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 72,
        centerTitle: true,
        titleSpacing: 20,
        title: Text(
          'Statistiques',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(8),
          child: SizedBox(height: 8),
        ),
        shape: Border(bottom: BorderSide(color: colors.border, width: 1)),
      ),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            _PeriodSelector(
              state: state,
              onPresetSelected: (preset) => ref
                  .read(agencyStatsControllerProvider.notifier)
                  .setPreset(preset),
              onCustomRange: _pickCustomRange,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state.errorMessage != null) ...[
              _StatePanel(
                message: state.errorMessage!,
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                actionLabel: 'Réessayer',
                onAction: _refresh,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (state.isLoading && dashboard.overview == null)
              const _StatePanel(
                message: 'Chargement des statistiques...',
                showLoader: true,
              )
            else ...[
              _OverviewSection(
                overview: dashboard.overview,
                amountFormat: _amountFormat,
              ),
              const SizedBox(height: AppSpacing.xl),
              _EvolutionSection(items: dashboard.evolution),
              const SizedBox(height: AppSpacing.xl),
              _BreakdownSection(
                title: 'Répartition par type',
                items: dashboard.byType,
                colorFor: _typeColor,
              ),
              const SizedBox(height: AppSpacing.xl),
              _BreakdownSection(
                title: 'Répartition par opérateur',
                items: dashboard.byOperator,
                colorFor: _operatorColor,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ServicePointSection(
                items: dashboard.servicePoints,
                amountFormat: _amountFormat,
              ),
              const SizedBox(height: AppSpacing.xl),
              _ActivityHoursSection(items: dashboard.activityHours),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickCustomRange() async {
    final state = ref.read(agencyStatsControllerProvider);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: state.startDate,
        end: state.endDate,
      ),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        final colors = AppThemeColors(context);
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.primary,
              surface: colors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;
    await ref
        .read(agencyStatsControllerProvider.notifier)
        .setCustomRange(picked.start, picked.end);
  }

  Color _typeColor(AgencyStatsBreakdownItem item) {
    switch (item.type) {
      case 'depot':
        return AppColors.operationDeposit;
      case 'retrait':
        return AppColors.operationWithdrawal;
      case 'transfert':
        return AppColors.operationTransfer;
      default:
        return AppColors.primary;
    }
  }

  Color _operatorColor(AgencyStatsBreakdownItem item) {
    final name = (item.operatorName ?? item.label).toLowerCase();
    if (name.contains('mtn')) return const Color(0xFFEAB308);
    if (name.contains('moov')) return AppColors.pending;
    if (name.contains('celtiis')) return const Color(0xFF65A30D);
    return AppColors.primary;
  }
}

String _compactAmount(double value) {
  final amount = value.abs();
  if (amount >= 1000000) {
    return '${(value / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 1000) {
    return '${(value / 1000).toStringAsFixed(1)}k';
  }
  return value.toStringAsFixed(0);
}

class _PeriodSelector extends StatelessWidget {
  const _PeriodSelector({
    required this.state,
    required this.onPresetSelected,
    required this.onCustomRange,
  });

  final AgencyStatsStateModel state;
  final ValueChanged<AgencyStatsPeriodPreset> onPresetSelected;
  final VoidCallback onCustomRange;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM');
    final label =
        '${dateFormat.format(state.startDate)} - ${dateFormat.format(state.endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title: 'Période', subtitle: label),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _PresetChip(
                label: 'Jour',
                isSelected: state.preset == AgencyStatsPeriodPreset.today,
                onTap: () => onPresetSelected(AgencyStatsPeriodPreset.today),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PresetChip(
                label: '7 jours',
                isSelected: state.preset == AgencyStatsPeriodPreset.sevenDays,
                onTap: () =>
                    onPresetSelected(AgencyStatsPeriodPreset.sevenDays),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _PresetChip(
                label: '30 jours',
                isSelected: state.preset == AgencyStatsPeriodPreset.thirtyDays,
                onTap: () =>
                    onPresetSelected(AgencyStatsPeriodPreset.thirtyDays),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _IconChip(
              isSelected: state.preset == AgencyStatsPeriodPreset.custom,
              onTap: onCustomRange,
            ),
          ],
        ),
      ],
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({required this.isSelected, required this.onTap});

  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: Container(
        width: 42,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.pill),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
          ),
        ),
        child: Icon(
          Icons.date_range_rounded,
          size: 18,
          color: isSelected ? Colors.white : colors.textSecondary,
        ),
      ),
    );
  }
}

class _OverviewSection extends StatelessWidget {
  const _OverviewSection({required this.overview, required this.amountFormat});

  final AgencyStatsOverview? overview;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final data = overview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Vue d’ensemble',
          subtitle: 'Lecture rapide de la performance de l’agence',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Opérations',
                value: (data?.operations ?? 0).toString(),
                trend: data?.operationsChangePercent,
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Montant',
                value: '${amountFormat.format(data?.amount ?? 0)} F',
                trend: data?.amountChangePercent,
                icon: Icons.payments_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Commission',
                value: '${amountFormat.format(data?.commission ?? 0)} F',
                trend: data?.commissionChangePercent,
                icon: Icons.account_balance_wallet_outlined,
                color: AppColors.info,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _KpiCard(
                label: 'Réussite',
                value: '${(data?.successRate ?? 0).toStringAsFixed(1)}%',
                progress: (data?.successRate ?? 0) / 100,
                icon: Icons.verified_outlined,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.progress,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? trend;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final trendValue = trend;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 21,
              height: 1.05,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (trendValue != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _TrendLabel(value: trendValue),
          ],
          if (progress != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ProgressBar(value: progress!.clamp(0, 1), color: color),
          ],
        ],
      ),
    );
  }
}

class _TrendLabel extends StatelessWidget {
  const _TrendLabel({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final isUp = value >= 0;
    final color = isUp ? AppColors.success : AppColors.error;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${value.abs().toStringAsFixed(1)}% vs période précédente',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                height: 1.2,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EvolutionSection extends StatelessWidget {
  const _EvolutionSection({required this.items});

  final List<AgencyStatsEvolutionItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      1,
      (current, item) => item.operations > current ? item.operations : current,
    );

    return _SectionCard(
      title: 'Évolution',
      subtitle: 'Nombre d’opérations confirmées par jour',
      child: items.isEmpty
          ? const _EmptyText('Aucune donnée sur cette période.')
          : SizedBox(
              height: 170,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final item in items.take(14))
                    Expanded(
                      child: _DailyBar(item: item, maxValue: maxValue),
                    ),
                ],
              ),
            ),
    );
  }
}

class _DailyBar extends StatelessWidget {
  const _DailyBar({required this.item, required this.maxValue});

  final AgencyStatsEvolutionItem item;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final heightFactor = maxValue == 0 ? 0.0 : item.operations / maxValue;
    final label = item.date.length >= 10
        ? item.date.substring(8, 10)
        : item.date;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            item.operations.toString(),
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: FractionallySizedBox(
              heightFactor: heightFactor.clamp(0.06, 1.0),
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.title,
    required this.items,
    required this.colorFor,
  });

  final String title;
  final List<AgencyStatsBreakdownItem> items;
  final Color Function(AgencyStatsBreakdownItem item) colorFor;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: title,
      subtitle: 'Répartition des opérations confirmées',
      child: items.isEmpty
          ? const _EmptyText('Aucune donnée à afficher.')
          : Column(
              children: [
                for (final item in items)
                  _HorizontalStatBar(
                    label: item.label,
                    value:
                        '${item.percent.toStringAsFixed(1)}% · ${_compactAmount(item.commission)} F',
                    percent: item.percent / 100,
                    color: colorFor(item),
                  ),
              ],
            ),
    );
  }
}

class _HorizontalStatBar extends StatelessWidget {
  const _HorizontalStatBar({
    required this.label,
    required this.value,
    required this.percent,
    required this.color,
  });

  final String label;
  final String value;
  final double percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressBar(value: percent.clamp(0, 1), color: color),
        ],
      ),
    );
  }
}

class _ServicePointSection extends StatelessWidget {
  const _ServicePointSection({required this.items, required this.amountFormat});

  final List<AgencyStatsServicePointItem> items;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Performance cabines',
      subtitle: 'Classement sur la période sélectionnée',
      child: items.isEmpty
          ? const _EmptyText('Aucune cabine à afficher.')
          : Column(
              children: [
                for (final item in items)
                  _ServicePointRow(item: item, amountFormat: amountFormat),
              ],
            ),
    );
  }
}

class _ServicePointRow extends StatelessWidget {
  const _ServicePointRow({required this.item, required this.amountFormat});

  final AgencyStatsServicePointItem item;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ServicePointStatusPill(isActive: item.isActive),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: colors.textTertiary,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.agent ?? 'Aucun agent affecté',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _ServicePointMetric(
                  label: 'Opérations',
                  value: item.operations.toString(),
                  icon: Icons.receipt_long_outlined,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _ServicePointMetric(
                  label: 'Montant',
                  value: '${amountFormat.format(item.amount)} F',
                  icon: Icons.payments_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _ServicePointMetric(
            label: 'Commission',
            value: '${amountFormat.format(item.commission)} F',
            icon: Icons.account_balance_wallet_outlined,
            color: AppColors.info,
            isWide: true,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ProgressBar(
            value: (item.successRate / 100).clamp(0, 1),
            color: item.successRate >= 90
                ? AppColors.success
                : AppColors.warning,
          ),
        ],
      ),
    );
  }
}

class _ServicePointStatusPill extends StatelessWidget {
  const _ServicePointStatusPill({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.success : AppColors.error;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ServicePointMetric extends StatelessWidget {
  const _ServicePointMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.isWide = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: isWide ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: isWide ? 15 : 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
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

class _ActivityHoursSection extends StatelessWidget {
  const _ActivityHoursSection({required this.items});

  final List<AgencyStatsActivityHourItem> items;

  @override
  Widget build(BuildContext context) {
    final maxValue = items.fold<int>(
      1,
      (current, item) => item.operations > current ? item.operations : current,
    );
    final peak = items.isEmpty
        ? null
        : items.reduce((a, b) => a.operations >= b.operations ? a : b);

    return _SectionCard(
      title: 'Heures d’activité',
      subtitle: peak == null || peak.operations == 0
          ? 'Aucun pic détecté'
          : 'Pic d’activité : ${peak.slot}',
      child: items.isEmpty
          ? const _EmptyText('Aucune donnée horaire.')
          : Column(
              children: [
                for (final item in items)
                  _HorizontalStatBar(
                    label: item.slot,
                    value:
                        '${item.operations} · ${_compactAmount(item.commission)} F',
                    percent: item.operations / maxValue,
                    color: AppColors.info,
                  ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: title, subtitle: subtitle),
          const SizedBox(height: AppSpacing.lg),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, required this.color});

  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pill),
      child: LinearProgressIndicator(
        minHeight: 7,
        value: value,
        backgroundColor: colors.surfaceAlt,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _StatePanel extends StatelessWidget {
  const _StatePanel({
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.color = AppColors.info,
    this.showLoader = false,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final IconData icon;
  final Color color;
  final bool showLoader;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (showLoader)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              else
                Icon(icon, color: color, size: 22),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.md),
            TextButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(actionLabel!),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                padding: EdgeInsets.zero,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyText extends StatelessWidget {
  const _EmptyText(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Text(
      message,
      style: TextStyle(
        color: colors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

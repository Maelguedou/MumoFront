import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../di/agency_insight_provider.dart';
import '../domain/entities/agency_insight.dart';
import '../domain/entities/agency_insight_item.dart';

class InsightsPage extends ConsumerStatefulWidget {
  const InsightsPage({super.key});

  @override
  ConsumerState<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends ConsumerState<InsightsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(agencyInsightControllerProvider);
      if (state.history.isEmpty && !state.isLoading && !state.isGenerating) {
        ref.read(agencyInsightControllerProvider.notifier).loadCurrentPeriod();
      }
    });
  }

  Future<void> _refresh() {
    return ref
        .read(agencyInsightControllerProvider.notifier)
        .loadCurrentPeriod();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final state = ref.watch(agencyInsightControllerProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final selected = state.selectedInsight;
    final period = selected == null
        ? 'Période sélectionnée automatiquement'
        : '${dateFormat.format(selected.startDate)} - ${dateFormat.format(selected.endDate)}';

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        foregroundColor: colors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Insights',
          style: TextStyle(fontWeight: FontWeight.w900),
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
            _IntroCard(period: period),
            const SizedBox(height: AppSpacing.xl),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'daily',
                  label: Text('Quotidien'),
                  icon: Icon(Icons.today_outlined),
                ),
                ButtonSegment<String>(
                  value: 'monthly',
                  label: Text('Mensuel'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
              ],
              selected: {state.selectedGranularity},
              onSelectionChanged: state.isLoading || state.isGenerating
                  ? null
                  : (selection) => ref
                        .read(agencyInsightControllerProvider.notifier)
                        .loadCurrentPeriod(granularity: selection.first),
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
            if ((state.isLoading || state.isGenerating) && selected == null)
              const _StatePanel(
                message: 'Analyse des données de l’agence...',
                showLoader: true,
              )
            else if (state.selectedInsight == null)
              const _StatePanel(
                message: 'Aucune analyse disponible pour cette période.',
                icon: Icons.verified_outlined,
                color: AppColors.success,
              )
            else
              Column(
                children: [
                  for (final insight in state.history)
                    _InsightReportCard(
                      insight: insight,
                      onTap: () => ref
                          .read(agencyInsightControllerProvider.notifier)
                          .selectInsight(insight),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _IntroCard extends StatelessWidget {
  const _IntroCard({required this.period});

  final String period;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.primarySoftBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: Icon(
              Icons.auto_awesome_outlined,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lecture intelligente',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Points à surveiller pour la période $period.',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    height: 1.35,
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

class _InsightReportCard extends StatelessWidget {
  const _InsightReportCard({required this.insight, required this.onTap});

  final AgencyInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final dateFormat = DateFormat('dd/MM/yyyy');
    final period =
        '${dateFormat.format(insight.startDate)} - ${dateFormat.format(insight.endDate)}';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Expanded(
                child: Text(
                  insight.granularity == 'daily'
                      ? 'Analyse quotidienne'
                      : 'Analyse mensuelle',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TextButton(onPressed: onTap, child: const Text('Consulter')),
            ],
          ),
          Text(
            period,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final item in insight.insights) _InsightCard(item: item),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.item});

  final AgencyInsightItem item;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final color = switch (item.level) {
      'warning' => AppColors.warning,
      'danger' => AppColors.error,
      'success' => AppColors.success,
      _ => AppColors.info,
    };
    final icon = switch (item.level) {
      'warning' => Icons.warning_amber_rounded,
      'danger' => Icons.error_outline_rounded,
      'success' => Icons.check_circle_outline_rounded,
      _ => Icons.insights_outlined,
    };
    final levelLabel = switch (item.level) {
      'warning' => 'À surveiller',
      'danger' => 'Prioritaire',
      'success' => 'Bon signal',
      _ => 'Information',
    };

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
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
                      levelLabel,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 15,
                        height: 1.2,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            item.message,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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

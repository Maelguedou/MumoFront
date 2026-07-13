import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/agency_report_controller.dart';
import '../domain/entities/agency_report_summary.dart';

class ManagerReportPage extends ConsumerStatefulWidget {
  const ManagerReportPage({super.key});

  @override
  ConsumerState<ManagerReportPage> createState() => _ManagerReportPageState();
}

class _ManagerReportPageState extends ConsumerState<ManagerReportPage> {
  late DateTime _startDate;
  late DateTime _endDate;
  String? _status;
  String? _type;

  final _amountFormat = NumberFormat.decimalPattern();
  final _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _endDate = DateTime(now.year, now.month, now.day);
    _startDate = _endDate.subtract(const Duration(days: 7));
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPreview());
  }

  Future<void> _loadPreview() {
    return ref
        .read(agencyReportControllerProvider.notifier)
        .loadPreview(
          startDate: _startDate,
          endDate: _endDate,
          status: _status,
          type: _type,
        );
  }

  Future<void> _downloadCsv() {
    return ref
        .read(agencyReportControllerProvider.notifier)
        .downloadCsv(
          startDate: _startDate,
          endDate: _endDate,
          status: _status,
          type: _type,
        );
  }

  Future<void> _downloadPdf() {
    return ref
        .read(agencyReportControllerProvider.notifier)
        .downloadPdf(
          startDate: _startDate,
          endDate: _endDate,
          status: _status,
          type: _type,
        );
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
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
    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_startDate.isAfter(_endDate)) _endDate = _startDate;
      } else {
        _endDate = picked;
        if (_endDate.isBefore(_startDate)) _startDate = _endDate;
      }
    });
    await _loadPreview();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final state = ref.watch(agencyReportControllerProvider);

    ref.listen(agencyReportControllerProvider, (previous, next) {
      final message = next.downloadMessage;
      if (message != null && message != previous?.downloadMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rapports',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              'Aperçu et export des opérations',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _loadPreview,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxxl,
          ),
          children: [
            _ReportToolbar(
              startLabel: _dateFormat.format(_startDate),
              endLabel: _dateFormat.format(_endDate),
              status: _status,
              type: _type,
              isLoading: state.isLoading,
              isDownloading: state.isDownloading,
              onPickStart: () => _pickDate(isStart: true),
              onPickEnd: () => _pickDate(isStart: false),
              onStatusChanged: (value) {
                setState(() => _status = value);
                _loadPreview();
              },
              onTypeChanged: (value) {
                setState(() => _type = value);
                _loadPreview();
              },
              onRefresh: _loadPreview,
              onDownloadCsv: _downloadCsv,
              onDownloadPdf: _downloadPdf,
            ),
            const SizedBox(height: AppSpacing.xl),
            if (state.errorMessage != null) ...[
              _StatePanel(
                message: state.errorMessage!,
                icon: Icons.error_outline_rounded,
                color: AppColors.error,
                actionLabel: 'Réessayer',
                onAction: _loadPreview,
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
            if (state.isLoading && state.summary == null)
              const _StatePanel(
                message: 'Chargement de l’aperçu du rapport...',
                showLoader: true,
              )
            else ...[
              _PdfPreviewSection(
                isLoading: state.isPdfPreviewLoading,
                pdfBytes: state.pdfPreviewBytes,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SummarySection(
                summary: state.summary,
                amountFormat: _amountFormat,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ReportToolbar extends StatelessWidget {
  const _ReportToolbar({
    required this.startLabel,
    required this.endLabel,
    required this.status,
    required this.type,
    required this.isLoading,
    required this.isDownloading,
    required this.onPickStart,
    required this.onPickEnd,
    required this.onStatusChanged,
    required this.onTypeChanged,
    required this.onRefresh,
    required this.onDownloadCsv,
    required this.onDownloadPdf,
  });

  final String startLabel;
  final String endLabel;
  final String? status;
  final String? type;
  final bool isLoading;
  final bool isDownloading;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onDownloadCsv;
  final Future<void> Function() onDownloadPdf;

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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Période du rapport',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: isLoading ? null : () => onRefresh(),
                tooltip: 'Actualiser l’aperçu',
                icon: isLoading
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.primary,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _PickerTile(
                  label: 'Début',
                  value: startLabel,
                  icon: Icons.calendar_month_outlined,
                  onTap: onPickStart,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PickerTile(
                  label: 'Fin',
                  value: endLabel,
                  icon: Icons.event_available_outlined,
                  onTap: onPickEnd,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _FilterDropdown(
                  label: 'Statut',
                  value: status,
                  hint: 'Tous',
                  items: const [
                    DropdownMenuItem(value: 'PAID', child: Text('Confirmé')),
                    DropdownMenuItem(
                      value: 'PENDING',
                      child: Text('En attente'),
                    ),
                    DropdownMenuItem(value: 'FAILED', child: Text('Échoué')),
                  ],
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _FilterDropdown(
                  label: 'Type',
                  value: type,
                  hint: 'Tous',
                  items: const [
                    DropdownMenuItem(value: 'depot', child: Text('Dépôt')),
                    DropdownMenuItem(value: 'retrait', child: Text('Retrait')),
                    DropdownMenuItem(
                      value: 'transfert',
                      child: Text('Transfert'),
                    ),
                  ],
                  onChanged: onTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _ReportDownloadButton(
                  label: 'Télécharger CSV',
                  icon: Icons.table_chart_outlined,
                  onPressed: isDownloading ? null : () => onDownloadCsv(),
                  backgroundColor: colors.surfaceAlt,
                  foregroundColor: colors.textPrimary,
                  borderColor: colors.border,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ReportDownloadButton(
                  label: 'Télécharger PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  onPressed: isDownloading ? null : () => onDownloadPdf(),
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportDownloadButton extends StatelessWidget {
  const _ReportDownloadButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            maxLines: 1,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          disabledBackgroundColor: backgroundColor.withValues(alpha: 0.45),
          disabledForegroundColor: foregroundColor.withValues(alpha: 0.55),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.md),
            side: BorderSide(color: borderColor ?? Colors.transparent),
          ),
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadii.md),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: colors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final String hint;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: colors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
          borderSide: BorderSide(color: colors.border),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      hint: Text(hint),
      items: [
        DropdownMenuItem<String>(value: null, child: Text(hint)),
        ...items,
      ],
      onChanged: onChanged,
    );
  }
}

class _PdfPreviewSection extends StatelessWidget {
  const _PdfPreviewSection({required this.isLoading, required this.pdfBytes});

  final bool isLoading;
  final Uint8List? pdfBytes;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);
    final bytes = pdfBytes;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Expanded(
              child: _SectionTitle(
                title: 'Aperçu PDF',
                subtitle:
                    'Rendu réel du document généré avec les filtres actuels',
              ),
            ),
            if (bytes != null && bytes.isNotEmpty)
              IconButton.filledTonal(
                onPressed: () => _openFullScreenPreview(context, bytes),
                tooltip: 'Agrandir l’aperçu',
                icon: const Icon(Icons.open_in_full_rounded, size: 18),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          height: 520,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: isLoading
              ? const _StatePanel(
                  message: 'Préparation du rendu PDF...',
                  showLoader: true,
                )
              : bytes == null || bytes.isEmpty
              ? const _StatePanel(
                  message: 'Aucun aperçu PDF disponible pour ces filtres.',
                  icon: Icons.picture_as_pdf_outlined,
                )
              : PdfPreview(
                  key: ValueKey(bytes.length),
                  build: (_) async => bytes,
                  allowPrinting: false,
                  allowSharing: false,
                  canChangeOrientation: false,
                  canChangePageFormat: false,
                  canDebug: false,
                  maxPageWidth: 700,
                  pdfFileName: 'mumo-rapport.pdf',
                ),
        ),
      ],
    );
  }

  void _openFullScreenPreview(BuildContext context, Uint8List bytes) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => _FullScreenPdfPreview(pdfBytes: bytes)),
    );
  }
}

class _FullScreenPdfPreview extends StatelessWidget {
  const _FullScreenPdfPreview({required this.pdfBytes});

  final Uint8List pdfBytes;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: colors.textPrimary),
        title: Text(
          'Aperçu PDF',
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: PdfPreview(
        key: ValueKey(pdfBytes.length),
        build: (_) async => pdfBytes,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        maxPageWidth: 900,
        pdfFileName: 'mumo-rapport.pdf',
      ),
    );
  }
}

class _SummarySection extends StatelessWidget {
  const _SummarySection({required this.summary, required this.amountFormat});

  final AgencyReportSummary? summary;
  final NumberFormat amountFormat;

  @override
  Widget build(BuildContext context) {
    final totals = summary?.totals;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle(
          title: 'Aperçu global',
          subtitle: 'Synthèse de la période sélectionnée',
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Opérations',
                value: (totals?.operations ?? 0).toString(),
                icon: Icons.receipt_long_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _MetricCard(
                label: 'Montant',
                value: '${amountFormat.format(totals?.amount ?? 0)} FCFA',
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
              child: _SmallMetricCard(
                label: 'Dépôts',
                value: (totals?.depots ?? 0).toString(),
                color: AppColors.operationDeposit,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SmallMetricCard(
                label: 'Retraits',
                value: (totals?.retraits ?? 0).toString(),
                color: AppColors.operationWithdrawal,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _SmallMetricCard(
                label: 'Transferts',
                value: (totals?.transferts ?? 0).toString(),
                color: AppColors.operationTransfer,
              ),
            ),
          ],
        ),
        if ((summary?.byServicePoint ?? const []).isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _ServicePointBreakdown(
            items: summary!.byServicePoint.take(4).toList(),
            amountFormat: amountFormat,
          ),
        ],
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

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
          Icon(icon, color: color, size: 22),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallMetricCard extends StatelessWidget {
  const _SmallMetricCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
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
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServicePointBreakdown extends StatelessWidget {
  const _ServicePointBreakdown({
    required this.items,
    required this.amountFormat,
  });

  final List<ServicePointReportSummary> items;
  final NumberFormat amountFormat;

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
        children: [
          for (var index = 0; index < items.length; index++) ...[
            if (index > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Divider(color: colors.border, height: 1),
              ),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        items[index].servicePointName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${items[index].operations} ops • ${amountFormat.format(items[index].amount)} FCFA',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                _CountPill(
                  label: 'D ${items[index].depots}',
                  color: AppColors.operationDeposit,
                ),
                const SizedBox(width: AppSpacing.xs),
                _CountPill(
                  label: 'R ${items[index].retraits}',
                  color: AppColors.operationWithdrawal,
                ),
                const SizedBox(width: AppSpacing.xs),
                _CountPill(
                  label: 'T ${items[index].transferts}',
                  color: AppColors.operationTransfer,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
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

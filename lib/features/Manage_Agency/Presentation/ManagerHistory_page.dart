import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});
  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String selectedFilter = 'Tout';

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        title: Text(
          "Historique",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        actions: [
          _buildHeaderButton("Filtrer"),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: colors.textPrimary),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  "Aujourd'hui",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTransactionItem(
                  type: "Retrait MTN",
                  phone: "+229 97 45 12 34",
                  amount: "25 000 F",
                  status: "Réussie",
                  typeColor: AppColors.operationWithdrawal,
                  statusColor: AppColors.success,
                  icon: Icons.arrow_upward,
                ),
                _buildTransactionItem(
                  type: "Dépôt Orange",
                  phone: "+229 91 23 45 67",
                  amount: "10 000 F",
                  status: "En attente",
                  typeColor: AppColors.operationDeposit,
                  statusColor: AppColors.pending,
                  icon: Icons.arrow_downward,
                ),
                const SizedBox(height: 20),
                Text(
                  "Hier",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                _buildTransactionItem(
                  type: "Retrait Moov",
                  phone: "+229 94 11 22 33",
                  amount: "15 000 F",
                  status: "Échouée",
                  typeColor: AppColors.operationWithdrawal,
                  statusColor: AppColors.error,
                  icon: Icons.arrow_upward,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final colors = AppThemeColors(context);
    final filters = ['Tout', 'Retrait', 'Dépôt', 'Transfert'];
    return Container(
      height: 60,
      color: colors.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: filters
            .map(
              (f) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(f),
                  selected: selectedFilter == f,
                  onSelected: (val) => setState(() => selectedFilter = f),
                  selectedColor: AppColors.primary,
                  backgroundColor: colors.surfaceElevated,
                  side: BorderSide(color: colors.border),
                  labelStyle: TextStyle(
                    color: selectedFilter == f
                        ? Colors.white
                        : colors.textPrimary,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildTransactionItem({
    required String type,
    required String phone,
    required String amount,
    required String status,
    required Color typeColor,
    required Color statusColor,
    required IconData icon,
  }) {
    final colors = AppThemeColors(context);
    return Card(
      color: colors.surfaceElevated,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _typeBackground(typeColor),
          child: Icon(icon, size: 18, color: typeColor),
        ),
        title: Text(
          type,
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "$phone · Cabine A\n14:32",
          style: TextStyle(color: colors.textSecondary, fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              amount,
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              status,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _typeBackground(Color color) {
    final colors = AppThemeColors(context);
    if (color == AppColors.operationDeposit) return colors.infoBg;
    if (color == AppColors.operationWithdrawal) return colors.warningBg;
    if (color == AppColors.operationTransfer) return colors.successBg;
    return colors.primarySoft;
  }

  Widget _buildHeaderButton(String label) {
    final colors = AppThemeColors(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(label, style: TextStyle(color: colors.textPrimary)),
      ),
    );
  }
}

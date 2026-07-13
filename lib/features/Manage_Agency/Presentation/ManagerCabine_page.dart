import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../Auth/Controller/login_controller.dart';
import '../Controller/service_point_controller.dart';
import '../data/service_point_state_model.dart';
import '../domain/entities/agent_lookup_result.dart';

class CabinsPage extends ConsumerStatefulWidget {
  const CabinsPage({super.key});

  @override
  ConsumerState<CabinsPage> createState() => _CabinsPageState();
}

class _CabinsPageState extends ConsumerState<CabinsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      // Ensure user is loaded from storage before fetching service points
      ref.read(authControllerProvider.notifier).ensureUserLoaded().then((_) {
        if (mounted) {
          ref
              .read(servicePointControllerProvider.notifier)
              .fetchServicePoints();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicePointControllerProvider);
    final colors = AppThemeColors(context);
    final authState = ref.watch(authControllerProvider);
    return Scaffold(
      backgroundColor: colors.background,
      appBar: _buildAppBar(context, state),
      body: RefreshIndicator(
        color: colors.primary,
        onRefresh: _refreshCabins,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildCabinsList(state, ownerUserId: authState.user?.id),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refreshCabins() async {
    await ref.read(authControllerProvider.notifier).ensureUserLoaded();
    await ref
        .read(servicePointControllerProvider.notifier)
        .fetchServicePoints();
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    ServicePointStateModel state,
  ) {
    final colors = AppThemeColors(context);
    final total = state.servicePoints.length;
    final activeCount = state.servicePoints.where((item) => item.status).length;
    final inactiveCount = total - activeCount;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: colors.surface,
      surfaceTintColor: colors.surface,
      elevation: 0,
      toolbarHeight: 112,
      titleSpacing: 0,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Cabines',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _openCreateServicePointSheet(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Ajouter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      minimumSize: const Size(0, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Align(
                alignment: Alignment.centerLeft,
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 15, color: colors.textSecondary),
                    children: [
                      TextSpan(text: '$total cabines · '),
                      TextSpan(
                        text: '$activeCount actives',
                        style: const TextStyle(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      TextSpan(text: ' · $inactiveCount non actives'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Divider(height: 1, thickness: 1, color: colors.border),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openCreateServicePointSheet(BuildContext context) async {
    ref.read(servicePointControllerProvider.notifier).resetStatus();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppThemeColors(context).surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateServicePointSheet(parentContext: context),
    );
  }

  // 3. Liste des cabines dans un seul bloc blanc
  Widget _buildCabinsList(ServicePointStateModel state, {String? ownerUserId}) {
    final colors = AppThemeColors(context);
    if (state.isLoadingList) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: const Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (state.listErrorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Text(
              state.listErrorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _refreshCabins,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Réessayer'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                textStyle: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }

    if (state.servicePoints.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Aucune cabine pour le moment',
          textAlign: TextAlign.center,
          style: TextStyle(color: colors.textSecondary, fontSize: 13),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: List.generate(state.servicePoints.length, (index) {
          final item = state.servicePoints[index];
          final isActive = item.status;
          final statusText = isActive ? 'Actif' : 'Inactif';
          final statusColor = isActive ? AppColors.success : AppColors.error;
          final subText = item.username != null && item.username!.isNotEmpty
              ? 'Agent: ${item.username}'
              : 'Agent: -';
          return Column(
            children: [
              _buildCabinRow(
                context,
                item.id,
                item.name ?? 'Cabine',
                subText,
                statusText,
                statusColor,
                ownerUserId: ownerUserId,
                isLocked: !isActive,
                onToggleLock: item.id != null
                    ? () {
                        ref
                            .read(servicePointControllerProvider.notifier)
                            .toggleServicePointStatus(
                              id: item.id!,
                              currentStatus: item.status,
                            );
                      }
                    : null,
              ),
              if (index != state.servicePoints.length - 1)
                const Divider(height: 1, indent: 15, endIndent: 15),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCabinRow(
    BuildContext context,
    String? id,
    String name,
    String sub,
    String status,
    Color color, {
    String? ownerUserId,
    bool isAlert = false,
    bool isLocked = false,
    VoidCallback? onToggleLock,
  }) {
    final colors = AppThemeColors(context);
    final accentColor = color;
    final lockColor = isLocked ? AppColors.error : AppColors.success;
    final lockIcon = isLocked ? Icons.lock : Icons.lock_open;
    final canEdit = !isLocked;

    return Container(
      color: isAlert ? colors.primarySoft : colors.surfaceElevated,
      child: InkWell(
        onTap: id == null
            ? null
            : () {
                if (canEdit) {
                  _openEditServicePointDialog(context, id, name, ref: ref);
                } else {
                  _showInactiveCabinMessage(context);
                }
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.circle, size: 11, color: accentColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              InkWell(
                onTap: onToggleLock == null
                    ? null
                    : () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          barrierDismissible: true,
                          builder: (dialogContext) {
                            final dialogColors = AppThemeColors(dialogContext);
                            return AlertDialog(
                              backgroundColor: dialogColors.surfaceElevated,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              title: Text(
                                isLocked
                                    ? 'Réactiver la cabine ?'
                                    : 'Bloquer la cabine ?',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: dialogColors.textPrimary,
                                ),
                              ),
                              content: Text(
                                isLocked
                                    ? 'Cette cabine est actuellement verrouillée. Voulez-vous la réactiver pour autoriser de nouvelles transactions ?'
                                    : 'Cette cabine va être désactivée. Elle ne pourra plus effectuer de transactions jusqu\'à sa réactivation.',
                                style: TextStyle(
                                  color: dialogColors.textSecondary,
                                  fontSize: 15,
                                ),
                              ),
                              actionsPadding: const EdgeInsets.fromLTRB(
                                20,
                                0,
                                20,
                                20,
                              ),
                              actions: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(false),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          side: BorderSide(
                                            color: dialogColors.border,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Annuler',
                                          style: TextStyle(
                                            color: dialogColors.textPrimary,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => Navigator.of(
                                          dialogContext,
                                        ).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isLocked
                                              ? AppColors.success
                                              : AppColors.error,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        child: const Text(
                                          'Confirmer',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          },
                        );

                        if (confirmed == true) {
                          onToggleLock();
                        }
                      },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(lockIcon, size: 18, color: lockColor),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color == AppColors.success
                      ? colors.successBg
                      : colors.errorBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              if (canEdit)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit' && id != null) {
                      _openEditServicePointDialog(context, id, name, ref: ref);
                    }
                  },
                  itemBuilder: (BuildContext ctx) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Text('Mettre à jour'),
                    ),
                  ],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  child: Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: colors.textTertiary,
                  ),
                )
              else
                InkWell(
                  onTap: () => _showInactiveCabinMessage(context),
                  borderRadius: BorderRadius.circular(14),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Opacity(
                      opacity: 0.35,
                      child: Icon(
                        Icons.chevron_right,
                        size: 26,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditServicePointDialog(
    BuildContext context,
    String id,
    String currentName, {
    required WidgetRef ref,
  }) async {
    await showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return _EditCabinDialog(
          id: id,
          currentName: currentName,
          parentContext: context,
        );
      },
    );
  }

  void _showInactiveCabinMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cabine inactive, impossible de la modifier'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
            filled: true,
            fillColor: colors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // 5. Carte d'alerte spécifique (Attention requise)
  Widget _buildWarningCard() {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.primarySoftBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cabine D — Attention requise",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "8 transactions seulement. Activité 83% en dessous de la moyenne.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CreateServicePointSheet extends ConsumerStatefulWidget {
  const CreateServicePointSheet({super.key, required this.parentContext});

  final BuildContext parentContext;

  @override
  ConsumerState<CreateServicePointSheet> createState() =>
      _CreateServicePointSheetState();
}

class _CreateServicePointSheetState
    extends ConsumerState<CreateServicePointSheet> {
  final _formKey = GlobalKey<FormState>();

  final _nameServiceController = TextEditingController();
  final _nameController = TextEditingController();
  final _lastnameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _npiController = TextEditingController();
  final _existingAgentQueryController = TextEditingController();

  String _typeAgent = 'self';
  AgentLookupResult? _lookupResult;
  bool _isSearchingAgent = false;

  @override
  void dispose() {
    _nameServiceController.dispose();
    _nameController.dispose();
    _lastnameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _npiController.dispose();
    _existingAgentQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(servicePointControllerProvider);
    final colors = AppThemeColors(context);

    ref.listen(servicePointControllerProvider, (previous, next) async {
      if (next.isSuccess && previous?.isSuccess != true) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        if (!mounted) {
          return;
        }

        final messenger = ScaffoldMessenger.of(widget.parentContext);
        messenger.clearMaterialBanners();
        messenger.showMaterialBanner(
          const MaterialBanner(
            content: Text('Point de service créé avec succès'),
            backgroundColor: AppColors.success,
            contentTextStyle: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            actions: [SizedBox.shrink()],
          ),
        );
        Future.delayed(const Duration(seconds: 3), () {
          messenger.hideCurrentMaterialBanner();
        });

        if (next.generatedPassword != null &&
            next.generatedPassword!.isNotEmpty) {
          // Show the new styled password dialog
          if (widget.parentContext.mounted) {
            // We use the parent context to show the dialog since the sheet is popping
            await _showUnifiedPasswordDialog(
              widget.parentContext,
              next.generatedPassword!,
            );
          }
        }
      }
    });

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Ajouter une cabine',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildUnifiedField(
                    context,
                    label: 'Nom de la cabine',
                    controller: _nameServiceController,
                    hint: 'Ex: Agence Centrale',
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: 20),
                  _buildTypeSelector(),
                  if (_typeAgent == 'new') ...[
                    const SizedBox(height: 20),
                    _buildUnifiedField(
                      context,
                      label: 'Nom',
                      controller: _nameController,
                      hint: 'Ex: Kofi',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildUnifiedField(
                      context,
                      label: 'Prénom',
                      controller: _lastnameController,
                      hint: 'Ex: Atta',
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildUnifiedField(
                      context,
                      label: 'Email',
                      controller: _emailController,
                      hint: 'Ex: kofi@mail.com',
                      keyboardType: TextInputType.emailAddress,
                      validator: _emailValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildUnifiedField(
                      context,
                      label: 'Téléphone',
                      controller: _phoneController,
                      hint: 'Ex: +2290197451234',
                      keyboardType: TextInputType.phone,
                      validator: _requiredValidator,
                    ),
                    const SizedBox(height: 16),
                    _buildUnifiedField(
                      context,
                      label: 'NPI',
                      controller: _npiController,
                      hint: 'Ex: 129964578120',
                      keyboardType: TextInputType.number,
                      validator: _requiredValidator,
                    ),
                  ],
                  if (_typeAgent == 'existing') ...[
                    const SizedBox(height: 20),
                    _buildExistingAgentSearch(),
                  ],
                  const SizedBox(height: 32),
                  if (state.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.errorBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: state.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: state.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Créer la cabine',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
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

  Widget _buildTypeSelector() {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Type d\'agent',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _typeChip('none', 'Sans agent'),
            _typeChip('self', 'Moi-même'),
            _typeChip('existing', 'Agent existant'),
            _typeChip('new', 'Nouvel agent'),
          ],
        ),
      ],
    );
  }

  Widget _typeChip(String value, String label) {
    final colors = AppThemeColors(context);
    final isSelected = _typeAgent == value;
    return InkWell(
      onTap: () => setState(() {
        _typeAgent = value;
        _lookupResult = null;
      }),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : colors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildExistingAgentSearch() {
    final colors = AppThemeColors(context);
    final result = _lookupResult;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildUnifiedField(
          context,
          label: 'Téléphone ou NPI',
          controller: _existingAgentQueryController,
          hint: 'Ex: +2290197451234 ou 129964578120',
          keyboardType: TextInputType.text,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _isSearchingAgent ? null : _searchExistingAgent,
            icon: _isSearchingAgent
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search, size: 18),
            label: const Text('Rechercher'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.primary,
              side: BorderSide(color: colors.primary),
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        if (result != null) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: result.canBeAssigned ? colors.successBg : colors.errorBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  result.canBeAssigned
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: result.canBeAssigned
                      ? AppColors.success
                      : AppColors.error,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    result.exists
                        ? '${result.displayName}\n${result.reason ?? ''}'
                        : (result.reason ?? 'Aucun compte trouvé'),
                    style: TextStyle(
                      color: result.canBeAssigned
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _searchExistingAgent() async {
    final query = _existingAgentQueryController.text.trim();
    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isSearchingAgent = true;
      _lookupResult = null;
    });

    final isNpi = RegExp(r'^[0-9]{12}$').hasMatch(query);
    final result = await ref
        .read(servicePointControllerProvider.notifier)
        .findAgent(npi: isNpi ? query : null, phone: isNpi ? null : query);

    if (!mounted) {
      return;
    }

    setState(() {
      _isSearchingAgent = false;
      _lookupResult = result;
    });
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final colors = AppThemeColors(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
            filled: true,
            fillColor: colors.surfaceAlt,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: colors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_typeAgent == 'existing' &&
        (_lookupResult == null ||
            !_lookupResult!.exists ||
            !_lookupResult!.canBeAssigned ||
            _lookupResult!.userId == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Recherchez puis selectionnez un agent disponible'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ref
        .read(servicePointControllerProvider.notifier)
        .createServicePoint(
          nameService: _nameServiceController.text.trim(),
          typeAgent: _typeAgent,
          name: _typeAgent == 'new' ? _nameController.text.trim() : null,
          lastname: _typeAgent == 'new'
              ? _lastnameController.text.trim()
              : null,
          email: _typeAgent == 'new' ? _emailController.text.trim() : null,
          phone: _typeAgent == 'new' ? _phoneController.text.trim() : null,
          npi: _typeAgent == 'new' ? _npiController.text.trim() : null,
          userId: _typeAgent == 'existing' ? _lookupResult?.userId : null,
        );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    return null;
  }

  String? _emailValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Champ obligatoire';
    }
    if (!value.contains('@')) {
      return 'Email invalide';
    }
    return null;
  }

  Widget _buildWarningCard() {
    final colors = AppThemeColors(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.primarySoftBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Cabine D — Attention requise",
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "8 transactions seulement. Activité 83% en dessous de la moyenne.",
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditCabinDialog extends ConsumerStatefulWidget {
  final String id;
  final String currentName;
  final BuildContext parentContext;

  const _EditCabinDialog({
    required this.id,
    required this.currentName,
    required this.parentContext,
  });

  @override
  ConsumerState<_EditCabinDialog> createState() => _EditCabinDialogState();
}

class _EditCabinDialogState extends ConsumerState<_EditCabinDialog> {
  late TextEditingController nameServiceController;
  late TextEditingController nameController;
  late TextEditingController lastnameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;
  late TextEditingController npiController;
  late TextEditingController existingAgentQueryController;

  bool changeAgent = false;
  String agentMode = 'owner';
  bool isSubmitting = false;
  bool isSearchingAgent = false;
  AgentLookupResult? lookupResult;

  @override
  void initState() {
    super.initState();
    nameServiceController = TextEditingController(text: widget.currentName);
    nameController = TextEditingController();
    lastnameController = TextEditingController();
    emailController = TextEditingController();
    phoneController = TextEditingController();
    npiController = TextEditingController();
    existingAgentQueryController = TextEditingController();
    // Debug: print service point details to help verify agency association
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(servicePointControllerProvider);
      final matches = state.servicePoints.where((s) => s.id == widget.id);
      if (matches.isNotEmpty) {
        final sp = matches.first;
        debugPrint(
          'EditCabin debug: id=${sp.id} status=${sp.status} agencyId=${sp.agencyId}',
        );
      } else {
        debugPrint(
          'EditCabin debug: servicePoint not found for id=${widget.id}',
        );
      }
    });
  }

  @override
  void dispose() {
    nameServiceController.dispose();
    nameController.dispose();
    lastnameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    npiController.dispose();
    existingAgentQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppThemeColors(context);

    return AlertDialog(
      backgroundColor: colors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.border),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: Text(
        'Mettre à jour la cabine',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: colors.textPrimary,
        ),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildUnifiedField(
                context,
                label: 'Nom de la cabine',
                controller: nameServiceController,
                hint: 'Ex: Agence Centrale',
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  value: changeAgent,
                  activeThumbColor: colors.primary,
                  onChanged: (value) {
                    setState(() {
                      changeAgent = value;
                    });
                  },
                  title: Text(
                    'Modifier l\'agent',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
              if (changeAgent) ...[
                const SizedBox(height: 20),
                Text(
                  'Mode d\'affectation',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _agentModeChip('none', 'Retirer agent'),
                    _agentModeChip('owner', 'Propriétaire'),
                    _agentModeChip('existing', 'Agent existant'),
                    _agentModeChip('new', 'Nouvel agent'),
                  ],
                ),
              ],
              if (changeAgent && agentMode == 'owner') ...[
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.primarySoftBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: colors.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'La cabine vous sera réaffectée.',
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (changeAgent && agentMode == 'none') ...[
                const SizedBox(height: 20),
                _buildInfoBox(
                  colors,
                  'La cabine restera disponible sans agent affecté.',
                ),
              ],
              if (changeAgent && agentMode == 'existing') ...[
                const SizedBox(height: 20),
                _buildUnifiedField(
                  context,
                  label: 'Téléphone ou NPI',
                  controller: existingAgentQueryController,
                  hint: 'Ex: +2290197451234 ou 129964578120',
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: isSearchingAgent ? null : _searchAgent,
                    icon: isSearchingAgent
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Rechercher'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.primary,
                      side: BorderSide(color: colors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                if (lookupResult != null) ...[
                  const SizedBox(height: 12),
                  _buildLookupResultBox(colors),
                ],
              ],
              if (changeAgent && agentMode == 'new') ...[
                const SizedBox(height: 20),
                _buildUnifiedField(
                  context,
                  label: 'Nom',
                  controller: nameController,
                  hint: 'Ex: Kofi',
                ),
                const SizedBox(height: 16),
                _buildUnifiedField(
                  context,
                  label: 'Prénom',
                  controller: lastnameController,
                  hint: 'Ex: Atta',
                ),
                const SizedBox(height: 16),
                _buildUnifiedField(
                  context,
                  label: 'Email',
                  controller: emailController,
                  hint: 'Ex: kofi@mail.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildUnifiedField(
                  context,
                  label: 'Téléphone',
                  controller: phoneController,
                  hint: 'Ex: +2290197451234',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildUnifiedField(
                  context,
                  label: 'NPI',
                  controller: npiController,
                  hint: 'Ex: 129964578120',
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: colors.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        setState(() => isSubmitting = true);

                        final trimmedNameService = nameServiceController.text
                            .trim();
                        final trimmedName = nameController.text.trim();
                        final trimmedLastname = lastnameController.text.trim();
                        final trimmedEmail = emailController.text.trim();
                        final trimmedPhone = phoneController.text.trim();
                        final trimmedNpi = npiController.text.trim();
                        if (changeAgent &&
                            agentMode == 'existing' &&
                            (lookupResult == null ||
                                !lookupResult!.exists ||
                                !lookupResult!.canBeAssigned ||
                                lookupResult!.userId == null)) {
                          if (mounted) setState(() => isSubmitting = false);
                          ScaffoldMessenger.of(
                            widget.parentContext,
                          ).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Recherchez puis selectionnez un agent disponible',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        await ref
                            .read(servicePointControllerProvider.notifier)
                            .updateServicePoint(
                              id: widget.id,
                              nameService: trimmedNameService.isNotEmpty
                                  ? trimmedNameService
                                  : null,
                              typeAgent: !changeAgent
                                  ? null
                                  : switch (agentMode) {
                                      'new' => 'new',
                                      'existing' => 'existing',
                                      'none' => 'none',
                                      _ => 'self',
                                    },
                              userId: changeAgent && agentMode == 'existing'
                                  ? lookupResult?.userId
                                  : null,
                              name:
                                  changeAgent &&
                                      agentMode == 'new' &&
                                      trimmedName.isNotEmpty
                                  ? trimmedName
                                  : null,
                              lastname:
                                  changeAgent &&
                                      agentMode == 'new' &&
                                      trimmedLastname.isNotEmpty
                                  ? trimmedLastname
                                  : null,
                              email:
                                  changeAgent &&
                                      agentMode == 'new' &&
                                      trimmedEmail.isNotEmpty
                                  ? trimmedEmail
                                  : null,
                              phone:
                                  changeAgent &&
                                      agentMode == 'new' &&
                                      trimmedPhone.isNotEmpty
                                  ? trimmedPhone
                                  : null,
                              npi:
                                  changeAgent &&
                                      agentMode == 'new' &&
                                      trimmedNpi.isNotEmpty
                                  ? trimmedNpi
                                  : null,
                            );

                        final updatedState = ref.read(
                          servicePointControllerProvider,
                        );
                        if (mounted) setState(() => isSubmitting = false);

                        if (updatedState.isSuccess) {
                          if (mounted) {
                            Navigator.of(context).pop();
                          }

                          // Show generated password dialog if a new agent was created
                          if (updatedState.generatedPassword != null &&
                              updatedState.generatedPassword!.isNotEmpty &&
                              widget.parentContext.mounted) {
                            final password = updatedState.generatedPassword!;
                            await _showUnifiedPasswordDialog(
                              widget.parentContext,
                              password,
                            );
                            // Reset state after password dialog is dismissed
                            ref
                                .read(servicePointControllerProvider.notifier)
                                .resetStatus();
                          }
                        } else if (widget.parentContext.mounted) {
                          ScaffoldMessenger.of(
                            widget.parentContext,
                          ).showSnackBar(
                            SnackBar(
                              content: Text(
                                updatedState.listErrorMessage ??
                                    'Cabine inactive, impossible de la modifier',
                              ),
                              behavior: SnackBarBehavior.floating,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Confirmer',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _agentModeChip(String value, String label) {
    final colors = AppThemeColors(context);
    final selected = agentMode == value;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() {
        agentMode = value;
        lookupResult = null;
      }),
      selectedColor: colors.primary,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: selected ? Colors.white : colors.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      ),
    );
  }

  Widget _buildInfoBox(AppThemeColors colors, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primarySoftBorder),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: colors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: colors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLookupResultBox(AppThemeColors colors) {
    final result = lookupResult!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: result.canBeAssigned ? colors.successBg : colors.errorBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        result.exists
            ? '${result.displayName}\n${result.reason ?? ''}'
            : (result.reason ?? 'Aucun compte trouvé'),
        style: TextStyle(
          color: result.canBeAssigned ? AppColors.success : AppColors.error,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }

  Future<void> _searchAgent() async {
    final query = existingAgentQueryController.text.trim();
    if (query.isEmpty) return;

    setState(() {
      isSearchingAgent = true;
      lookupResult = null;
    });

    final isNpi = RegExp(r'^[0-9]{12}$').hasMatch(query);
    final result = await ref
        .read(servicePointControllerProvider.notifier)
        .findAgent(npi: isNpi ? query : null, phone: isNpi ? null : query);

    if (!mounted) return;

    setState(() {
      isSearchingAgent = false;
      lookupResult = result;
    });
  }
}

Widget _buildUnifiedField(
  BuildContext context, {
  required String label,
  required TextEditingController controller,
  required String hint,
  TextInputType? keyboardType,
  String? Function(String?)? validator,
}) {
  final colors = AppThemeColors(context);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: colors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: colors.textTertiary, fontSize: 14),
          filled: true,
          fillColor: colors.surfaceAlt,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: colors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
        ),
      ),
    ],
  );
}

Future<void> _showUnifiedPasswordDialog(
  BuildContext context,
  String password,
) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (pwdDialogContext) {
      final colors = AppThemeColors(pwdDialogContext);

      return AlertDialog(
        backgroundColor: colors.surfaceElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: colors.border),
        ),
        title: Text(
          'Compte agent créé',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: colors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Un mot de passe a été généré pour le nouvel agent. '
              'Veuillez le copier et le conserver en lieu sûr.',
              style: TextStyle(fontSize: 14, color: colors.textSecondary),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceAlt,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      password,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        color: colors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: password));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mot de passe copié !'),
                          duration: Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: Icon(Icons.copy, size: 22, color: colors.primary),
                    tooltip: 'Copier',
                  ),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(pwdDialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Compris',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      );
    },
  );
}

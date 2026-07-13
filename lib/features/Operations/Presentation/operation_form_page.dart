import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../Controller/operation_controller.dart';
import '../data/models/operator_model.dart';
import '../data/services/ussd/ussd_execution_result.dart';
import '../di/operation_providers.dart';
import '../../Manage_Agency/Controller/service_point_controller.dart';

class OperationFormPage extends ConsumerStatefulWidget {
  final String operationType;

  const OperationFormPage({super.key, required this.operationType});

  @override
  ConsumerState<OperationFormPage> createState() => _OperationFormPageState();
}

class _OperationFormPageState extends ConsumerState<OperationFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _pinController = TextEditingController();
  OperatorModel? _selectedOperator;
  UssdModel? _selectedUssd;
  int _selectedSimSlot = 0;
  List<DeviceSimInfo> _deviceSimCards = const [];

  @override
  void initState() {
    super.initState();
    // Charger le point de service de l'agent s'il n'est pas là
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(servicePointControllerProvider.notifier).fetchMyServicePoint();
      _loadSimCards();
    });
  }

  Future<void> _loadSimCards() async {
    try {
      final simCards = await ref.read(ussdExecutorProvider).getSimCards();
      if (!mounted || simCards.isEmpty) return;

      final sortedSimCards = [...simCards]
        ..sort((a, b) => a.slotIndex.compareTo(b.slotIndex));

      setState(() {
        _deviceSimCards = sortedSimCards;
        final selectedExists = sortedSimCards.any(
          (sim) => sim.slotIndex == _selectedSimSlot,
        );
        if (!selectedExists) {
          _selectedSimSlot = sortedSimCards.first.slotIndex;
        }
      });
    } catch (_) {
      // Si le moteur USSD actuel ne peut pas lister les SIM, on garde le
      // fallback manuel SIM 1 / SIM 2.
    }
  }

  void _onOperatorChanged(OperatorModel? val) {
    setState(() {
      _selectedOperator = val;
      _selectedUssd = null;
      if (val != null) {
        final matchingUssds = _matchingUssds(val);
        _selectedUssd = matchingUssds.length == 1 ? matchingUssds.first : null;
      }
    });
  }

  List<UssdModel> _matchingUssds(OperatorModel operator) {
    final operationType = _normalizeOperationType(widget.operationType);
    return operator.ussds
        .where(
          (u) =>
              u.isActive &&
              _normalizeOperationType(u.operationType) == operationType,
        )
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  String _normalizeOperationType(String value) {
    return value
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('ò', 'o')
        .replaceAll('ó', 'o')
        .trim();
  }

  bool get _isTransfer {
    return _normalizeOperationType(widget.operationType) == 'transfert';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _amountController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final operationState = ref.watch(operationControllerProvider);
    final colors = AppThemeColors(context);
    final surface = colors.surfaceElevated;
    final fieldColor = colors.surfaceAlt;
    final borderColor = colors.border;
    final secondaryText = colors.textSecondary;
    final matchingUssds = _selectedOperator == null
        ? <UssdModel>[]
        : _matchingUssds(_selectedOperator!);
    final simOptions = _simOptions();
    final selectedSimSlot =
        simOptions.any((sim) => sim.slotIndex == _selectedSimSlot)
        ? _selectedSimSlot
        : simOptions.first.slotIndex;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppRadii.sheet),
          topRight: Radius.circular(AppRadii.sheet),
        ),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                "Nouveau ${widget.operationType}",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                "Veuillez remplir les informations pour effectuer l'opération.",
                style: TextStyle(color: secondaryText, fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xxl),

              // Sélecteur d'opérateur
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Réseau / Opérateur",
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (operationState.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (operationState.error != null)
                _buildErrorPanel(
                  operationState.error!,
                  onRetry: () => ref
                      .read(operationControllerProvider.notifier)
                      .getOperators(),
                ),
              DropdownButtonFormField<OperatorModel>(
                initialValue: _selectedOperator,
                hint: Text(
                  operationState.isLoading
                      ? "Chargement..."
                      : "Choisir l'opérateur",
                ),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                items: operationState.operators.isEmpty
                    ? []
                    : operationState.operators.map((op) {
                        return DropdownMenuItem(
                          value: op,
                          child: Text(op.name),
                        );
                      }).toList(),
                onChanged: _onOperatorChanged,
                validator: (val) => val == null ? "Champ requis" : null,
              ),

              if (_selectedOperator != null && matchingUssds.length > 1) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  _isTransfer ? "Type de transfert" : "Service USSD",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<UssdModel>(
                  initialValue: _selectedUssd,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: fieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  items: matchingUssds.map((u) {
                    return DropdownMenuItem(
                      value: u,
                      child: Text(u.displayLabel),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedUssd = val),
                  validator: (val) {
                    if (val == null) return "Service non disponible";
                    return null;
                  },
                ),
              ] else if (_selectedOperator != null &&
                  matchingUssds.isEmpty) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(
                  "Aucun service disponible pour ${widget.operationType}.",
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),

              if (_selectedUssd?.requiresNumber == true) ...[
                // Numéro Téléphone
                Text(
                  "Numéro du client",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: "01XXXXXXXX",
                          filled: true,
                          fillColor: fieldColor,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 18,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                            borderSide: BorderSide(
                              color: colors.primary,
                              width: 1.4,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return "Champ requis";
                          final normalized = val.trim().replaceAll(
                            RegExp(r'[\s-]+'),
                            '',
                          );
                          if (!RegExp(
                            r'^(?:01[0-9]{8,15}|22901[0-9]{8,15}|\+22901[0-9]{8,15})$',
                          ).hasMatch(normalized)) {
                            return "Format invalide (01..., 22901... ou +22901...)";
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 58,
                      height: 58,
                      child: OutlinedButton(
                        onPressed: _openContactNumber,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: fieldColor,
                          foregroundColor: colors.primary,
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.md),
                          ),
                        ),
                        child: const Icon(Icons.person_rounded, size: 24),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              if (_selectedUssd != null) ...[
                // Montant
                Text(
                  "Montant (FCFA)",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    hintText: "Ex: 5000",
                    prefixIcon: const Icon(Icons.money),
                    filled: true,
                    fillColor: fieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Champ requis";
                    final amount = double.tryParse(val.trim());
                    if (amount == null) return "Montant invalide";
                    if (amount <= 0) {
                      return "Le montant doit être supérieur à 0";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              if (_selectedUssd?.requiresPin ?? false) ...[
                Text(
                  "Code secret",
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  controller: _pinController,
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: "Code secret",
                    prefixIcon: const Icon(Icons.lock_outline),
                    filled: true,
                    fillColor: fieldColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      borderSide: BorderSide(color: borderColor),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return "Champ requis";
                    if (val.length < 2) return "Code trop court";
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              // Sélection SIM
              Text(
                "SIM d'exécution",
                style: TextStyle(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<int>(
                initialValue: selectedSimSlot,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: fieldColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.md),
                    borderSide: BorderSide(color: borderColor),
                  ),
                ),
                items: simOptions.map((sim) {
                  return DropdownMenuItem(
                    value: sim.slotIndex,
                    child: Text(sim.label),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val == null) return;
                  setState(() => _selectedSimSlot = val);
                },
              ),
              const SizedBox(height: AppSpacing.xxxl),

              // Bouton de validation
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: operationState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                    ),
                    elevation: 0,
                  ),
                  child: operationState.isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Exécuter l'opération",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }

  List<DeviceSimInfo> _simOptions() {
    if (_deviceSimCards.isNotEmpty) return _deviceSimCards;

    return const [DeviceSimInfo(slotIndex: 0), DeviceSimInfo(slotIndex: 1)];
  }

  Future<void> _openContactNumber() async {
    final hasPermission = await FlutterContacts.requestPermission(
      readonly: true,
    );
    if (!hasPermission) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Permission refusée. Impossible d'accéder aux contacts.",
          ),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final contact = await FlutterContacts.openExternalPick();
    if (contact == null) return;

    final fullContact = await FlutterContacts.getContact(contact.id);
    final phones = fullContact?.phones ?? [];
    if (phones.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Ce contact n'a pas de numéro de téléphone."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final selectedNumber = phones.first.number;
    final normalized = _normalizeContactNumberForOperation(selectedNumber);

    if (normalized == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Numéro de téléphone invalide pour l'opération."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _phoneController.text = normalized;
    });
  }

  String? _normalizeContactNumberForOperation(String raw) {
    //Nettoyage des espaces et caractères spéciaux
    var value = raw.trim().replaceAll(RegExp(r'[\s().-]+'), '');

    if (value.startsWith('+229')) {
      value = value.substring(4);
    } else if (value.startsWith('00229')) {
      value = value.substring(5);
    } else if (value.startsWith('229')) {
      value = value.substring(3);
    }

    if (value.length == 8 && !value.startsWith('01')) {
      value = '01$value';
    }

    if (value.startsWith('01') && value.length == 10) {
      return value;
    }
    return null;
  }

  Widget _buildErrorPanel(String message, {required VoidCallback onRetry}) {
    final colors = AppThemeColors(context);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppColors.error,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              minimumSize: const Size(0, 34),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final selectedUssd = _selectedUssd;

    final myServicePoint = ref
        .read(servicePointControllerProvider)
        .myServicePoint;
    if (myServicePoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Point de service introuvable. Veuillez réessayer."),
        ),
      );
      return;
    }

    if (!myServicePoint.status) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Cette cabine est inactive. Les opérations sont bloquées.",
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (selectedUssd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Veuillez choisir un service disponible."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref
        .read(operationControllerProvider.notifier)
        .executeOperation(
          ussdId: selectedUssd.id,
          number: selectedUssd.requiresNumber
              ? _phoneController.text.trim()
              : null,
          amount: double.parse(_amountController.text.trim()),
          pin: selectedUssd.requiresPin ? _pinController.text.trim() : null,
          servicePointId: myServicePoint.id!,
          simSlot: _selectedSimSlot,
          requireTransactionIdForConfirmation:
              _normalizeOperationType(selectedUssd.operationType) !=
              'transfert',
        );

    if (success && mounted) {
      await ref
          .read(servicePointControllerProvider.notifier)
          .fetchOperationStats(myServicePoint.id!);
      await ref.read(operationControllerProvider.notifier).getHistory();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Opération envoyée ! Le dialer va s'ouvrir."),
          backgroundColor: AppColors.success,
        ),
      );
    } else if (mounted) {
      final error = ref.read(operationControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? "Une erreur est survenue"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

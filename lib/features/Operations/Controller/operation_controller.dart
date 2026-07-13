import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/operator_model.dart';
import '../data/models/execute_operation_model.dart';
import '../data/models/operation_history_model.dart';
import '../data/services/ussd_response_parser.dart';
import '../di/operation_providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/utils/user_friendly_error.dart';

const _unset = Object();

class OperationState {
  final bool isLoading;
  final List<OperatorModel> operators;
  final bool isLoadingHistory;
  final List<OperationHistoryItem> history;
  final String? historyError;
  final String? error;

  OperationState({
    this.isLoading = false,
    this.operators = const [],
    this.isLoadingHistory = false,
    this.history = const [],
    this.historyError,
    this.error,
  });

  OperationState copyWith({
    bool? isLoading,
    List<OperatorModel>? operators,
    bool? isLoadingHistory,
    List<OperationHistoryItem>? history,
    Object? historyError = _unset,
    Object? error = _unset,
  }) {
    return OperationState(
      isLoading: isLoading ?? this.isLoading,
      operators: operators ?? this.operators,
      isLoadingHistory: isLoadingHistory ?? this.isLoadingHistory,
      history: history ?? this.history,
      historyError: identical(historyError, _unset)
          ? this.historyError
          : historyError as String?,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }
}

class OperationController extends Notifier<OperationState> {
  @override
  OperationState build() {
    // On charge les opérateurs dès que le contrôleur est initialisé
    Future.microtask(() => getOperators());
    return OperationState();
  }

  Future<void> getOperators() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      dev.log('OperationController: Fetching operators...');
      final operators = await ref
          .read(operationRepositoryProvider)
          .getOperators();
      dev.log(
        'OperationController: Successfully fetched ${operators.length} operators.',
      );
      state = state.copyWith(isLoading: false, operators: operators);
    } catch (e, stack) {
      dev.log('OperationController Error: $e');
      dev.log('Stack trace: $stack');
      state = state.copyWith(
        isLoading: false,
        error: _operatorsErrorMessage(e),
      );
    }
  }

  Future<void> getHistory() async {
    state = state.copyWith(isLoadingHistory: true, historyError: null);
    try {
      final history = await ref.read(operationRepositoryProvider).getHistory();
      state = state.copyWith(isLoadingHistory: false, history: history);
    } catch (e, stack) {
      dev.log('OperationController history error: $e');
      dev.log('Stack trace: $stack');
      state = state.copyWith(
        isLoadingHistory: false,
        historyError: _historyErrorMessage(e),
      );
    }
  }

  Future<bool> executeOperation({
    required int ussdId,
    String? number,
    required double amount,
    String? pin,
    required String servicePointId,
    required int simSlot,
    required bool requireTransactionIdForConfirmation,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final request = ExecuteOperationRequest(
        ussdId: ussdId,
        number: number,
        amount: amount,
        pin: pin,
        servicePointId: servicePointId,
      );
      final response = await ref
          .read(operationRepositoryProvider)
          .executeOperation(request);

      final ussdCode = response.ussdCode;
      dev.log('Executing Direct USSD for ussdId=$ussdId');
      await AppLogger.info(
        'USSD execute ussdId=$ussdId simSlot=$simSlot',
        tag: 'USSD',
      );

      // Execution avec capture de reponse via le moteur USSD injectable.
      final ussdResult = await ref
          .read(ussdExecutorProvider)
          .execute(
            code: ussdCode,
            simSlot: simSlot,
            timeout: const Duration(seconds: 25),
          );
      final ussdResponse = ussdResult.rawMessage;
      dev.log('USSD Response: $ussdResponse');
      await AppLogger.info(
        'USSD response=$ussdResponse duration=${ussdResult.duration}',
        tag: 'USSD',
      );

      if (!ussdResult.success &&
          !ussdResult.hasMessage &&
          ussdResult.errorMessage != null &&
          !ussdResult.errorMessage!.contains('Aucune reponse USSD')) {
        throw Exception(ussdResult.errorMessage);
      }

      if (ussdResponse == null || ussdResponse.trim().isEmpty) {
        await AppLogger.warning(
          'USSD no response captured; check accessibility service and fallback to SMS matching',
          tag: 'USSD',
        );
      }

      final ussdStatus = UssdResponseParser.parse(
        ussdResponse,
        requireTransactionId: requireTransactionIdForConfirmation,
      );
      dev.log('USSD Parsed Status: $ussdStatus');
      await AppLogger.info('USSD status=$ussdStatus', tag: 'USSD');

      switch (ussdStatus) {
        case UssdResponseStatus.confirmed:
          final transactionId = UssdResponseParser.extractTransactionId(
            ussdResponse,
          );
          await ref
              .read(operationRepositoryProvider)
              .confirmOperationDirect(
                operationId: response.operationId,
                message: ussdResponse!,
                transactionId: transactionId,
              );
          await AppLogger.info(
            'confirm-direct success operationId=${response.operationId} transactionId=$transactionId',
            tag: 'USSD',
          );
          break;
        case UssdResponseStatus.failed:
          await AppLogger.warning(
            'USSD failed response=$ussdResponse',
            tag: 'USSD',
          );
          state = state.copyWith(
            isLoading: false,
            error: ussdResponse ?? 'Opération USSD échouée',
          );
          return false;
        case UssdResponseStatus.pending:
        case UssdResponseStatus.unknown:
          // Pas de confirmation directe: le matching SMS servira de filet.
          await AppLogger.info(
            'USSD fallback SMS status=$ussdStatus',
            tag: 'USSD',
          );
          break;
      }

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final message = _operationErrorMessage(e);
      await AppLogger.error('executeOperation failed', tag: 'USSD', error: e);
      state = state.copyWith(isLoading: false, error: message);
      return false;
    }
  }

  String _operationErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'] ?? data['error'];
        if (message != null &&
            message.toString().trim().isNotEmpty &&
            !_looksTechnical(message.toString())) {
          return message.toString();
        }
      }
      if (error.response?.statusCode == 403) {
        return 'Cette cabine est inactive ou vous n’êtes pas autorisé à effectuer cette opération.';
      }

      return userFriendlyDioMessage(
        error,
        fallback:
            'Impossible d’exécuter l’opération pour le moment. Vérifiez votre connexion puis réessayez.',
      );
    }

    return userFriendlyUnexpectedMessage(
      fallback: 'Impossible d’exécuter l’opération pour le moment. Réessayez.',
    );
  }

  String _operatorsErrorMessage(Object error) {
    if (error is DioException) {
      return userFriendlyDioMessage(
        error,
        fallback:
            'Impossible de charger les opérateurs pour le moment. Réessayez.',
      );
    }

    return userFriendlyUnexpectedMessage(
      fallback:
          'Impossible de charger les opérateurs pour le moment. Réessayez.',
    );
  }

  String _historyErrorMessage(Object error) {
    if (error is DioException) {
      return userFriendlyDioMessage(
        error,
        fallback:
            'Impossible de charger les dernières transactions pour le moment. Réessayez.',
      );
    }

    return userFriendlyUnexpectedMessage(
      fallback:
          'Impossible de charger les dernières transactions pour le moment. Réessayez.',
    );
  }

  bool _looksTechnical(String message) {
    final value = message.toLowerCase();
    const markers = [
      'dioexception',
      'exception',
      'sqlstate',
      'queryexception',
      'socketexception',
      'connection error',
      'stack trace',
      'trace:',
      'vendor/',
      'line ',
    ];

    return markers.any(value.contains);
  }
}

final operationControllerProvider =
    NotifierProvider<OperationController, OperationState>(() {
      return OperationController();
    });

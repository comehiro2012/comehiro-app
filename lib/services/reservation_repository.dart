import 'package:cloud_functions/cloud_functions.dart';

import '../models/reservation.dart';

/// 予約の登録窓口。Cloud Functionsが最終検証してからFirestoreへ保存します。
class ReservationRepository {
  ReservationRepository({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-northeast1');

  final FirebaseFunctions _functions;

  Future<String> create(ReservationDraft reservation) async {
    try {
      final result = await _functions
          .httpsCallable('createReservation')
          .call<Map<String, dynamic>>(reservation.toCallablePayload());
      return result.data['reservationId'] as String;
    } on FirebaseFunctionsException catch (error) {
      throw ReservationRepositoryException(error.message ?? '予約を登録できませんでした。');
    }
  }
}

class ReservationRepositoryException implements Exception {
  const ReservationRepositoryException(this.message);
  final String message;
  @override
  String toString() => message;
}

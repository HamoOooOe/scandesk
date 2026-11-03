import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../assets/domain/asset.dart';
import '../../../assets/domain/assets_repository.dart';
import '../../domain/qr_payload.dart';

enum ScanStatus { idle, resolving, found, notOurs, notFound, error }

class ScanState extends Equatable {
  const ScanState({this.status = ScanStatus.idle, this.asset, this.error});

  final ScanStatus status;
  final Asset? asset;
  final String? error;

  @override
  List<Object?> get props => [status, asset, error];
}

/// Turns whatever the camera (or the keyboard) produced into an asset.
/// The page decides where to go next, because that depends on the role.
class ScanCubit extends Cubit<ScanState> {
  ScanCubit(this._assets) : super(const ScanState());

  final AssetsRepository _assets;

  Future<void> submit(String raw) async {
    if (state.status == ScanStatus.resolving) return;
    final code = QrPayload.parse(raw);
    if (code == null) {
      emit(const ScanState(status: ScanStatus.notOurs));
      return;
    }
    emit(const ScanState(status: ScanStatus.resolving));
    try {
      final asset = await _assets.getByCode(code);
      emit(
        asset == null
            ? const ScanState(status: ScanStatus.notFound)
            : ScanState(status: ScanStatus.found, asset: asset),
      );
    } on Failure catch (failure) {
      emit(ScanState(status: ScanStatus.error, error: failure.message));
    }
  }

  void reset() => emit(const ScanState());
}

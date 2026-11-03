import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../assets/domain/asset.dart';
import '../../../assets/domain/assets_repository.dart';
import '../../domain/ticket.dart';
import '../../domain/tickets_repository.dart';

enum ReportStatus { loading, editing, sending, sent, notFound, error }

class ReportState extends Equatable {
  const ReportState({
    this.status = ReportStatus.loading,
    this.asset,
    this.photos = const [],
    this.error,
  });

  final ReportStatus status;
  final Asset? asset;

  /// Local file paths of photos picked for this report (max 3).
  final List<String> photos;
  final String? error;

  ReportState copyWith({ReportStatus? status, Asset? asset, List<String>? photos, String? error}) {
    return ReportState(
      status: status ?? this.status,
      asset: asset ?? this.asset,
      photos: photos ?? this.photos,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, asset, photos, error];
}

/// The "report an issue" form for one asset.
class ReportCubit extends Cubit<ReportState> {
  ReportCubit(this._assets, this._tickets) : super(const ReportState());

  static const maxPhotos = 3;

  final AssetsRepository _assets;
  final TicketsRepository _tickets;

  Future<void> load(String assetId) async {
    try {
      final asset = await _assets.getById(assetId);
      emit(
        asset == null
            ? const ReportState(status: ReportStatus.notFound)
            : ReportState(status: ReportStatus.editing, asset: asset),
      );
    } on Failure catch (failure) {
      emit(ReportState(status: ReportStatus.error, error: failure.message));
    }
  }

  void addPhoto(String path) {
    if (state.photos.length >= maxPhotos) return;
    emit(state.copyWith(photos: [...state.photos, path]));
  }

  void removePhoto(String path) =>
      emit(state.copyWith(photos: state.photos.where((p) => p != path).toList()));

  Future<void> send({
    required String title,
    required String description,
    required TicketPriority priority,
  }) async {
    final asset = state.asset;
    if (asset == null) return;
    emit(state.copyWith(status: ReportStatus.sending));
    try {
      await _tickets.create(
        assetId: asset.id,
        title: title,
        description: description,
        priority: priority,
        photoPaths: state.photos,
      );
      emit(state.copyWith(status: ReportStatus.sent));
    } on Failure catch (failure) {
      emit(state.copyWith(status: ReportStatus.editing, error: failure.message));
    }
  }
}

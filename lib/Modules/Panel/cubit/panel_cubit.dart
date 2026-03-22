import 'package:bloc/bloc.dart';
import 'package:beat_cinema/models/level_metadata.dart';

enum PanelContentType {
  search,
  configEdit,
  fileInfo,
  downloadDetail,
  audioPreview,
  videoPreview,
  syncCalibration,
}

class PanelState {
  final bool isOpen;
  final PanelContentType? contentType;
  final LevelMetadata? context;

  const PanelState({this.isOpen = false, this.contentType, this.context});

  PanelState copyWith({
    bool? isOpen,
    PanelContentType? contentType,
    LevelMetadata? context,
  }) {
    return PanelState(
      isOpen: isOpen ?? this.isOpen,
      contentType: contentType ?? this.contentType,
      context: context ?? this.context,
    );
  }
}

class PanelCubit extends Cubit<PanelState> {
  PanelCubit() : super(const PanelState());

  void openPanel(PanelContentType type, {LevelMetadata? context}) {
    emit(PanelState(isOpen: true, contentType: type, context: context));
  }

  void closePanel() {
    emit(const PanelState());
  }

  void togglePanel(PanelContentType type, {LevelMetadata? context}) {
    if (state.isOpen && state.contentType == type) {
      closePanel();
    } else {
      openPanel(type, context: context);
    }
  }
}

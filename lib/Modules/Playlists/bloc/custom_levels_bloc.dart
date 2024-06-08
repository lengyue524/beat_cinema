import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'custom_levels_event.dart';
part 'custom_levels_state.dart';

class CustomLevelsBloc extends Bloc<CustomLevelsEvent, CustomLevelsState> {
  CustomLevelsBloc() : super(CustomLevelsInitial()) {
    on<CustomLevelsEvent>((event, emit) {
      // TODO: implement event handler
    });
  }
}

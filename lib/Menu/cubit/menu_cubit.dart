import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

part 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit() : super(MenuState(MenuItem.config));

  void setMenu(MenuItem menu) {
    state.menu = menu;
    emit(state);
  }
}

import 'package:bloc/bloc.dart';

part 'menu_state.dart';

class MenuCubit extends Cubit<MenuState> {
  MenuCubit() : super(MenuState(MenuItem.home));

  void setMenu(MenuItem menu) {
    emit(MenuState(menu));
  }
}

import 'package:beat_cinema/Config/config_page.dart';
import 'package:beat_cinema/Menu/cubit/menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MenuCubit, MenuState>(
      builder: (context, state) {
        switch (state.menu) {
          case MenuItem.config:
            return const ConfigPage();
          default:
          return const ConfigPage();
        }
      },
    );
  }
}
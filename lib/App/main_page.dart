import 'package:beat_cinema/Modules/Config/config_page.dart';
import 'package:beat_cinema/Modules/CustomLevels/custom_levels_page.dart';
import 'package:beat_cinema/Modules/Menu/cubit/menu_cubit.dart';
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
          case MenuItem.home:
            return const CustomLevelsPage();
          default:
            return const ConfigPage();
        }
      },
    );
  }
}

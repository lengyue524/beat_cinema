import 'package:beat_cinema/Menu/cubit/menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextButton(onPressed: () {
          context.read<MenuCubit>().setMenu(MenuItem.config);
        }, child: const Text("Config"))
      ],
    );
  }
}
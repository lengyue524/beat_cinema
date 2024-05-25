import 'package:beat_cinema/App/main_page.dart';
import 'package:beat_cinema/Modules/Menu/cubit/menu_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text("BeatCinema"),
        ),
        // body: Expanded(child: MainPage()),
        body: BlocBuilder<MenuCubit, MenuState>(
          builder: (context, state) {
            return Row(
              children: [
                NavigationRail(
                  destinations: [
                    NavigationRailDestination(
                        icon: const Icon(Icons.home),
                        label: Text(
                          "Home",
                          style: Theme.of(context).textTheme.titleMedium,
                        )),
                    NavigationRailDestination(
                        icon: const Icon(Icons.settings),
                        label: Text(
                          "Home",
                          style: Theme.of(context).textTheme.titleMedium,
                        ))
                  ],
                  selectedIndex: state.menu.index,
                  onDestinationSelected: (value) {
                    context.read<MenuCubit>().setMenu(MenuItem.values[value]);
                  },
                ),
                const VerticalDivider(thickness: 1, width: 1),
                const Expanded(child: MainPage())
              ],
            );
          },
        )
        // drawer: MenuPage(),
        );
  }
}

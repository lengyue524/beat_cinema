import 'package:beat_cinema/App/main_page.dart';
import 'package:beat_cinema/Menu/menu_page.dart';
import 'package:flutter/material.dart';

class RootPage extends StatelessWidget {
  const RootPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("BeatCinema"),
      ),
      body: Expanded(child: MainPage()),
      drawer: MenuPage(),
    );
  }
}
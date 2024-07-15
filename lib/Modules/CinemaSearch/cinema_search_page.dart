import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher_string.dart';

class CinemaSearchPage extends StatelessWidget {
  const CinemaSearchPage({super.key, required this.levelInfo});
  final LevelInfo levelInfo;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CinemaSearchBloc(),
      child: BlocBuilder<CinemaSearchBloc, CinemaSearchState>(
        builder: (context, state) {
          final songName = levelInfo.customLevel.songName;
          if (state is CinemaSearchInitial &&
              songName != null &&
              songName.isNotEmpty) {
            context.read<CinemaSearchBloc>().add(
                CinameSearchTextEvent(songName, 20, context.read<AppBloc>()));
          }
          return Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.search),
                  Expanded(
                      child: TextField(
                    decoration:
                        const InputDecoration.collapsed(hintText: "Search..."),
                    onSubmitted: (value) {
                      context.read<CinemaSearchBloc>().add(
                          CinameSearchTextEvent(
                              value, 20, context.read<AppBloc>()));
                    },
                  )),
                  DropdownButton(
                      value: context.read<AppBloc>().cinemaSearchPlatform,
                      items: CinemaSearchPlatform.values
                          .map<DropdownMenuItem<CinemaSearchPlatform>>((e) {
                        return DropdownMenuItem<CinemaSearchPlatform>(
                          value: e,
                          child: Text(e.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        context
                            .read<AppBloc>()
                            .add(AppCinemaSearchPlatformUpdateEvent(value!));
                      }),
                ],
              ),
              Expanded(child: getContent(state)),
              // SearchAnchor(
              //   builder: (context, controller) {
              //     return SearchBar(
              //         padding: const WidgetStatePropertyAll<EdgeInsets>(
              //             EdgeInsets.symmetric(horizontal: 16.0)),
              //         controller: controller,
              //         leading: const Icon(Icons.search),
              //         onSubmitted: (value) {
              //           context.read<CinemaSearchBloc>().add(
              //               CinameSearchTextEvent(
              //                   value, 20, context.read<AppBloc>()));
              //         },
              //         onTap: () {
              //           controller.openView();
              //         },
              //       );
              //   },
              //   suggestionsBuilder: (context, controller) {
              //     if (state is CinemaSearchLoaded) {
              //       return List<ListTile>.generate(state.videoInfos.length,
              //           (index) {
              //         final thumb = state.videoInfos[index].thumbnail;
              //         final title = state.videoInfos[index].title;
              //         final url = state.videoInfos[index].originalUrl;
              //         return ListTile(
              //           title: Row(
              //             children: [
              //               Container(
              //                 width: 96,
              //                 height: 54,
              //                 padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              //                 child: thumb == null
              //                     ? Container(
              //                         color: const Color.fromARGB(
              //                             255, 248, 248, 248),
              //                       )
              //                     : Image.network(thumb),
              //               ),
              //               Expanded(
              //                   child: Text(
              //                 title ?? "",
              //                 style: Theme.of(context).textTheme.labelMedium,
              //               )),
              //               IconButton(
              //                   onPressed: () {
              //                     if (url != null) {
              //                       launchUrlString(url);
              //                     }
              //                   },
              //                   icon: const Icon(Icons.public))
              //             ],
              //           ),
              //         );
              //       });
              //     } else {
              //       return List<ListTile>.generate(0, (index) {
              //         return const ListTile(
              //           title: CircularProgressIndicator(),
              //         );
              //       });
              //     }
              //   },
              // ),
              // Expanded(child: Text("xxx"))
            ],
          );
        },
      ),
    );
  }

  Widget getContent(CinemaSearchState state) {
    if (state is CinemaSearchLoaded) {
      return ListView.builder(
          itemCount: state.videoInfos.length,
          itemBuilder: (context, index) {
            final thumb = state.videoInfos[index].thumbnail;
            final title = state.videoInfos[index].title;
            final url = state.videoInfos[index].originalUrl;
            return Row(
              children: [
                Container(
                  width: 96,
                  height: 54,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                  child: thumb == null
                      ? Container(
                          color: const Color.fromARGB(255, 248, 248, 248),
                        )
                      : Image.network(thumb),
                ),
                Expanded(
                    child: Text(
                  title ?? "",
                  style: Theme.of(context).textTheme.labelMedium,
                )),
                IconButton(
                    onPressed: () {
                      if (url != null) {
                        launchUrlString(url);
                      }
                    },
                    icon: const Icon(Icons.public))
              ],
            );
          });
    } else {
      return const Center(
        child: SizedBox(
          width: 36,
          height: 36,
          child: CircularProgressIndicator(),
        ),
      );
    }
  }
}

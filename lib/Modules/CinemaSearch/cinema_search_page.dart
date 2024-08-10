// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'package:beat_cinema/App/bloc/app_bloc.dart';
import 'package:beat_cinema/Modules/CinemaSearch/bloc/cinema_search_bloc.dart';
import 'package:beat_cinema/Modules/CustomLevels/level_info.dart';
import 'package:beat_cinema/Modules/Manager/cinema_download_manager.dart';

class CinemaSearchPage extends StatelessWidget {
  CinemaSearchPage({
    Key? key,
    required this.levelInfo,
  }) : super(key: key) {
    searchTextController =
        TextEditingController(text: levelInfo.customLevel.songName ?? "");
  }
  final LevelInfo levelInfo;
  late final TextEditingController searchTextController;
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
                  const SizedBox(
                      width: 48, height: 48, child: Icon(Icons.search)),
                  Expanded(
                      child: TextField(
                    controller: searchTextController,
                    decoration: InputDecoration.collapsed(
                        hintText: AppLocalizations.of(context)!.search_tips),
                    onSubmitted: (value) {
                      context.read<CinemaSearchBloc>().add(
                          CinameSearchTextEvent(
                              value, 20, context.read<AppBloc>()));
                    },
                  )),
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
            final videoInfo = state.videoInfos[index];
            final thumb = videoInfo.thumbnail;
            final title = videoInfo.title;
            final url = videoInfo.originalUrl;
            final duration = videoInfo.durationString ?? "00:00";
            final resolution = videoInfo.resolution ?? "unknow";
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 54,
                    child: thumb == null
                        ? Container(
                            color: const Color.fromARGB(255, 248, 248, 248),
                          )
                        : Image.network(thumb, fit: BoxFit.fill),
                  ),
                  Expanded(
                      child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title ?? "",
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Row(children: [
                              const Icon(Icons.timer, size: 12),
                              const SizedBox(width: 2),
                              Text(
                                duration,
                                style: Theme.of(context).textTheme.bodySmall,
                              )
                            ]),
                            const SizedBox(width: 8,),
                            Text(
                              resolution,
                              style: Theme.of(context).textTheme.bodySmall,
                              
                            ),
                          ],
                        )
                      ],
                    ),
                  )),
                  IconButton(
                      onPressed: () {
                        AppBloc appBloc = context.read<AppBloc>();
                        if (appBloc.beatSaberPath != null) {
                          CinemaDownloadManager().startCinimaDownload(
                              context,
                              appBloc.beatSaberPath!,
                              videoInfo,
                              levelInfo,
                              appBloc.cinemaVideoQuality);
                        }
                      },
                      icon: const Icon(Icons.download)),
                  IconButton(
                      onPressed: () {
                        if (url != null) {
                          launchUrlString(url);
                        }
                      },
                      icon: const Icon(Icons.public))
                ],
              ),
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

import 'package:media_kit/media_kit.dart';

class PlayerService {
  final List<Player> _activePlayers = [];

  Player createAudioPlayer() {
    final player = Player();
    _activePlayers.add(player);
    return player;
  }

  Player createVideoPlayer() {
    final player = Player();
    _activePlayers.add(player);
    return player;
  }

  Future<void> disposePlayer(Player player) async {
    await player.dispose();
    _activePlayers.remove(player);
  }

  Future<void> disposeAll() async {
    for (final player in List.from(_activePlayers)) {
      await player.dispose();
    }
    _activePlayers.clear();
  }
}

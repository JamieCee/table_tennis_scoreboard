import 'player.dart';
import 'set_score.dart';

class Game {
  final int order;
  final bool isDoubles;
  List<Player> homePlayers;
  List<Player> awayPlayers;
  List<SetScore> sets = [SetScore()];
  int setsWonHome = 0;
  int setsWonAway = 0;

  int homeGamesWon = 0;
  int awayGamesWon = 0;

  // For doubles: keep track of who starts serving each set
  Player? startingServer;
  Player? startingReceiver;

  Game({
    required this.order,
    required this.isDoubles,
    required this.homePlayers,
    required this.awayPlayers,
  });
}

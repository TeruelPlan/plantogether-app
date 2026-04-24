import '../../domain/model/destination_model.dart';
import '../../domain/model/vote_config_model.dart';

/// Pure scoring helpers for destination aggregates. Stateless.
class DestinationScoring {
  const DestinationScoring._();

  /// Returns the id(s) of the destination(s) with the leading score.
  /// Empty set if every aggregate is empty (no votes cast at all).
  static Set<String> leadingDestinationIds(
    List<DestinationModel> destinations,
    VoteMode mode,
  ) {
    if (destinations.isEmpty) return const {};

    switch (mode) {
      case VoteMode.simple:
      case VoteMode.approval:
        int maxVotes = 0;
        for (final d in destinations) {
          if (d.votes.totalVotes > maxVotes) maxVotes = d.votes.totalVotes;
        }
        if (maxVotes == 0) return const {};
        return {
          for (final d in destinations)
            if (d.votes.totalVotes == maxVotes) d.id,
        };
      case VoteMode.ranking:
        final withAvg = <String, double>{};
        for (final d in destinations) {
          final avg = averageRank(d.votes.rankVotes);
          if (avg != null) withAvg[d.id] = avg;
        }
        if (withAvg.isEmpty) return const {};
        final minAvg = withAvg.values.reduce((a, b) => a < b ? a : b);
        return {
          for (final e in withAvg.entries)
            if (e.value == minAvg) e.key,
        };
    }
  }

  /// Pre-formatted footer label per mode.
  static String aggregateLabel(DestinationVotesModel votes, VoteMode mode) {
    switch (mode) {
      case VoteMode.simple:
      case VoteMode.approval:
        final n = votes.totalVotes;
        if (n == 0) return 'No votes yet';
        if (n == 1) return '1 vote';
        return '$n votes';
      case VoteMode.ranking:
        final avg = averageRank(votes.rankVotes);
        if (avg == null) return 'Not yet ranked';
        return 'Avg rank: ${avg.toStringAsFixed(1)}';
    }
  }

  /// Average rank across voters. Keys are rank labels (serialized ints as
  /// strings); values are voter counts. Returns null if no voter ranked.
  static double? averageRank(Map<String, int> rankVotes) {
    if (rankVotes.isEmpty) return null;
    int weighted = 0;
    int count = 0;
    for (final entry in rankVotes.entries) {
      final rank = int.tryParse(entry.key);
      if (rank == null) continue;
      weighted += rank * entry.value;
      count += entry.value;
    }
    if (count == 0) return null;
    return weighted / count;
  }
}

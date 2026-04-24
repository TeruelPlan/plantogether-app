import 'package:flutter_test/flutter_test.dart';
import 'package:plantogether_app/features/destination/domain/model/destination_model.dart';
import 'package:plantogether_app/features/destination/domain/model/vote_config_model.dart';
import 'package:plantogether_app/features/destination/presentation/util/destination_scoring.dart';

DestinationModel _dest(String id, DestinationVotesModel votes) => DestinationModel(
      id: id,
      tripId: 'trip-1',
      name: id,
      proposedByDeviceId: 'device-1',
      createdAt: DateTime.utc(2026, 4, 1),
      updatedAt: DateTime.utc(2026, 4, 1),
      votes: votes,
    );

void main() {
  group('DestinationScoring.leadingDestinationIds — SIMPLE/APPROVAL', () {
    test('single winner returns only the top id', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel(totalVotes: 3)),
          _dest('b', const DestinationVotesModel(totalVotes: 1)),
          _dest('c', const DestinationVotesModel(totalVotes: 0)),
        ],
        VoteMode.simple,
      );
      expect(result, {'a'});
    });

    test('tie returns all tied ids', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel(totalVotes: 2)),
          _dest('b', const DestinationVotesModel(totalVotes: 2)),
          _dest('c', const DestinationVotesModel(totalVotes: 1)),
        ],
        VoteMode.approval,
      );
      expect(result, {'a', 'b'});
    });

    test('all zero votes returns empty set', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel(totalVotes: 0)),
          _dest('b', const DestinationVotesModel(totalVotes: 0)),
        ],
        VoteMode.simple,
      );
      expect(result, isEmpty);
    });
  });

  group('DestinationScoring.leadingDestinationIds — RANKING', () {
    test('lowest average rank wins', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel(rankVotes: {'1': 2, '2': 1})),
          _dest('b', const DestinationVotesModel(rankVotes: {'2': 3})),
        ],
        VoteMode.ranking,
      );
      // a: (1*2 + 2*1)/3 = 1.33; b: 2.0
      expect(result, {'a'});
    });

    test('tie returns all tied ids', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel(rankVotes: {'1': 1})),
          _dest('b', const DestinationVotesModel(rankVotes: {'1': 2})),
        ],
        VoteMode.ranking,
      );
      expect(result, {'a', 'b'});
    });

    test('destinations without ranked votes are skipped', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel()),
          _dest('b', const DestinationVotesModel(rankVotes: {'1': 1})),
        ],
        VoteMode.ranking,
      );
      expect(result, {'b'});
    });

    test('all empty returns empty set', () {
      final result = DestinationScoring.leadingDestinationIds(
        [
          _dest('a', const DestinationVotesModel()),
          _dest('b', const DestinationVotesModel()),
        ],
        VoteMode.ranking,
      );
      expect(result, isEmpty);
    });
  });

  group('DestinationScoring.aggregateLabel — SIMPLE/APPROVAL', () {
    test('formats zero as No votes yet', () {
      expect(
        DestinationScoring.aggregateLabel(
            const DestinationVotesModel(), VoteMode.simple),
        'No votes yet',
      );
    });

    test('formats 1 as singular', () {
      expect(
        DestinationScoring.aggregateLabel(
            const DestinationVotesModel(totalVotes: 1), VoteMode.approval),
        '1 vote',
      );
    });

    test('formats >1 as plural', () {
      expect(
        DestinationScoring.aggregateLabel(
            const DestinationVotesModel(totalVotes: 3), VoteMode.simple),
        '3 votes',
      );
    });
  });

  group('DestinationScoring.aggregateLabel — RANKING', () {
    test('formats average with one decimal', () {
      expect(
        DestinationScoring.aggregateLabel(
          const DestinationVotesModel(rankVotes: {'1': 2, '2': 1}),
          VoteMode.ranking,
        ),
        'Avg rank: 1.3',
      );
    });

    test('empty rankVotes returns Not yet ranked', () {
      expect(
        DestinationScoring.aggregateLabel(
            const DestinationVotesModel(), VoteMode.ranking),
        'Not yet ranked',
      );
    });
  });

  group('DestinationScoring.averageRank', () {
    test('returns null for empty', () {
      expect(DestinationScoring.averageRank(const {}), isNull);
    });

    test('computes weighted average', () {
      expect(
        DestinationScoring.averageRank(const {'1': 2, '3': 2}),
        closeTo(2.0, 1e-9),
      );
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../trip/domain/model/trip_model.dart';
import '../../../trip/presentation/bloc/current_member_cubit.dart';
import '../bloc/balance/balance_bloc.dart';
import '../bloc/balance/balance_event.dart';
import '../bloc/balance/balance_state.dart';
import '../widget/settlement_arrows_widget.dart';

/// Full-screen settlement view (story 5.4.1 / 5.4.2). Hosts the
/// [SettlementArrowsWidget] in its full-screen variant. Surfaces mark-done
/// failures as a SnackBar.
class SettlementPage extends StatelessWidget {
  final String tripId;
  final TripModel trip;

  const SettlementPage({super.key, required this.tripId, required this.trip});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        key: const ValueKey('settlement_app_bar'),
        title: const Text('Settlement'),
      ),
      body: BlocListener<BalanceBloc, BalanceState>(
        listenWhen: (_, current) =>
            current.maybeWhen(error: (_) => true, orElse: () => false),
        listener: (context, state) {
          state.whenOrNull(
            error: (message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  key: const ValueKey('settlement_error_snackbar'),
                  content: Text(message),
                ),
              );
            },
          );
        },
        child: RefreshIndicator(
          onRefresh: () async {
            context.read<BalanceBloc>().add(LoadBalance(tripId));
          },
          child: BlocBuilder<CurrentMemberCubit, CurrentMemberState>(
            builder: (context, memberState) {
              final myMemberId = memberState is CurrentMemberLoaded
                  ? memberState.member.tripMemberId
                  : null;
              return ListView(
                key: const ValueKey('settlement_scroll'),
                children: [
                  SettlementArrowsWidget(
                    trip: trip,
                    tripId: tripId,
                    myMemberId: myMemberId,
                    variant: SettlementVariant.fullScreen,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

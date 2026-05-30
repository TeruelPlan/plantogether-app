import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../domain/entity/balance.dart';
import '../bloc/balance/balance_bloc.dart';
import '../bloc/balance/balance_state.dart';

/// Header banner summarising the current member's net balance (story 5.4.1).
/// Tapping it invokes [onTap] (wired to open the full-screen settlement view).
class ExpenseBalanceBanner extends StatelessWidget {
  final String? myMemberId;
  final VoidCallback onTap;

  const ExpenseBalanceBanner({
    super.key,
    required this.myMemberId,
    required this.onTap,
  });

  static const _epsilon = 0.01;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<BalanceBloc, BalanceState>(
      builder: (context, state) {
        final balance = state.maybeWhen(
          loaded: (balance) => balance,
          orElse: () => null,
        );
        // Empty state (initial / loading / error): hide the banner entirely.
        if (balance == null) return const SizedBox.shrink();
        return _banner(context, balance);
      },
    );
  }

  double _net(Balance balance) {
    if (myMemberId == null) return 0;
    return balance.participantBalances[myMemberId] ?? 0;
  }

  Widget _banner(BuildContext context, Balance balance) {
    final theme = Theme.of(context);
    final net = _net(balance);
    final currency = balance.referenceCurrency;

    final Color background;
    final String text;
    if (balance.allSettled || net.abs() <= _epsilon) {
      background = theme.colorScheme.surface;
      text = "You're all settled ✓";
    } else if (net > _epsilon) {
      background = theme.colorScheme.tertiaryContainer;
      text = 'You are owed ${_format(net.abs(), currency)}';
    } else {
      background = theme.colorScheme.errorContainer.withValues(alpha: 0.5);
      text = 'You owe ${_format(net.abs(), currency)}';
    }

    return InkWell(
      key: const ValueKey('expense_balance_banner_inkwell'),
      onTap: onTap,
      child: Container(
        key: const ValueKey('expense_balance_banner'),
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }

  String _format(double amount, String currency) {
    return NumberFormat.currency(name: currency, symbol: currency)
        .format(amount);
  }
}

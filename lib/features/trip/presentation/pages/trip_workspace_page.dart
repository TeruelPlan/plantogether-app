import 'package:flutter/material.dart';

class TripWorkspacePage extends StatelessWidget {
  final String tripId;
  final String tripTitle;

  const TripWorkspacePage({
    super.key,
    required this.tripId,
    required this.tripTitle,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tripTitle),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Dates'),
              Tab(text: 'Destinations'),
              Tab(text: 'Expenses'),
              Tab(text: 'Tasks'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            Center(child: Text('Overview')),
            Center(child: Text('Dates')),
            Center(child: Text('Destinations')),
            Center(child: Text('Expenses')),
            Center(child: Text('Tasks')),
          ],
        ),
      ),
    );
  }
}

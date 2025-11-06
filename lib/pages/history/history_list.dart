import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/history/history_tile.dart';
import 'package:pakyaw/providers/combined_trips_provider.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:pakyaw/models/trip_models.dart';

class HistoryList extends ConsumerStatefulWidget {
  final String userID;
  final String filter;
  const HistoryList({
    super.key,
    required this.userID,
    required this.filter,
  });

  @override
  ConsumerState<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends ConsumerState<HistoryList> {
  final ScrollController controller = ScrollController();
  bool isLoadingMore = false;
  double draggedOffset = 0.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> displayFurtherDocs() async {
    draggedOffset = 0.0;
    setState(() {
      isLoadingMore = true;
    });
    await ref
        .read(combinedTripsProvider(widget.userID).notifier)
        .loadMore();
    setState(() {
      isLoadingMore = false;
    });
  }

  List<BaseTrip> filterTrips(List<BaseTrip> trips) {
    if (widget.filter == 'All') return trips;

    // Filter by trip type
    if (widget.filter == 'Pakyaw') {
      return trips.where((trip) => trip is PakyawTrip).toList();
    } else if (widget.filter == 'Carpool') {
      return trips.where((trip) => trip is CarpoolTrip).toList();
    }

    return trips;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double triggerRefreshDistance = SizeConfig.screenHeight * 0.50;
    final historyTrips = ref.watch(combinedTripsProvider(widget.userID));

    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels == notification.metrics.maxScrollExtent) {
          if (notification is OverscrollNotification) {
            // Add to the drag offset when overscrolling
            draggedOffset += notification.overscroll;

            // Check if the user has dragged more than the trigger threshold
            if (draggedOffset >= triggerRefreshDistance && !isLoadingMore) {
              displayFurtherDocs();  // Trigger the refresh
            }
          }
        }
        return true;
      },
      child: historyTrips.when(
        data: (data) {
          final filteredData = filterTrips(data);
          if (filteredData.isEmpty) {
            return _buildEmptyState();
          }
          return RefreshIndicator(
            onRefresh: () async {
              await ref
                  .read(combinedTripsProvider(widget.userID).notifier)
                  .refresh();
            },
            child: ListView.builder(
              controller: controller,
              itemCount: filteredData.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == filteredData.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                return HistoryTile(trip: filteredData[index]);
              },
            ),
          );
        },
        error: (e, stack) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    ref.invalidate(combinedTripsProvider(widget.userID));
                  },
                  child: const Text('Try again'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    String message;
    IconData icon;

    switch (widget.filter) {
      case 'Pakyaw':
        message = 'No Pakyaw trips yet';
        icon = Icons.local_taxi;
        break;
      case 'Carpool':
        message = 'No Carpool trips yet';
        icon = Icons.people;
        break;
      default:
        message = 'No trips yet';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your trip history will appear here',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
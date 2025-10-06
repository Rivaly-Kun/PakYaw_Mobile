import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/history/history_tile.dart';
import 'package:pakyaw/providers/history_trip_provider.dart';
import 'package:pakyaw/shared/error.dart';
import 'package:pakyaw/shared/loading.dart';
import 'package:pakyaw/shared/size_config.dart';

class HistoryList extends ConsumerStatefulWidget {
  final String userID;
  const HistoryList({super.key, required this.userID});

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
    await ref
        .read(tripsNotifierProvider(widget.userID).notifier)
        .loadMore(widget.userID);
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double triggerRefreshDistance = SizeConfig.screenHeight * 0.50;
    final historyTrips = ref.watch(tripsNotifierProvider(widget.userID));

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
          if (data.isEmpty) {
            return const Center(
              child: Text('No history trips found'),
            );
          }

          return ListView.builder(
            controller: controller,
            itemCount: data.length + (isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == data.length) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return HistoryTile(trip: data[index]);
            },
          );
        },
        error: (e, stack) {
          debugPrint(e.toString());
          debugPrint(stack.toString());
          return ErrorCatch(error: e.toString());
        },
        loading: () => const Loading(),
      ),
    );
  }
}
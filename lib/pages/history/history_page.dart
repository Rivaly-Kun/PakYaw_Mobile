import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/history/history_list.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/shared/size_config.dart';
import 'package:flutter/cupertino.dart';
import 'package:pakyaw/models/trip_models.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String selectedFilter = 'All';
  final List<Map<String, dynamic>> filterOptions = [
    {'label': 'All', 'icon': Icons.list_alt},
    {'label': 'Pakyaw', 'icon': Icons.local_taxi},
    {'label': 'Carpool', 'icon': Icons.people},
  ];

  void onFilterChanged(String filter) {
    setState(() {
      selectedFilter = filter;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAuth = ref.watch(authStateProvider).value;
    SizeConfig().init(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.history, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Trip History',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: filterOptions
                  .map((filter) => _buildFilterChip(
                filter['label'],
                filter['icon'],
                selectedFilter == filter['label'],
              ))
                  .toList(),
            ),
          ),
          Expanded(
            child: HistoryList(
              userID: userAuth!.uid,
              filter: selectedFilter,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, bool isSelected) {
    Color chipColor;
    if (label == 'Pakyaw') {
      chipColor = Colors.orange;
    } else if (label == 'Carpool') {
      chipColor = Colors.green;
    } else {
      chipColor = Colors.blue;
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        showCheckmark: false,
        avatar: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : chipColor,
        ),
        label: Text(label),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : chipColor,
          fontWeight: FontWeight.w600,
        ),
        onSelected: (_) => onFilterChanged(label),
        selectedColor: chipColor,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? chipColor : chipColor.withOpacity(0.3),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
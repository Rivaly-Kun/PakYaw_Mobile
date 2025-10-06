import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/pages/history/history_list.dart';
import 'package:pakyaw/providers/auth_provider.dart';
import 'package:pakyaw/shared/size_config.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    final userAuth = ref.watch(authStateProvider).value;
    SizeConfig().init(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Center(
          child: Text(
            'History',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: SizeConfig.safeBlockHorizontal * 5
            ),
          ),
        ),
      ),
      body: HistoryList(userID: userAuth!.uid,),
    );
  }
}

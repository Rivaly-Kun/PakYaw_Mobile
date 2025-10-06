import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pakyaw/shared/size_config.dart';

import '../providers/user_provider.dart';
import '../shared/error.dart';
import '../shared/loading.dart';

class BlockedScreen extends ConsumerStatefulWidget {
  const BlockedScreen({super.key});

  @override
  ConsumerState<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends ConsumerState<BlockedScreen> {
  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return ref.watch(usersProvider).when(
      data: (data){
        if(data != null){
          return Scaffold(
            body: SafeArea(
              child: Container(
                margin: EdgeInsets.only(top: SizeConfig.blockSizeVertical * 20),
                child: Center(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image(
                        image: const AssetImage('assets/block.png'),
                        height: SizeConfig.blockSizeVertical * 25,
                        width: SizeConfig.blockSizeHorizontal * 45,
                        fit: BoxFit.contain,
                      ),
                      Text(
                        'You have been Blocked!',
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 7,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      SizedBox(height: SizeConfig.blockSizeVertical * 1.5,),
                      Text(
                        'Reason:',
                        style: TextStyle(
                            fontSize: SizeConfig.safeBlockHorizontal * 6,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: SizeConfig.blockSizeHorizontal * 10),
                        child: Text(
                          data.reason,
                          style: TextStyle(
                              fontSize: SizeConfig.safeBlockHorizontal * 5,
                              fontWeight: FontWeight.bold
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }else{
          return const ErrorCatch(error: 'Error: User not found. please Try Again Later.');
        }
      },
      error: (error, stack) => ErrorCatch(error: '$error'),
      loading: () => const Loading(),);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/bloc/subscription/subscription_bloc.dart';
import 'package:table_tennis_scoreboard/theme.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SubscriptionBloc(),
      child: Scaffold(
        backgroundColor: const Color(0xff3E4249),
        appBar: AppBar(
          title: Text(
            'Digital TT Scoreboard',
            style: GoogleFonts.oswald(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.white,
            ),
          ),
          backgroundColor: AppColors.primaryBackground,
          leading: Builder(
            builder: (context) {
              return IconButton(
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
                icon: const Icon(Icons.menu),
              );
            },
          ),
        ),
        body: BlocListener<SubscriptionBloc, SubscriptionState>(
          listener: (context, state) {
            if (state is SubscriptionLaunchUrlFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: Colors.redAccent,
                  content: Text(state.errorMessage),
                ),
              );
            }
          },
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You currently do not have an active subscription. '
                    'To make use of this app and it\'s features, '
                    'please contact administration to subscribe.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.oswald(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 64),
                  ElevatedButton(
                    // 4. Dispatch the event to the BLoC on button press.
                    onPressed: () {
                      context.read<SubscriptionBloc>().add(
                        SubscribeButtonPressed(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purpleAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Subscribe",
                      style: GoogleFonts.oswald(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        drawer: const AppDrawer(),
      ),
    );

    // return Scaffold(
    //   backgroundColor: const Color(0xff3E4249),
    //   appBar: AppBar(
    //     title: Text(
    //       'TT Scoreboard',
    //       style: GoogleFonts.oswald(
    //         fontSize: 24,
    //         fontWeight: FontWeight.bold,
    //         color: AppColors.white,
    //       ),
    //     ),
    //     backgroundColor: AppColors.primaryBackground,
    //     leading: Builder(
    //       builder: (context) {
    //         return IconButton(
    //           icon: const Icon(Icons.menu),
    //           onPressed: () {
    //             Scaffold.of(context).openDrawer();
    //           },
    //         );
    //       },
    //     ),
    //   ),
    //   body: Center(
    //     child: Padding(
    //       padding: const EdgeInsets.all(16.0),
    //       child: Column(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           Text(
    //             'You currently do not have an active subscription. '
    //             'To make use of this app and it\'s features, '
    //             'please contact administration to subscribe.',
    //             textAlign: TextAlign.center,
    //             style: GoogleFonts.oswald(
    //               fontSize: 24,
    //               fontWeight: FontWeight.bold,
    //               color: AppColors.white,
    //             ),
    //           ),
    //           const SizedBox(height: 64),
    //           ElevatedButton(
    //             onPressed: _launcherSubscriptionURL,
    //             style: ElevatedButton.styleFrom(
    //               backgroundColor: AppColors.purpleAccent,
    //               padding: const EdgeInsets.symmetric(
    //                 horizontal: 40,
    //                 vertical: 18,
    //               ),
    //               shape: RoundedRectangleBorder(
    //                 borderRadius: BorderRadius.circular(16),
    //               ),
    //             ),
    //             child: Text(
    //               "Subscribe",
    //               style: GoogleFonts.oswald(
    //                 color: Colors.white,
    //                 fontSize: 22,
    //                 fontWeight: FontWeight.bold,
    //               ),
    //             ),
    //           ),
    //         ],
    //       ),
    //     ),
    //   ),
    //   drawer: const AppDrawer(),
    // );
  }
}

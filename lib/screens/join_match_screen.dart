import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/services/match_state_manager.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';

import '../bloc/join_match/join_match_bloc.dart';
import '../theme.dart';

class JoinMatchScreen extends StatelessWidget {
  final bool isWebObserver;
  const JoinMatchScreen({super.key, this.isWebObserver = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          JoinMatchBloc(matchStateManager: context.read<MatchStateManager>()),
      child: Scaffold(
        backgroundColor: AppColors.charcoal,
        appBar: AppBar(
          automaticallyImplyLeading: !isWebObserver,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text("Join as Observer"),
        ),
        // The actual UI is now in a separate widget below.
        body: const _JoinMatchForm(),
        drawer: const AppDrawer(),
      ),
    );
  }
}

class _JoinMatchForm extends StatefulWidget {
  const _JoinMatchForm();

  @override
  State<_JoinMatchForm> createState() => __JoinMatchFormState();
}

class __JoinMatchFormState extends State<_JoinMatchForm> {
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _dispatchJoinEvent() {
    // This context is from _JoinMatchForm, which is UNDER the BlocProvider, so this works.
    context.read<JoinMatchBloc>().add(
      JoinMatchRequested(matchId: _codeController.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // This build method's context is a descendant of the BlocProvider, so it can find the BLoC.
    return BlocConsumer<JoinMatchBloc, JoinMatchState>(
      listener: (context, state) {
        if (state is JoinMatchSuccess) {
          context.pushReplacement(
            '/controller/scoreboard',
            extra: state.matchBloc,
          );
        }
        if (state is JoinMatchFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(state.error),
                backgroundColor: Colors.redAccent,
              ),
            );
        }
      },
      builder: (context, state) {
        final isLoading = state is JoinMatchLoading;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: "Enter game code",
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withAlpha(13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.blueAccent.shade200),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: isLoading ? null : _dispatchJoinEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Join Match",
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontSize: 22,
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

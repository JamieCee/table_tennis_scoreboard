import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_tennis_scoreboard/services/auth_manager.dart';
import 'package:table_tennis_scoreboard/shared/styled_text.dart';
import 'package:table_tennis_scoreboard/widgets/app_drawer.dart';
import 'package:table_tennis_scoreboard/widgets/subscription_banner.dart';

import '../bloc/auth/auth_bloc.dart';
import '../theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthBloc(authManager: context.read<AuthManager>()),
      child: const Scaffold(
        backgroundColor: Color(0xff3E4249),
        drawer: AppDrawer(),
        // The LoginForm is now the direct child and will get a context
        // that knows about the AuthBloc.
        body: LoginForm(),
      ),
    );
  }
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() {
    if (!_formKey.currentState!.validate()) return;

    // Dispatch the event to the Bloc
    context.read<AuthBloc>().add(
      LoginRequested(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This is a robust pattern to ensure the listener and builders
    // all have access to the bloc without any context ambiguity.
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // The main UI is built here.
        // Now, we'll wrap this UI with the listener.
        return BlocListener<AuthBloc, AuthState>(
          listener: (context, listenState) {
            // Use a different name for the state to avoid confusion
            if (listenState is AuthSuccess) {
              context.go('/home');
            } else if (listenState is AuthNotSubscribed) {
              context.go('/subscribe');
            } else if (listenState is AuthFailure) {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(listenState.error),
                    backgroundColor: Colors.red,
                  ),
                );
            }
          },
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // This part can use the 'state' from the BlocBuilder
                    if (state is AuthNotSubscribed)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 24.0),
                        child: SubscriptionBanner(),
                      )
                    else
                      const SizedBox.shrink(),

                    Icon(
                      Icons.sports_tennis,
                      color: AppColors.purpleAccent,
                      size: 100,
                    ),
                    const SizedBox(height: 40),
                    const StyledHeading('Sign In'),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email..',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter an email'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password..',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter a password'
                          : null,
                    ),
                    const SizedBox(height: 24),
                    // This button also uses the 'state' from the outer BlocBuilder
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: state is AuthLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.purpleAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                "Login",
                                style: GoogleFonts.oswald(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: TextButton(
                        onPressed: () => context.go('/join-match'),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.midnightBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          "Join as Spectator",
                          style: GoogleFonts.oswald(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

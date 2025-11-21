import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/design_tokens.dart';
import '../cubit/auth_cubit.dart';
import '../states/auth_state.dart';

/// Login page for Google Sign-In authentication.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppGradients.appBar(cs),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.l),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Logo/Icon
                  Icon(
                    Icons.track_changes,
                    size: 80,
                    color: cs.onPrimary,
                  ),
                  const SizedBox(height: AppSpacing.l),
                  
                  // App Title
                  Text(
                    'All Tracker',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.s),
                  
                  // Subtitle
                  Text(
                    'Your productivity hub',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: cs.onPrimary.withOpacity(0.9),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.l * 2),
                  
                  // Login Card
                  Card(
                    elevation: AppElevations.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.l),
                      child: BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Sign in message
                              Text(
                                'Sign in to continue',
                                style: Theme.of(context).textTheme.titleLarge,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: AppSpacing.m),
                              
                              // Error message
                              if (state is AuthError) ...[
                                Container(
                                  padding: const EdgeInsets.all(AppSpacing.s),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer,
                                    borderRadius: BorderRadius.circular(AppRadii.chip),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: cs.onErrorContainer,
                                        size: 20,
                                      ),
                                      const SizedBox(width: AppSpacing.s),
                                      Expanded(
                                        child: Text(
                                          state.message,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: cs.onErrorContainer,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.m),
                              ],
                              
                              // Loading indicator or Sign in button
                              if (state is AuthLoading)
                                const Padding(
                                  padding: EdgeInsets.all(AppSpacing.m),
                                  child: CircularProgressIndicator(),
                                )
                              else
                                ElevatedButton.icon(
                                  onPressed: () {
                                    context.read<AuthCubit>().signIn();
                                  },
                                  icon: const Icon(Icons.login),
                                  label: const Text('Sign in with Google'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 56),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.l,
                                      vertical: AppSpacing.m,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.l),
                  
                  // Info text
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
                    child: Text(
                      'Sign in with your Google account to access all features and sync your data securely.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onPrimary.withOpacity(0.8),
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/password.dart';
import '../bloc/password_cubit.dart';
import '../bloc/password_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/password_list_item.dart';
import '../widgets/password_form_bottom_sheet.dart';
import 'password_detail_page.dart';

class PasswordListPage extends StatelessWidget {
  const PasswordListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createPasswordCubit();
        cubit.loadPasswords();
        return cubit;
      },
      child: const PasswordListPageView(),
    );
  }
}

class PasswordListPageView extends StatelessWidget {
  const PasswordListPageView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PasswordCubit>();

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Password Tracker',
        actions: [
          IconButton(
            tooltip: 'Home Page',
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlocBuilder<PasswordCubit, PasswordState>(
          builder: (context, state) {
            if (state is PasswordsLoading) {
              return const LoadingView();
            }

            if (state is PasswordsLoaded) {
              final passwords = state.passwords;

              if (passwords.isEmpty) {
                return const Center(
                  child: Text('No passwords yet. Tap + to add one.'),
                );
              }

              return ListView.builder(
                itemCount: passwords.length,
                itemBuilder: (context, index) {
                  final password = passwords[index];
                  return PasswordListItem(
                    password: password,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PasswordDetailPage(passwordId: password.id),
                        ),
                      );
                    },
                  );
                },
              );
            }

            if (state is PasswordsError) {
              return ErrorView(
                message: state.message,
                onRetry: () => cubit.loadPasswords(),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPasswordForm(context, cubit),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPasswordForm(BuildContext context, PasswordCubit cubit, {Password? password}) {
    PasswordFormBottomSheet.show(
      context,
      password: password,
      onSubmit: (siteName, url, username, passwordText, isGoogleSignIn, is2FA, categoryGroup, hasSecretQuestions) async {
        if (password != null) {
          // Update existing
          final updated = password.copyWith(
            siteName: siteName,
            url: url,
            username: username,
            password: passwordText,
            isGoogleSignIn: isGoogleSignIn,
            is2FA: is2FA,
            categoryGroup: categoryGroup,
            hasSecretQuestions: hasSecretQuestions,
            lastUpdated: DateTime.now(),
          );
          await cubit.updatePassword(updated);
        } else {
          // Create new
          await cubit.createPassword(
            siteName: siteName,
            url: url,
            username: username,
            password: passwordText,
            isGoogleSignIn: isGoogleSignIn,
            is2FA: is2FA,
            categoryGroup: categoryGroup,
            hasSecretQuestions: hasSecretQuestions,
          );
        }
      },
      onDelete: password != null
          ? () async {
              await cubit.deletePassword(password.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          : null,
      title: password != null ? 'Edit Password' : 'Create Password',
    );
  }

}


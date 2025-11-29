import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/password.dart';
import '../../domain/entities/secret_question.dart';
import '../bloc/password_cubit.dart';
import '../bloc/secret_question_cubit.dart';
import '../bloc/secret_question_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/password_form_bottom_sheet.dart';
import '../widgets/secret_question_list_item.dart';
import '../widgets/secret_question_form_bottom_sheet.dart';

class PasswordDetailPage extends StatelessWidget {
  final String passwordId;

  const PasswordDetailPage({super.key, required this.passwordId});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) {
            final cubit = createPasswordCubit();
            cubit.loadPasswords();
            return cubit;
          },
        ),
        BlocProvider(
          create: (_) => createSecretQuestionCubit(),
        ),
      ],
      child: PasswordDetailPageView(passwordId: passwordId),
    );
  }
}

class PasswordDetailPageView extends StatefulWidget {
  final String passwordId;

  const PasswordDetailPageView({super.key, required this.passwordId});

  @override
  State<PasswordDetailPageView> createState() => _PasswordDetailPageViewState();
}

class _PasswordDetailPageViewState extends State<PasswordDetailPageView> {
  bool _isPasswordVisible = false;
  bool _secretQuestionsLoaded = false;

  @override
  void initState() {
    super.initState();
  }

  void _copyPasswordToClipboard(String password) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Password copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordCubit = context.read<PasswordCubit>();
    final secretQuestionCubit = context.read<SecretQuestionCubit>();

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Password Details',
        actions: [
          FutureBuilder<Password?>(
            future: passwordCubit.getPasswordById(widget.passwordId),
            builder: (context, snapshot) {
              if (snapshot.hasData && snapshot.data != null) {
                final password = snapshot.data!;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit',
                      onPressed: () => _showPasswordForm(context, passwordCubit, password: password),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, passwordCubit, password),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: FutureBuilder<Password?>(
        future: passwordCubit.getPasswordById(widget.passwordId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }

          if (snapshot.hasError || snapshot.data == null) {
            return ErrorView(
              message: 'Failed to load password',
              onRetry: () {
                setState(() {});
              },
            );
          }

          final password = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(label: 'Site Name', value: password.siteName),
                if (password.url != null) _DetailRow(label: 'URL', value: password.url!),
                if (password.username != null) _DetailRow(label: 'Username', value: password.username!),
                if (password.password != null && password.password!.isNotEmpty)
                  _PasswordDetailRow(
                    label: 'Password',
                    value: password.password!,
                    isVisible: _isPasswordVisible,
                    onToggleVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    onCopy: () => _copyPasswordToClipboard(password.password!),
                  ),
                _DetailRow(label: 'Google Sign-In', value: password.isGoogleSignIn ? 'Yes' : 'No'),
                _DetailRow(label: '2FA Enabled', value: password.is2FA ? 'Yes' : 'No'),
                if (password.categoryGroup != null)
                  _DetailRow(label: 'Category', value: password.categoryGroup!),
                _DetailRow(
                  label: 'Last Updated',
                  value: password.lastUpdated.toString().split('.')[0],
                ),
                if (password.hasSecretQuestions) ...[
                  const SizedBox(height: 24),
                  // Secret Questions Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Secret Questions',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () => _showSecretQuestionForm(context, secretQuestionCubit, password.id),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<SecretQuestionCubit, SecretQuestionState>(
                    builder: (context, state) {
                      // Load secret questions once when section is first displayed
                      if (!_secretQuestionsLoaded) {
                        _secretQuestionsLoaded = true;
                        // Load immediately, not in post frame callback
                        secretQuestionCubit.loadSecretQuestions(password.id);
                      }

                      if (state is SecretQuestionsLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (state is SecretQuestionsLoaded) {
                        final secretQuestions = state.secretQuestions;

                        if (secretQuestions.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text('No secret questions yet. Tap + to add one.'),
                          );
                        }

                        return Column(
                          children: secretQuestions.map((sq) {
                            return SecretQuestionListItem(
                              secretQuestion: sq,
                              onTap: () => _showSecretQuestionForm(
                                context,
                                secretQuestionCubit,
                                password.id,
                                secretQuestion: sq,
                              ),
                            );
                          }).toList(),
                        );
                      }

                      if (state is SecretQuestionsError) {
                        return Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text('Error: ${state.message}'),
                        );
                      }

                      return const SizedBox.shrink();
                    },
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPasswordForm(BuildContext context, PasswordCubit cubit, {required Password password}) {
    PasswordFormBottomSheet.show(
      context,
      password: password,
      onSubmit: (siteName, url, username, passwordText, isGoogleSignIn, is2FA, categoryGroup, hasSecretQuestions) async {
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
        if (context.mounted) {
          setState(() {});
        }
      },
      onDelete: () async {
        await cubit.deletePassword(password.id);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      title: 'Edit Password',
    );
  }

  void _confirmDelete(BuildContext context, PasswordCubit cubit, Password password) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Password'),
        content: Text('Are you sure you want to delete "${password.siteName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              cubit.deletePassword(password.id);
              Navigator.of(context).pop();
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSecretQuestionForm(
    BuildContext context,
    SecretQuestionCubit cubit,
    String passwordId, {
    SecretQuestion? secretQuestion,
  }) {
    SecretQuestionFormBottomSheet.show(
      context,
      secretQuestion: secretQuestion,
      passwordId: passwordId,
      onSubmit: (question, answer) async {
        if (secretQuestion != null) {
          // Update existing
          final updated = SecretQuestion(
            id: secretQuestion.id,
            passwordId: passwordId,
            question: question,
            answer: answer,
          );
          await cubit.updateSecretQuestion(updated);
        } else {
          // Create new
          await cubit.createSecretQuestion(
            passwordId: passwordId,
            question: question,
            answer: answer,
          );
        }
      },
      onDelete: secretQuestion != null
          ? () async {
              await cubit.deleteSecretQuestion(secretQuestion.id, passwordId);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            }
          : null,
      title: secretQuestion != null ? 'Edit Secret Question' : 'Create Secret Question',
    );
  }

}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PasswordDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isVisible;
  final VoidCallback onToggleVisibility;
  final VoidCallback? onCopy;

  const _PasswordDetailRow({
    required this.label,
    required this.value,
    required this.isVisible,
    required this.onToggleVisibility,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Expanded(
            child: Text(
              !isVisible ? '••••••••' : value,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(isVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: onToggleVisibility,
                tooltip: isVisible ? 'Hide password' : 'Show password',
                iconSize: 20,
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: onCopy,
                  tooltip: 'Copy password',
                  iconSize: 20,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

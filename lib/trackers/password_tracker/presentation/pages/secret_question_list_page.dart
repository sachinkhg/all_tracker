import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/secret_question.dart';
import '../bloc/secret_question_cubit.dart';
import '../bloc/secret_question_state.dart';
import '../../core/injection.dart';
import '../../../../widgets/primary_app_bar.dart';
import '../../../../widgets/loading_view.dart';
import '../../../../widgets/error_view.dart';
import '../widgets/secret_question_list_item.dart';
import '../widgets/secret_question_form_bottom_sheet.dart';

class SecretQuestionListPage extends StatelessWidget {
  final String passwordId;

  const SecretQuestionListPage({super.key, required this.passwordId});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = createSecretQuestionCubit();
        cubit.loadSecretQuestions(passwordId);
        return cubit;
      },
      child: SecretQuestionListPageView(passwordId: passwordId),
    );
  }
}

class SecretQuestionListPageView extends StatelessWidget {
  final String passwordId;

  const SecretQuestionListPageView({super.key, required this.passwordId});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SecretQuestionCubit>();

    return Scaffold(
      appBar: PrimaryAppBar(
        title: 'Secret Questions/Other Details',
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: BlocBuilder<SecretQuestionCubit, SecretQuestionState>(
          builder: (context, state) {
            if (state is SecretQuestionsLoading) {
              return const LoadingView();
            }

            if (state is SecretQuestionsLoaded) {
              final secretQuestions = state.secretQuestions;

              if (secretQuestions.isEmpty) {
                return const Center(
                  child: Text('No secret questions/other details yet. Tap + to add one.'),
                );
              }

              return ListView.builder(
                itemCount: secretQuestions.length,
                itemBuilder: (context, index) {
                  final secretQuestion = secretQuestions[index];
                  return SecretQuestionListItem(
                    secretQuestion: secretQuestion,
                    onTap: () {
                      _showSecretQuestionForm(context, cubit, passwordId, secretQuestion: secretQuestion);
                    },
                  );
                },
              );
            }

            if (state is SecretQuestionsError) {
              return ErrorView(
                message: state.message,
                onRetry: () => cubit.loadSecretQuestions(passwordId),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showSecretQuestionForm(context, cubit, passwordId),
        child: const Icon(Icons.add),
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
      title: secretQuestion != null ? 'Edit Secret Question/Other Details' : 'Create Secret Question/Other Details',
    );
  }

}


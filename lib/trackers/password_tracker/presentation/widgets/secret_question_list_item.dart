import 'package:flutter/material.dart';
import '../../domain/entities/secret_question.dart';

class SecretQuestionListItem extends StatelessWidget {
  final SecretQuestion secretQuestion;
  final VoidCallback onTap;

  const SecretQuestionListItem({
    super.key,
    required this.secretQuestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: ListTile(
        leading: const Icon(Icons.help_outline),
        title: Text(secretQuestion.question),
        subtitle: const Text('Answer: ••••••••'),
        onTap: onTap,
      ),
    );
  }
}


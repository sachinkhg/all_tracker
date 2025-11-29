import 'package:flutter/material.dart';
import '../../domain/entities/secret_question.dart';

class SecretQuestionFormBottomSheet extends StatefulWidget {
  final SecretQuestion? secretQuestion;
  final String passwordId;
  final Future<void> Function(String question, String answer) onSubmit;
  final Future<void> Function()? onDelete;
  final String title;

  const SecretQuestionFormBottomSheet({
    super.key,
    this.secretQuestion,
    required this.passwordId,
    required this.onSubmit,
    this.onDelete,
    required this.title,
  });

  static Future<void> show(
    BuildContext context, {
    SecretQuestion? secretQuestion,
    required String passwordId,
    required Future<void> Function(String question, String answer) onSubmit,
    Future<void> Function()? onDelete,
    String title = 'Create Secret Question',
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SecretQuestionFormBottomSheet(
          secretQuestion: secretQuestion,
          passwordId: passwordId,
          onSubmit: onSubmit,
          onDelete: onDelete,
          title: title,
        );
      },
    );
  }

  @override
  State<SecretQuestionFormBottomSheet> createState() => _SecretQuestionFormBottomSheetState();
}

class _SecretQuestionFormBottomSheetState extends State<SecretQuestionFormBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final TextEditingController _answerController;
  bool _obscureAnswer = true;

  @override
  void initState() {
    super.initState();
    _questionController = TextEditingController(text: widget.secretQuestion?.question ?? '');
    _answerController = TextEditingController(text: widget.secretQuestion?.answer ?? '');
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      await widget.onSubmit(
        _questionController.text.trim(),
        _answerController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          await widget.onDelete!();
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _questionController,
                  decoration: const InputDecoration(
                    labelText: 'Question *',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Question is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _answerController,
                  decoration: InputDecoration(
                    labelText: 'Answer *',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureAnswer ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _obscureAnswer = !_obscureAnswer;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureAnswer,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Answer is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleSubmit,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


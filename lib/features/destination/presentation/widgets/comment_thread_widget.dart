import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/model/comment_model.dart';
import '../bloc/destination_comment_bloc.dart';
import '../bloc/destination_comment_event.dart';
import '../bloc/destination_comment_state.dart';
import 'comment_tile.dart';

class CommentThreadWidget extends StatefulWidget {
  final String destinationId;

  const CommentThreadWidget({super.key, required this.destinationId});

  @override
  State<CommentThreadWidget> createState() => _CommentThreadWidgetState();
}

class _CommentThreadWidgetState extends State<CommentThreadWidget> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  String _helperText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    final bloc = context.read<DestinationCommentBloc>();
    bloc.state.maybeWhen(
      initial: () => bloc.add(LoadComments(widget.destinationId)),
      orElse: () {},
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _helperText = 'Comment cannot be empty');
      return;
    }
    if (text.length > 2000) {
      setState(() => _helperText = 'Comment must be at most 2000 characters');
      return;
    }
    setState(() => _helperText = '');
    context
        .read<DestinationCommentBloc>()
        .add(AddComment(widget.destinationId, text));
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DestinationCommentBloc, DestinationCommentState>(
      listenWhen: (prev, curr) {
        final wasSubmitting = prev.maybeWhen(
          loaded: (_, submitting, __) => submitting,
          orElse: () => false,
        );
        final nowFinished = curr.maybeWhen(
          loaded: (_, submitting, error) => !submitting && error == null,
          orElse: () => false,
        );
        return wasSubmitting && nowFinished;
      },
      listener: (context, state) {
        _controller.clear();
      },
      builder: (context, state) {
        return state.when(
          initial: () => const SizedBox.shrink(),
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                key: ValueKey('comment_thread_loading'),
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          loaded: (comments, submitting, submitError) =>
              _buildLoaded(context, comments, submitting, submitError),
          error: (message) => Padding(
            padding: const EdgeInsets.all(12.0),
            child: Text(
              message,
              key: const ValueKey('comment_thread_error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoaded(
    BuildContext context,
    List<CommentModel> comments,
    bool submitting,
    String? submitError,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (comments.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'No comments yet · Be the first to share your thoughts',
              key: ValueKey('comment_thread_empty_state'),
              textAlign: TextAlign.center,
            ),
          )
        else
          ListView.separated(
            key: ValueKey(
              'comment_thread_list_${widget.destinationId}',
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: comments.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) =>
                CommentTile(comment: comments[index]),
          ),
        if (submitError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              submitError,
              key: const ValueKey('comment_thread_submit_error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const ValueKey('comment_input_field'),
                controller: _controller,
                focusNode: _focusNode,
                maxLength: 2000,
                enabled: !submitting,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Write a comment…',
                  helperText: _helperText.isEmpty ? null : _helperText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              key: const ValueKey('comment_send_button'),
              onPressed: submitting ? null : _submit,
              icon: submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

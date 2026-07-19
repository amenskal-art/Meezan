import 'package:flutter/material.dart';

import '../../core/models.dart';
import '../../core/services/gemini_service.dart';
import '../../core/theme.dart';
import '../../core/ui_helpers.dart';

/// Role-aware Gemini chat. The SAME widget serves both roles because the
/// intelligence lives server-side: the geminiChat Cloud Function reads the
/// caller's role from Firestore and applies the matching system prompt.
///   Client -> "Legal Assistant AI"  (Iraqi legal FAQs, app guidance,
///             specialization matching)
///   Lawyer -> "Co-Counsel AI"       (brief summarization, document analysis,
///             contract drafting under Iraqi statutes)
/// Lawyers additionally get an "attach document text" sheet whose content is
/// forwarded as `documentText` for analysis.
class ChatScreen extends StatefulWidget {
  final AppUser user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _input = TextEditingController();
  final _scroll = ScrollController();
  String _docText = '';
  bool _busy = false;

  bool get _isLawyer => widget.user.isApprovedLawyer;

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _busy) return;
    setState(() {
      _messages.add(ChatMessage('user', text));
      _input.clear();
      _busy = true;
    });
    _jump();
    try {
      final reply =
          await GeminiService.send(_messages, documentText: _docText);
      setState(() {
        _messages.add(ChatMessage('model', reply));
        _docText = ''; // document is consumed by one exchange
      });
    } catch (_) {
      if (mounted) {
        setState(() =>
            _messages.add(ChatMessage('model', tr(context).error)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      _jump();
    }
  }

  void _jump() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  Future<void> _attachText() async {
    final t = tr(context);
    final ctrl = TextEditingController(text: _docText);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(t.pasteDocumentHint,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextField(
            controller: ctrl,
            maxLines: 8,
            decoration: const InputDecoration(hintText: '...'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () {
              setState(() => _docText = ctrl.text.trim());
              Navigator.of(sheetCtx).pop();
            },
            child: Text(t.save),
          ),
        ]),
      ),
    );
  }

  Widget _bubble(ChatMessage m) {
    final isUser = m.role == 'user';
    return Align(
      alignment:
          isUser ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: isUser ? MeezanTheme.navy : Colors.white,
          borderRadius: BorderRadiusDirectional.only(
            topStart: const Radius.circular(16),
            topEnd: const Radius.circular(16),
            bottomStart: Radius.circular(isUser ? 16 : 4),
            bottomEnd: Radius.circular(isUser ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2)),
          ],
        ),
        child: SelectableText(m.text,
            style: TextStyle(
                color: isUser ? Colors.white : Colors.black87, height: 1.4)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = tr(context);
    return Column(children: [
      Expanded(
        child: ListView(
          controller: _scroll,
          padding: const EdgeInsets.symmetric(vertical: 12),
          children: [
            // Role-aware intro bubble
            _bubble(ChatMessage(
                'model', _isLawyer ? t.aiLawyerIntro : t.aiClientIntro)),
            for (final m in _messages) _bubble(m),
            if (_busy)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Row(children: [
                  SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: MeezanTheme.gold)),
                ]),
              ),
          ],
        ),
      ),
      if (_docText.isNotEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Chip(
              avatar: const Icon(Icons.attach_file, size: 16),
              label: Text(t.attachText),
              onDeleted: () => setState(() => _docText = ''),
            ),
          ),
        ),
      SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
          child: Row(children: [
            if (_isLawyer)
              IconButton(
                onPressed: _attachText,
                icon: const Icon(Icons.attach_file),
                tooltip: t.attachText,
              ),
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: t.typeMessage,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            FloatingActionButton.small(
              onPressed: _busy ? null : _send,
              child: const Icon(Icons.send),
            ),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(t.aiDisclaimer,
            style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
      ),
    ]);
  }
}

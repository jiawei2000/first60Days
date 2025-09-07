import 'package:flutter/material.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _scrollCtrl = ScrollController();
  final _inputCtrl = TextEditingController();

  final List<_Msg> _messages = [
    _Msg(text: 'Hello Amanda, how can I assist you today?', isMe: false),
    _Msg(text: 'Baby Chloe is not sleeping', isMe: true, style: _MsgStyle.chip),
  ];

  bool _trainerTyping = false;

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(),
        titleSpacing: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://i.pravatar.cc/80?img=5',
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Elaine Lee', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                Row(
                  children: [
                    Text('Trainer', style: TextStyle(fontSize: 12, color: Colors.black54)),
                    SizedBox(width: 6),
                    Icon(Icons.circle, size: 8, color: Colors.green),
                    SizedBox(width: 4),
                    Text('Online', style: TextStyle(fontSize: 12, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ],
        ),
        centerTitle: false,
      ),

      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                itemCount: _messages.length + (_trainerTyping ? 1 : 0),
                itemBuilder: (context, i) {
                  if (_trainerTyping && i == _messages.length) {
                    return _TypingBubble(isMe: false);
                  }
                  final m = _messages[i];
                  return Align(
                    alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
                    child: _Bubble(msg: m),
                  );
                },
              ),
            ),

            // Input bar
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, bottomInset + 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF2F3F5),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      alignment: Alignment.centerLeft,
                      child: TextField(
                        controller: _inputCtrl,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Type a message…',
                        ),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 44,
                    width: 44,
                    child: Material(
                      color: const Color(0xFF2F80ED),
                      borderRadius: BorderRadius.circular(22),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(22),
                        onTap: _send,
                        child: const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send() {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(_Msg(text: text, isMe: true));
      _inputCtrl.clear();
    });
    _scrollToEnd();

    // Fake "trainer typing…" then reply
    setState(() => _trainerTyping = true);
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _trainerTyping = false;
        _messages.add(_Msg(
          text: 'Thanks for sharing. When was her last feed?',
          isMe: false,
        ));
      });
      _scrollToEnd();
    });
  }

  void _scrollToEnd() {
    // schedule after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollCtrl.animateTo(
        _scrollCtrl.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }
}

// --- Models & UI bits ---

enum _MsgStyle { normal, chip }

class _Msg {
  final String text;
  final bool isMe;
  final _MsgStyle style;
  _Msg({required this.text, required this.isMe, this.style = _MsgStyle.normal});
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.msg, super.key});
  final _Msg msg;

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;
    final isChip = msg.style == _MsgStyle.chip;

    // Colors per mock
    final trainerBlue = const Color(0xFF2F80ED);
    final userChip = const Color(0xFFE6F0FF);

    final bg = isMe
        ? (isChip ? userChip : userChip) // you can darken for user if desired
        : trainerBlue;
    final fg = isMe ? Colors.black87 : Colors.white;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMe ? 16 : 4),
      bottomRight: Radius.circular(isMe ? 4 : 16),
    );

    final padding = EdgeInsets.symmetric(
      horizontal: isChip ? 12 : 14,
      vertical: isChip ? 8 : 10,
    );

    return Container(
      margin: EdgeInsets.fromLTRB(isMe ? 64 : 12, 8, isMe ? 12 : 64, 4),
      padding: padding,
      decoration: BoxDecoration(color: bg, borderRadius: radius),
      child: Text(
        msg.text,
        style: TextStyle(color: fg, fontSize: 15),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({required this.isMe, super.key});
  final bool isMe;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))
        ..repeat();
  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMe = widget.isMe;
    final trainerBlue = const Color(0xFF2F80ED);
    final bg = isMe ? const Color(0xFFE6F0FF) : trainerBlue;
    final dot = isMe ? Colors.black54 : Colors.white;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.fromLTRB(isMe ? 64 : 12, 8, isMe ? 12 : 64, 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration:
            BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: AnimatedBuilder(
          animation: _ac,
          builder: (_, __) {
            final v = (1 + (0.6 * (1 + (0.5 * (1 + _ac.value))))); // just wiggle
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(dot, 1.0 + _ac.value * 0.6),
                const SizedBox(width: 4),
                _dot(dot, v),
                const SizedBox(width: 4),
                _dot(dot, 1.0 + (1 - _ac.value) * 0.6),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _dot(Color c, double scale) => Transform.scale(
        scale: scale,
        child: Icon(Icons.circle, size: 6, color: c),
      );
}

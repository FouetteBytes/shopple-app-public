import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:stream_chat_flutter/stream_chat_flutter.dart';
import 'package:get/get.dart';

import '../../../controllers/chat/chat_management_controller.dart';
import '../../../controllers/chat/chat_session_controller.dart';
import '../../../screens/chat/chat_conversation_screen.dart';
import '../../common/liquid_glass.dart';

class MiniChatSheet extends StatefulWidget {
  final String userId;
  const MiniChatSheet({super.key, required this.userId});

  static void show(BuildContext context, {required String userId}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MiniChatSheet(userId: userId),
    );
  }

  @override
  State<MiniChatSheet> createState() => _MiniChatSheetState();
}

class _MiniChatSheetState extends State<MiniChatSheet> {
  Channel? _channel;
  bool _loading = true;
  String? _error;
  late final StreamMessageInputController _messageController;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _messageController = StreamMessageInputController();
    _initChat();
  }

  Future<void> _initChat() async {
    try {
      // Ensure chat session is connected
      try {
        final chatSession = ChatSessionController.instance;
        if (!chatSession.isConnected && !chatSession.isLoading) {
          await chatSession.connectUser();
        }
      } catch (_) {
        // If ChatSessionController not registered yet, ignore; Stream widgets may still work if client exists
      }

      // Small grace delay if the client is still spinning up
      await Future.any([
        Future.delayed(const Duration(milliseconds: 200)),
        Future.value(),
      ]);

      final channel = await ChatManagementController.instance
          .getOrCreateDirectChannel(widget.userId);
      if (!mounted) return;
      if (channel == null) {
        setState(() {
          _error = 'Unable to open chat';
          _loading = false;
        });
        return;
      }
      setState(() {
        _channel = channel;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Chat unavailable';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _openFullChat() {
    if (_channel != null) {
      Get.to(() => ChatConversationScreen(channel: _channel!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: 20,
      enableBlur: true,
      padding: const EdgeInsets.only(bottom: 10),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, controller) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Text(
                      'Quick chat',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    if (!_loading && _channel != null)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openFullChat();
                        },
                        icon: const Icon(
                          Icons.open_in_full,
                          color: Colors.blue,
                          size: 16,
                        ),
                        label: const Text(
                          'Open',
                          style: TextStyle(color: Colors.blue),
                        ),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(child: _buildBody(controller)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody(ScrollController controller) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: GoogleFonts.inter(color: Colors.white70)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _retrying
                  ? null
                  : () async {
                      setState(() {
                        _retrying = true;
                        _loading = true;
                        _error = null;
                      });
                      await _initChat();
                      if (mounted) setState(() => _retrying = false);
                    },
              child: _retrying
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final channel = _channel!;
    return StreamChannel(
      channel: channel,
      child: Column(
        children: [
          Expanded(
            child: StreamMessageListView(
              reverse: true,
              shrinkWrap: false,
              emptyBuilder: (context) => Center(
                child: Text(
                  'Send a message to start the conversation',
                  style: GoogleFonts.inter(color: Colors.white54),
                ),
              ),
            ),
          ),
          StreamMessageInput(messageInputController: _messageController),
        ],
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/kaisa_resident_design.dart';
import 'kaisa_profile_repository.dart';

/// Responsive one-to-one resident conversation; uses the existing DM RLS.
class ResidentChatPage extends StatefulWidget {
  const ResidentChatPage({super.key, required this.recipientId});
  final String recipientId;
  @override
  State<ResidentChatPage> createState() => _ResidentChatPageState();
}

class _ResidentChatPageState extends State<ResidentChatPage> {
  final _db = Supabase.instance.client;
  final _input = TextEditingController();
  final _scroll = ScrollController();
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _messages = [];
  String _name = 'KAISA Resident';
  String? _avatarPath, _error;
  bool _busy = false, _loading = true, _refreshing = false;
  String? get _uid => _db.auth.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    // Light polling: replaces expensive full-page reloads and works on mobile/web.
    _refreshTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (mounted && !_busy && !_refreshing) _load();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _load({bool initial = false}) async {
    final uid = _uid;
    if (uid == null || _refreshing) return;
    _refreshing = true;
    try {
      if (initial) {
        final profile = await KaisaProfileRepository.instance.publicProfile(
          widget.recipientId,
        );
        if (mounted)
          setState(() {
            _name = profile?['display_name']?.toString() ?? 'KAISA Resident';
            _avatarPath = profile?['avatar_path']?.toString();
          });
      }
      final result = await _db
          .from('kaisa_direct_messages')
          .select('id,sender_id,recipient_id,body,created_at')
          .or(
            'and(sender_id.eq.$uid,recipient_id.eq.${widget.recipientId}),and(sender_id.eq.${widget.recipientId},recipient_id.eq.$uid)',
          )
          .order('created_at', ascending: true)
          .limit(200);
      if (!mounted) return;
      final rows = (result as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      final changed =
          rows.length != _messages.length ||
          (rows.isNotEmpty &&
              _messages.isNotEmpty &&
              rows.last['id'] != _messages.last['id']);
      setState(() {
        _messages = rows;
        _error = null;
      });
      if (changed || initial) _scrollToBottom();
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load conversation: $e');
    } finally {
      _refreshing = false;
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final body = _input.text.trim();
    final uid = _uid;
    if (uid == null ||
        _busy ||
        body.isEmpty ||
        body.length > 1000 ||
        uid == widget.recipientId)
      return;
    setState(() => _busy = true);
    try {
      await _db.from('kaisa_direct_messages').insert({
        'sender_id': uid,
        'recipient_id': widget.recipientId,
        'body': body,
      });
      _input.clear();
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Message not sent: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    final imageUrl = _avatarPath == null || _avatarPath!.isEmpty
        ? null
        : _db.storage.from('kaisa-avatars').getPublicUrl(_avatarPath!);
    return Scaffold(
      backgroundColor: KaisaResidentDesign.paper,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: KaisaResidentDesign.desktopWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: mobile ? 0 : 32,
              vertical: mobile ? 0 : 18,
            ),
            child: Container(
              decoration: KaisaResidentDesign.cardDecoration(),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: KaisaResidentDesign.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: 'Messages',
                          onPressed: () => context.go('/resident/messages'),
                          icon: const Icon(Icons.arrow_back_rounded),
                        ),
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: const Color(0xFFE5F2E9),
                          backgroundImage: imageUrl == null
                              ? null
                              : NetworkImage(imageUrl),
                          child: imageUrl == null
                              ? const Icon(
                                  Icons.person_rounded,
                                  color: KaisaResidentDesign.green,
                                )
                              : null,
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: InkWell(
                            onTap: () => context.push(
                              '/resident/user/${widget.recipientId}',
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: KaisaResidentDesign.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                                const Text(
                                  'Private conversation',
                                  style: TextStyle(
                                    color: KaisaResidentDesign.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh conversation',
                          onPressed: () => _load(),
                          icon: const Icon(
                            Icons.refresh_rounded,
                            color: KaisaResidentDesign.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.all(9),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  Expanded(
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _messages.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.waving_hand_outlined,
                                  color: KaisaResidentDesign.green,
                                  size: 39,
                                ),
                                SizedBox(height: 13),
                                Text(
                                  'Say hello!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  'Your conversation starts here.',
                                  style: TextStyle(
                                    color: KaisaResidentDesign.muted,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                            itemCount: _messages.length,
                            itemBuilder: (context, i) {
                              final message = _messages[i];
                              final mine = message['sender_id'] == _uid;
                              final at = DateTime.tryParse(
                                message['created_at']?.toString() ?? '',
                              )?.toLocal();
                              return Align(
                                alignment: mine
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxWidth: mobile
                                        ? MediaQuery.sizeOf(context).width * .75
                                        : 540,
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 10),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                    decoration: BoxDecoration(
                                      color: mine
                                          ? KaisaResidentDesign.forest
                                          : const Color(0xFFF0F5F1),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(18),
                                        topRight: const Radius.circular(18),
                                        bottomLeft: Radius.circular(
                                          mine ? 18 : 4,
                                        ),
                                        bottomRight: Radius.circular(
                                          mine ? 4 : 18,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: mine
                                          ? CrossAxisAlignment.end
                                          : CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${message['body'] ?? ''}',
                                          style: TextStyle(
                                            color: mine
                                                ? Colors.white
                                                : KaisaResidentDesign.ink,
                                            fontSize: 14,
                                            height: 1.4,
                                          ),
                                        ),
                                        if (at != null) ...[
                                          const SizedBox(height: 5),
                                          Text(
                                            TimeOfDay.fromDateTime(
                                              at,
                                            ).format(context),
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: mine
                                                  ? Colors.white70
                                                  : KaisaResidentDesign.muted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SafeArea(
                    top: false,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: KaisaResidentDesign.border),
                        ),
                      ),
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _input,
                              maxLength: 1000,
                              minLines: 1,
                              maxLines: 4,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: 'Write a message...',
                                counterText: '',
                                filled: true,
                                fillColor: const Color(0xFFF5F8F5),
                                isDense: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              onSubmitted: (_) => _send(),
                            ),
                          ),
                          const SizedBox(width: 9),
                          IconButton.filled(
                            tooltip: 'Send message',
                            style: IconButton.styleFrom(
                              backgroundColor: KaisaResidentDesign.forest,
                            ),
                            onPressed: _busy ? null : _send,
                            icon: const Icon(Icons.send_rounded),
                          ),
                        ],
                      ),
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

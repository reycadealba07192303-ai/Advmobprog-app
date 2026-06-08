import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../services/user_service.dart';
import '../widgets/custom_text.dart';
import '../theme/app_theme.dart';
final ChatService chatService = ChatService();

class ChatDetailScreen extends StatefulWidget {
  final String currentUserEmail;
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({
    Key? key,
    required this.currentUserEmail,
    required this.tappedUser,
  }) : super(key: key);

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late Future<String> _currentUserIdFuture;
  bool _isSending = false;
  Timestamp? _sendingStartedAt;

  static const _postSendDelay = Duration(milliseconds: 600);

  @override
  void initState() {
    super.initState();
    _currentUserIdFuture = _getCurrentUserId();
  }

  Future<String> _getCurrentUserId() async {
    final userData = await userService.value.getUserData();
    return (userData['uid'] ?? '').toString();
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(String currentUserId, String receiverId) async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _sendingStartedAt = Timestamp.now();
    });

    try {
      await chatService.sendMessage(receiverId, text);
      _msgCtrl.clear();
      _msgFocus.requestFocus();

      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
      await Future.delayed(_postSendDelay);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
          _sendingStartedAt = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tappedUserId = (widget.tappedUser['uid'] ?? '').toString();
    final tappedUserName = (widget.tappedUser['firstName'] ?? '').toString();

    return FutureBuilder<String>(
      future: _currentUserIdFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.hasError || !snap.hasData || snap.data!.isEmpty) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }

        final currentUserId = snap.data!;

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: CustomText(text: tappedUserName, fontSize: 25.sp),
          ),
          body: Column(
            children: [
              // Messages
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: chatService.getMessage(currentUserId, tappedUserId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading messages: ${snapshot.error}'),
                      );
                    }

                    List<QueryDocumentSnapshot> docs = snapshot.data?.docs ?? [];
                    final palette = AppPalette.of(context);

                    if (docs.isEmpty) {
                      return Center(
                        child: CustomText(
                          text: 'No messages yet',
                          color: palette.textSecondary,
                          fontSize: 16.sp,
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      reverse: true,
                      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final data = doc.data() as Map<String, dynamic>;
                        final msgText = (data['message'] ?? '').toString();
                        final senderId = (data['senderId'] ?? '').toString();
                        final isMe = senderId == currentUserId;
                        final isPending = doc.metadata.hasPendingWrites;

                        return AnimatedAlign(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOut,
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: EdgeInsets.only(
                              bottom: 12.h,
                              left: isMe ? 40.w : 0,
                              right: isMe ? 0 : 40.w,
                            ),
                            padding: EdgeInsets.symmetric(
                              vertical: 12.h, horizontal: 16.w,
                            ),
                            decoration: BoxDecoration(
                              gradient: isMe ? AppColors.primaryGradient : null,
                              color: isMe ? null : palette.surfaceLight,
                              boxShadow: [
                                BoxShadow(
                                  color: palette.shadow.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                              borderRadius: BorderRadius.circular(20.r).copyWith(
                                bottomLeft: isMe ? Radius.circular(20.r) : Radius.zero,
                                bottomRight: isMe ? Radius.zero : Radius.circular(20.r),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Flexible(
                                  child: CustomText(
                                    text: msgText.isNotEmpty ? msgText : "[empty]",
                                    fontSize: 15.sp,
                                    color: isMe ? Colors.white : palette.textPrimary,
                                    fontWeight: FontWeight.normal,
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                if (isMe) ...[
                                  SizedBox(width: 8.w),
                                  isPending
                                      ? SizedBox(
                                          width: 12.sp,
                                          height: 12.sp,
                                          child: const CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
                                          ),
                                        )
                                      : Icon(
                                          Icons.check_circle_outline,
                                          size: 14.sp,
                                          color: Colors.white.withValues(alpha: 0.9),
                                        ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Composer
              SafeArea(
                top: false,
                child: Container(
                  padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 12.h),
                  decoration: BoxDecoration(
                    color: AppPalette.of(context).surface,
                    boxShadow: [
                      BoxShadow(
                        color: AppPalette.of(context).shadow.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppPalette.of(context).surfaceLight,
                            borderRadius: BorderRadius.circular(24.r),
                            border: Border.all(color: AppPalette.of(context).cardBorder),
                          ),
                          child: TextField(
                            controller: _msgCtrl,
                            focusNode: _msgFocus,
                            enabled: !_isSending,
                            textInputAction: TextInputAction.send,
                            minLines: 1,
                            maxLines: 4,
                            style: TextStyle(
                              color: AppPalette.of(context).textPrimary,
                              fontFamily: 'Poppins',
                              fontSize: 14.sp,
                            ),
                            onSubmitted: (_) =>
                                !_isSending ? _send(currentUserId, tappedUserId) : null,
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              hintStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppPalette.of(context).textMuted,
                                fontSize: 14.sp,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.w, vertical: 12.h,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryStart.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: IconButton(
                          icon: _isSending
                              ? SizedBox(
                                  width: 20.sp,
                                  height: 20.sp,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Icon(Icons.send_rounded, color: Colors.white, size: 20.sp),
                          onPressed: () => _isSending ? null : _send(currentUserId, tappedUserId),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

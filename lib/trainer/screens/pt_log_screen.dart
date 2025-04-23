// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/chat_message.dart';
import '../../models/meeting.dart';
import '../../widgets/chat_input_field.dart';
import '../../widgets/chat_message_bubble.dart';
import '../services/pt_logs_service.dart';

class PtLogConstants {
  static const String userRole = 'user';
  static const String assistantRole = 'assistant';
  static const String errorMessage = '오류가 발생했습니다: ';
  static const String appTitle = 'PT 일지 작성';
  static const String logHistoryKey = 'pt_log_history';

  static const double messagePadding = 8.0;
  static const double messageMargin = 4.0;
  static const double borderRadius = 12.0;
  static const double iconSpacing = 8.0;

  static const String defaultMessage = '''
오늘의 PT 일지를 작성하거나 수정하는 화면입니다.
(챗봇의 기능은 하지 않습니다.)

아래 서식에 맞게 작성해주세요.

1. 운동 이름
2. 무게
3. 횟수
4. 세트
5. 해당 운동에 대한 피드백(선택 사항)
6. 오늘 수업에 대한 전반적인 피드백(선택 사항)

이곳은 채팅 내역이 남지 않으니 유의해주세요!
(단, 입력중인 메시지는 유지됩니다.)
''';
}

class PtLogScreen extends StatefulWidget {
  final int scheduleId;
  final Meeting meeting;
  final String title;

  const PtLogScreen({
    super.key,
    required this.scheduleId,
    required this.meeting,
    this.title = 'PT 일지 작성',
  });

  @override
  State<PtLogScreen> createState() => PtLogScreenState();
}

class PtLogScreenState extends State<PtLogScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final PtLogsService _ptLogsService = PtLogsService();
  bool _isLoading = false;
  SharedPreferences? _prefs;
  bool _isPrefsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePrefs();
    _messages.add(
      ChatMessage(
        content: PtLogConstants.defaultMessage,
        role: PtLogConstants.assistantRole,
      ),
    );
  }

  Future<void> _initializePrefs() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isPrefsInitialized = true;
      await _loadDraftMessage();
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing SharedPreferences: $e');
      }
    }
  }

  Future<void> _loadDraftMessage() async {
    if (!_isPrefsInitialized || _prefs == null) return;

    try {
      final draftMessage = _prefs!.getString(
        '${PtLogConstants.logHistoryKey}_${widget.scheduleId}_draft',
      );
      if (draftMessage != null && mounted) {
        _messageController.text = draftMessage;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading draft message: $e');
      }
    }
  }

  Future<void> _saveDraftMessage() async {
    if (!_isPrefsInitialized || _prefs == null) return;

    try {
      await _prefs!.setString(
        '${PtLogConstants.logHistoryKey}_${widget.scheduleId}_draft',
        _messageController.text,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error saving draft message: $e');
      }
    }
  }

  void _showToast(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            top: MediaQuery.of(context).size.height * 0.8,
            left: MediaQuery.of(context).size.width * 0.1,
            right: MediaQuery.of(context).size.width * 0.1,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    if (kDebugMode) {
      print('User message: $userMessage');
    }
    _messageController.clear();
    await _saveDraftMessage();

    setState(() {
      _messages.add(
        ChatMessage(content: userMessage, role: PtLogConstants.userRole),
      );
      _messages.add(
        ChatMessage(
          content: '답변을 생성하는 중...',
          role: PtLogConstants.assistantRole,
        ),
      );
      _isLoading = true;
    });

    try {
      if (kDebugMode) {
        print('Calling _ptLogsService.sendMessage');
      }
      final response = await _ptLogsService.sendMessage(
        userMessage,
        widget.scheduleId,
      );
      if (kDebugMode) {
        print('Received response from service: ${response.finalResponse}');
      }

      if (mounted) {
        setState(() {
          _messages.removeLast(); // 로딩 메시지 제거
          _messages.add(
            ChatMessage(
              content: response.finalResponse,
              role: PtLogConstants.assistantRole,
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('Error in _sendMessage: $e');
        print('Stack trace: $stackTrace');
      }
      if (mounted) {
        setState(() {
          _messages.removeLast(); // 로딩 메시지 제거
          _isLoading = false;
        });
        _showToast('${PtLogConstants.errorMessage}$e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: const Color(0xfff0f0f0),
        foregroundColor: Colors.black87,
        elevation: 0,
        forceMaterialTransparency: true,
      ),
      body: SafeArea(
        child: Container(
          color: const Color(0xfff0f0f0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.meeting.eventName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('시작 일시: ${_formatDateTime(widget.meeting.from)}'),
                        Text('종료 일시: ${_formatDateTime(widget.meeting.to)}'),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _messages.length,
                  padding: const EdgeInsets.all(PtLogConstants.messagePadding),
                  itemBuilder: (context, index) {
                    return ChatMessageBubble(message: _messages[index]);
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ChatInputField(
                  controller: _messageController,
                  onSend: _sendMessage,
                  isLoading: _isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}년 ${dateTime.month}월 ${dateTime.day}일 ${dateTime.hour}시 ${dateTime.minute}분';
  }

  @override
  void dispose() {
    _saveDraftMessage();
    _messageController.dispose();
    super.dispose();
  }
}

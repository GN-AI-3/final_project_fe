// ignore_for_file: deprecated_member_use

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../../models/exercise_record.dart';
import '../../models/meeting.dart';
import '../../models/schedule.dart';
import '../../trainer/services/schedule_service.dart';
import '../../widgets/custom_dialog.dart';
import '../screens/member_personal_exercise_screen.dart';
import '../services/member_personal_exercise_service.dart';
import '../../widgets/common_bottom_navigation_bar.dart';
import '../screens/member_chat_screen.dart';
import '../../screens/home_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_toast.dart';
import '../../trainer/services/pt_logs_service.dart';

class MemberCalendarConstants {
  static const Map<String, String> statusDescriptions = {
    'scheduled': '[예정된 일정]',
    'changed': '[변경된 일정]',
    'completed': '[완료된 일정]',
    'cancelled': '[취소된 일정]',
    'no_show': '[불참]',
  };

  static const Map<CalendarView, IconData> viewIcons = {
    CalendarView.day: Icons.view_day,
    CalendarView.week: Icons.view_week,
    CalendarView.month: Icons.calendar_month,
    CalendarView.schedule: Icons.schedule,
  };

  static const Map<CalendarView, CalendarView> nextView = {
    CalendarView.day: CalendarView.week,
    CalendarView.week: CalendarView.month,
    CalendarView.month: CalendarView.schedule,
    CalendarView.schedule: CalendarView.day,
  };
}

class MemberCalendarState {
  final CalendarController controller = CalendarController();
  CalendarView currentView = CalendarView.month;
  List<Meeting> meetings = [];
  List<Meeting> filteredMeetings = [];
  String? selectedStatus;
  bool isLoading = false;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  void updateView(CalendarView newView) {
    currentView = newView;
    controller.view = newView;
  }

  void updateFilteredMeetings(List<Meeting> meetings) {
    filteredMeetings = meetings;
  }

  void updateSelectedStatus(String? status) {
    selectedStatus = status;
  }

  void updateLoading(bool loading) {
    isLoading = loading;
  }

  void updateLastDates(DateTime? start, DateTime? end) {
    lastStartDate = start;
    lastEndDate = end;
  }
}

class MemberCalendarScreen extends StatefulWidget {
  const MemberCalendarScreen({super.key});

  @override
  State<MemberCalendarScreen> createState() => _MemberCalendarScreenState();
}

class _MemberCalendarScreenState extends State<MemberCalendarScreen> {
  final ScheduleService _scheduleService = MemberScheduleService();
  final MemberPersonalExerciseService _exerciseService =
      MemberPersonalExerciseService();
  final PtLogsService _ptLogsService = PtLogsService();
  final MemberCalendarState _state = MemberCalendarState();
  DateTime _selectedDate = DateTime.now();
  bool _isButtonVisible = false;

  @override
  void initState() {
    super.initState();
    _isButtonVisible = true;
    _state.updateSelectedStatus('scheduled');
    _loadMeetings();
  }

  Future<void> _loadMeetings({DateTime? startDate, DateTime? endDate}) async {
    if (_state.isLoading) return;
    if (!mounted) return;

    _state.updateLoading(true);

    try {
      final queryStartDate = startDate;
      final queryEndDate = endDate;

      final schedules = await _scheduleService.getSchedules(
        startTime: queryStartDate,
        endTime: queryEndDate,
      );

      final exerciseRecords = await _exerciseService.getExerciseRecords(
        queryStartDate ?? DateTime.now(),
        queryEndDate ?? DateTime.now().add(const Duration(days: 30)),
      );

      if (!mounted) return;

      final meetings =
          schedules.map<Meeting>((schedule) {
            return createMeeting(schedule);
          }).toList();

      // 운동 기록을 Meeting 객체로 변환하여 추가
      for (var record in exerciseRecords) {
        final date = DateTime.parse(record.date);
        if (record.records.isNotEmpty) {
          meetings.add(
            Meeting(
              '${date.month}월 ${date.day}일의 개인운동 기록',
              date,
              date,
              const Color(0xff2746f8),
              true,
              textStyle: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w400,
              ),
              description: '운동 기록',
            ),
          );
        }
      }

      if (!mounted) return;

      _state.meetings = meetings;
      _state.updateFilteredMeetings(meetings);
      _filterMeetings();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (!mounted) return;
      _showError('앗!', e);
    } finally {
      if (mounted) {
        _state.updateLoading(false);
      }
    }
  }

  Meeting createMeeting(Schedule schedule) {
    final eventName =
        [
              'changed',
              'cancelled',
              'no_show',
            ].contains(schedule.status.toLowerCase())
            ? '${_getStatusDescription(schedule.status)} ${schedule.reason}'
            : schedule.status.toLowerCase() == 'scheduled'
            ? '${schedule.currentPtCount}회차 PT'
            : '${_getStatusDescription(schedule.status)} PT 스케줄 (${schedule.currentPtCount}회차)';

    return Meeting(
      eventName,
      schedule.startTime,
      schedule.endTime,
      Colors.green,
      false,
      id: schedule.id,
      scheduleId: schedule.id,
      textStyle: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w400,
      ),
      description:
          schedule.status.toLowerCase() == 'scheduled'
              ? '남은 PT: ${schedule.remainingPtCount}회'
              : '${_getStatusDescription(schedule.status)}\n남은 PT: ${schedule.remainingPtCount}회',
    );
  }

  void _showError(String message, dynamic error) {
    if (kDebugMode) {
      print('$message: $error');
    }
    if (mounted) {
      CustomDialog.show(
        context: context,
        title: '앗!',
        content: Text('$message\n${error?.toString() ?? ''}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      );
    }
  }

  void _showMeetingDetails(Meeting meeting) {
    CustomDialog.show(
      context: context,
      title: 'PT 스케줄',
      content: Container(
        width: double.infinity,
        alignment: Alignment.centerLeft,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meeting.description != '운동 기록') ...[
              if (meeting.description?.contains('[완료된 일정]') ?? false) ...[
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final exercises = await _ptLogsService.getPtLogExercises(
                        meeting.scheduleId!,
                      );
                      if (!mounted) return;

                      Navigator.pop(context);
                      _showPtLogDetails(exercises, meeting);
                    } catch (e) {
                      if (!mounted) return;
                      CustomToast.show(
                        context: context,
                        message: '해당 일정의 PT 일지가 없습니다.',
                        type: ToastType.info,
                      );
                    }
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('PT 기록 보기'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                  ),
                ),
              ],
            ],
            if (meeting.description == '운동 기록') ...[
              FutureBuilder<List<GroupedExerciseRecord>>(
                future: _exerciseService.getExerciseRecords(
                  meeting.from,
                  meeting.to,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Text('오류가 발생했습니다: ${snapshot.error}');
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('운동 기록이 없습니다.');
                  }

                  final records = snapshot.data!;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        records.expand((record) => record.records).map((
                          exercise,
                        ) {
                          return GestureDetector(
                            onLongPress: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) => SafeArea(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ListTile(
                                        leading: const Icon(Icons.edit),
                                        title: const Text('기록 수정'),
                                        onTap: () {
                                          Navigator.pop(context);
                                          _showExerciseRecordEditDialog(
                                            exercise,
                                            DateTime.parse(records.first.date),
                                          );
                                        },
                                      ),
                                      ListTile(
                                        leading: const Icon(Icons.delete, color: Colors.red),
                                        title: const Text(
                                          '기록 삭제',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                        onTap: () {
                                          Navigator.pop(context);
                                          // TODO: 삭제 기능 구현
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('삭제 기능은 아직 구현되지 않았습니다.'),
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 12,
                                  bottom: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise.exerciseName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    if (exercise.recordData.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildExerciseDetail('무게', '${exercise.recordData['weight']}kg'),
                                          _buildExerciseDetail('횟수', exercise.recordData['reps'].toString()),
                                          _buildExerciseDetail('세트', exercise.recordData['sets'].toString()),
                                        ],
                                      ),
                                    ],
                                    if (exercise.memoData.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        '메모:',
                                        style: TextStyle(fontWeight: FontWeight.w400),
                                      ),
                                      Text(exercise.memoData['memo'] ?? ''),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  void _showExerciseRecordEditDialog(ExerciseRecord exercise, DateTime date) {
    final TextEditingController repsController = TextEditingController(
      text: exercise.recordData['reps']?.toString() ?? '',
    );
    final TextEditingController setsController = TextEditingController(
      text: exercise.recordData['sets']?.toString() ?? '',
    );
    final TextEditingController weightController = TextEditingController(
      text: exercise.recordData['weight']?.toString() ?? '',
    );
    final TextEditingController memoController = TextEditingController(
      text: exercise.memoData['memo']?.toString() ?? '',
    );

    CustomDialog.show(
      context: context,
      title: '${exercise.exerciseName} 기록 수정',
      content: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: repsController,
              decoration: const InputDecoration(
                labelText: '횟수',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: setsController,
              decoration: const InputDecoration(
                labelText: '세트',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              decoration: const InputDecoration(
                labelText: '무게',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: memoController,
              decoration: const InputDecoration(
                labelText: '메모',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () async {
            try {
              final memberId = await _exerciseService.getMemberId();

              final recordData = {
                if (repsController.text.isNotEmpty) 'reps': int.parse(repsController.text),
                if (setsController.text.isNotEmpty) 'sets': int.parse(setsController.text),
                if (weightController.text.isNotEmpty) 'weight': double.parse(weightController.text),
              };

              final memoData = {
                'memo': memoController.text.isEmpty ? '' : memoController.text,
              };

              await _exerciseService.updateExerciseRecord(
                memberId: memberId,
                exerciseId: exercise.exerciseId,
                date: date,
                recordData: recordData,
                memoData: memoData,
              );

              if (mounted) {
                Navigator.pop(context);
                _loadMeetings();
              }
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('오류가 발생했습니다: $e')),
                );
              }
            }
          },
          child: const Text('저장'),
        ),
      ],
    );
  }

  void _changeView() {
    setState(() {
      _state.updateView(
        MemberCalendarConstants.nextView[_state.currentView] ??
            CalendarView.month,
      );
    });
  }

  void _filterMeetings() {
    setState(() {
      if (_state.selectedStatus == null) {
        _state.updateFilteredMeetings(_state.meetings);
      } else if (_state.selectedStatus == 'scheduled') {
        // scheduled와 completed 상태의 일정만 표시
        _state.updateFilteredMeetings(
          _state.meetings.where((meeting) {
            final status = meeting.description?.split('\n')[0];
            return status == null || 
                   !status.contains('[') || 
                   status.contains('[완료된 일정]');
          }).toList(),
        );
      } else {
        final targetDescription =
            MemberCalendarConstants.statusDescriptions[_state.selectedStatus!
                .toLowerCase()];
        _state.updateFilteredMeetings(
          _state.meetings.where((meeting) {
            final status = meeting.description?.split('\n')[0];
            return status == targetDescription;
          }).toList(),
        );
      }
    });
  }

  String _getStatusDescription(String status) {
    return MemberCalendarConstants.statusDescriptions[status.toLowerCase()] ??
        '[${status.toUpperCase()}]';
  }

  void _showFilterMenu() {
    showMenu<String>(
      context: context,
      position: const RelativeRect.fromLTRB(1, 80, 0, 0),
      items: [
        const PopupMenuItem<String>(value: null, child: Text('전체')),
        const PopupMenuItem<String>(value: 'scheduled', child: Text('예정')),
        const PopupMenuItem<String>(value: 'changed', child: Text('변경')),
        const PopupMenuItem<String>(value: 'completed', child: Text('완료')),
        const PopupMenuItem<String>(value: 'cancelled', child: Text('취소')),
        const PopupMenuItem<String>(value: 'no_show', child: Text('불참')),
      ],
    ).then((value) {
      if (value != null) {
        setState(() {
          _state.updateSelectedStatus(value);
          _filterMeetings();
        });
      }
    });
  }

  void _handleViewChanged(ViewChangedDetails details) {
    if (_state.isLoading) return;

    final visibleDates = details.visibleDates;
    if (visibleDates.isEmpty) return;

    final startDate = visibleDates.first;
    final endDate = DateTime(
      visibleDates.last.year,
      visibleDates.last.month,
      visibleDates.last.day,
      23,
      59,
      59,
    );

    final cachedStart = _state.lastStartDate;
    final cachedEnd = _state.lastEndDate;

    final needsLoading =
        cachedStart == null ||
        cachedEnd == null ||
        startDate.isBefore(cachedStart) ||
        endDate.isAfter(cachedEnd);

    if (needsLoading) {
      _state.updateLastDates(startDate, endDate);
      _loadMeetings(startDate: startDate, endDate: endDate);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  Future<void> _showRoleSwitchDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('역할 전환'),
        content: const Text('트레이너 화면으로 전환하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('아니오'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('예'),
          ),
        ],
      ),
    );

    if (result == true) {
      await AuthService.login('trainer@example.com', '1234', 'trainer');
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
          (route) => false,
        );
      }
    }
  }

  void _showPtLogDetails(List<PtLogExercise> exercises, Meeting meeting) {
    CustomDialog.show(
      context: context,
      title: 'PT 기록',
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:
              exercises
                  .map(
                    (exercise) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              exercise.exerciseName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildExerciseDetail(
                                  '무게',
                                  '${exercise.weight}kg',
                                ),
                                _buildExerciseDetail(
                                  '횟수',
                                  exercise.reps.toString(),
                                ),
                                _buildExerciseDetail(
                                  '세트',
                                  exercise.sets.toString(),
                                ),
                                _buildExerciseDetail(
                                  '휴식',
                                  '${exercise.restTime}초',
                                ),
                              ],
                            ),
                            if (exercise.feedback?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              const Text(
                                '피드백:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(exercise.feedback ?? ''),
                            ],
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('닫기'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('캘린더'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterMenu,
          ),
          IconButton(
            icon: Icon(
              MemberCalendarConstants.viewIcons[_state.currentView] ??
                  Icons.calendar_month,
            ),
            onPressed: _changeView,
          ),
        ],
        forceMaterialTransparency: true,
        backgroundColor: const Color(0xfff0f0f0),
      ),
      body: Stack(
        children: [
          _state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                color: const Color(0xfff0f0f0),
                child: SfCalendar(
                  controller: _state.controller,
                  view: _state.currentView,
                  headerHeight: 50,
                  headerStyle: const CalendarHeaderStyle(
                    textAlign: TextAlign.start,
                    backgroundColor: Color(0xfff0f0f0),
                    textStyle: TextStyle(fontSize: 22, color: Colors.black87),
                  ),
                  headerDateFormat: ' yyyy년 M월',
                  timeZone: 'Korea Standard Time',
                  cellBorderColor: const Color(0xffd8d8d8),
                  monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                    agendaViewHeight: 350,
                    appointmentDisplayCount: 2,
                    agendaItemHeight: 50,
                  ),
                  appointmentBuilder: (BuildContext context,
                      CalendarAppointmentDetails calendarAppointmentDetails) {
                    final Meeting meeting = calendarAppointmentDetails.appointments.first as Meeting;
                    return Container(
                      width: calendarAppointmentDetails.bounds.width,
                      height: calendarAppointmentDetails.bounds.height,
                      decoration: BoxDecoration(
                        color: meeting.background,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: meeting.description == '운동 기록' 
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              meeting.eventName,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                                color: Colors.white,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                meeting.eventName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${meeting.from.hour.toString().padLeft(2, '0')}:${meeting.from.minute.toString().padLeft(2, '0')} - ${meeting.to.hour.toString().padLeft(2, '0')}:${meeting.to.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                    );
                  },
                  selectionDecoration: BoxDecoration(
                    color: Colors.transparent,
                    border: Border.all(
                      color: const Color(0xff2746f8),
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.all(Radius.circular(4)),
                    shape: BoxShape.rectangle,
                  ),
                  firstDayOfWeek: 1,
                  cellEndPadding: 0,
                  todayHighlightColor: const Color(0xff2746f8),
                  backgroundColor: const Color(0xfff0f0f0),
                  initialSelectedDate: DateTime.now().toLocal(),
                  initialDisplayDate: DateTime.now().toLocal(),
                  dataSource: MeetingDataSource(_state.filteredMeetings),
                  showDatePickerButton: true,
                  showTodayButton: true,
                  onTap: (CalendarTapDetails details) {
                    if (details.targetElement == CalendarElement.appointment) {
                      _showMeetingDetails(details.appointments![0] as Meeting);
                    } else if (details.targetElement ==
                        CalendarElement.calendarCell) {
                      setState(() {
                        _selectedDate = details.date!;
                        _isButtonVisible = false;
                      });
                      Future.delayed(const Duration(milliseconds: 50), () {
                        if (mounted) {
                          setState(() {
                            _isButtonVisible = true;
                          });
                        }
                      });
                    }
                  },
                  onViewChanged: _handleViewChanged,
                ),
              ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              transform: Matrix4.translationValues(
                0,
                _isButtonVisible ? 0 : 100,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => MemberPersonalExerciseScreen(
                              selectedDate: _selectedDate,
                            ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xff2746f8),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    '${_formatDate(_selectedDate)} 개인 운동 기록하기',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CommonBottomNavigationBar(
        isTrainer: false,
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              // 현재 화면이므로 아무것도 하지 않음
              break;
            case 1:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MemberChatScreen()),
              );
              break;
            case 2:
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HomeScreen()),
              );
              break;
            case 3:
              CustomToast.show(
                context: context,
                message: '현재 준비중입니다.',
                type: ToastType.info,
              );
              break;
            case 4:
              _showRoleSwitchDialog();
              break;
          }
        },
      ),
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class MeetingDataSource extends CalendarDataSource {
  MeetingDataSource(List<Meeting> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return appointments![index].from;
  }

  @override
  DateTime getEndTime(int index) {
    return appointments![index].to;
  }

  @override
  String getSubject(int index) {
    return appointments![index].eventName;
  }

  @override
  Color getColor(int index) {
    return appointments![index].background;
  }

  @override
  bool isAllDay(int index) {
    return appointments![index].isAllDay;
  }
}

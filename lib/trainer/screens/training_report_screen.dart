// ignore_for_file: deprecated_member_use

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../member/services/member_personal_exercise_service.dart';
import '../../models/exercise_record.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../services/pt_logs_service.dart';

// 데이터 모델 클래스
class ReportData {
  final String category;
  final double score;
  final String description;

  ReportData({
    required this.category,
    required this.score,
    required this.description,
  });
}

class TrainingReportScreen extends StatelessWidget {
  final int ptContractId;

  const TrainingReportScreen({super.key, required this.ptContractId});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('트레이닝 리포트'),
          backgroundColor: const Color(0xfff0f0f0),
          foregroundColor: Colors.black87,
          elevation: 0,
          bottom: TabBar(
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            dividerColor: Colors.grey[400],
            tabs: const [
              Tab(text: '     개요     '),
              Tab(text: '     운동     '),
              Tab(text: '     식단     '),
              Tab(text: '    인바디    '),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            ReportComparisonTab(ptContractId: ptContractId),
            ExerciseReportTab(ptContractId: ptContractId),
            DietReportTab(ptContractId: ptContractId),
            InbodyReportTab(ptContractId: ptContractId),
          ],
        ),
      ),
    );
  }
}

class ReportComparisonTab extends StatefulWidget {
  final int ptContractId;

  const ReportComparisonTab({super.key, required this.ptContractId});

  @override
  State<ReportComparisonTab> createState() => _ReportComparisonTabState();
}

class _ReportComparisonTabState extends State<ReportComparisonTab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _blueAnimation;
  late Animation<double> _greenAnimation;
  bool _showCurrentData = true;
  int? _selectedDataSetIndex;
  List<Report>? _reports;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _blueAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
      ),
    );

    _greenAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _selectedDataSetIndex = 0;
    _loadReports();
  }

  Future<void> _loadReports() async {
    try {
      final reports = await ReportService.getLatestReports(widget.ptContractId);
      setState(() {
        _reports = reports;
        _isLoading = false;
      });
      if (reports.isNotEmpty) {
        _controller.forward();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReports, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_reports == null || _reports!.isEmpty) {
      return const Center(
        child: Text(
          '아직 트레이닝 리포트가 생성되지 않았습니다.\nPT 기록을 먼저 작성해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    if (_reports!.length < 2) {
      return const Center(
        child: Text(
          '비교할 리포트가 충분하지 않습니다.\n더 많은 PT 기록을 작성해주세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    final currentReport = _reports![0];
    final previousReport = _reports![1];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '종합 점수 비교',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            '당신은 이제 PT 이전과 이후로 나뉩니다.',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 36),
          SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return RadarChart(
                  RadarChartData(
                    dataSets: [
                      RadarDataSet(
                        fillColor: Colors.green.withOpacity(
                          _selectedDataSetIndex == 1 ? 0.4 : 0.2,
                        ),
                        borderColor: Colors.green,
                        borderWidth: _selectedDataSetIndex == 1 ? 2 : 1,
                        entryRadius: 3,
                        dataEntries: [
                          RadarEntry(
                            value:
                                previousReport.exerciseReport.diligenceScore
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                previousReport
                                    .exerciseReport
                                    .personalExerciseScore
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                (previousReport.dietReport.dietScore ?? 0)
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                previousReport.inbodyReport.bmiScore
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                previousReport.inbodyReport.bodyFatScore
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                previousReport.inbodyReport.skeletalMuscleScore
                                    .toDouble() *
                                _greenAnimation.value,
                          ),
                        ],
                      ),
                      RadarDataSet(
                        fillColor: Colors.blue.withOpacity(
                          _selectedDataSetIndex == 0 ? 0.45 : 0.3,
                        ),
                        borderColor: Colors.blue,
                        borderWidth: _selectedDataSetIndex == 0 ? 2 : 1,
                        entryRadius: 3,
                        dataEntries: [
                          RadarEntry(
                            value:
                                currentReport.exerciseReport.diligenceScore
                                    .toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                currentReport
                                    .exerciseReport
                                    .personalExerciseScore
                                    .toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                (currentReport.dietReport.dietScore ?? 0)
                                    .toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                currentReport.inbodyReport.bmiScore.toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                currentReport.inbodyReport.bodyFatScore
                                    .toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value:
                                currentReport.inbodyReport.skeletalMuscleScore
                                    .toDouble() *
                                _blueAnimation.value,
                          ),
                        ],
                      ),
                    ],
                    radarBackgroundColor: Colors.transparent,
                    radarShape: RadarShape.polygon,
                    titleTextStyle: const TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    getTitle: (index, _) {
                      const titles = [
                        '운동 성실도',
                        '운동 점수',
                        '식단 점수',
                        'BMI 점수',
                        '체지방률',
                        '골격근량',
                      ];
                      return RadarChartTitle(text: titles[index]);
                    },
                    tickCount: 5,
                    ticksTextStyle: const TextStyle(
                      color: Colors.black54,
                      fontSize: 10,
                    ),
                    gridBorderData: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 0.5,
                    ),
                    radarBorderData: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 0.5,
                    ),
                    tickBorderData: BorderSide(
                      color: Colors.grey.withOpacity(0.3),
                      width: 0.5,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCurrentData = false;
                    _selectedDataSetIndex = 1;
                  });
                },
                child: _LegendItem(
                  color: Colors.green,
                  text: '초기',
                  isSelected: !_showCurrentData,
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _showCurrentData = true;
                    _selectedDataSetIndex = 0;
                  });
                },
                child: _LegendItem(
                  color: Colors.blue,
                  text: '현재',
                  isSelected: _showCurrentData,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          _ReportDetailSection(
            title: Text(
              '운동 리포트',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            data:
                _showCurrentData
                    ? currentReport.exerciseReport
                    : previousReport.exerciseReport,
          ),
          const SizedBox(height: 32),
          _ReportDetailSection(
            title: Text(
              '식단 리포트',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            data:
                _showCurrentData
                    ? currentReport.dietReport
                    : previousReport.dietReport,
          ),
          const SizedBox(height: 32),
          _ReportDetailSection(
            title: Text(
              '인바디 리포트',
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            data:
                _showCurrentData
                    ? currentReport.inbodyReport
                    : previousReport.inbodyReport,
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSection extends StatelessWidget {
  final Widget title;
  final dynamic data;

  const _ReportDetailSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        title,
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((title as Text).data == '운동 리포트') ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 2,
                      children: [
                        _buildScoreRow(
                          '성실도 점수',
                          (data as ExerciseReport).diligenceScore,
                        ),
                        _buildScoreRow(
                          '개인 운동 점수',
                          (data as ExerciseReport).personalExerciseScore,
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 12),
                    _buildSectionTitle('운동 성과 요약'),
                    Text(
                      (data as ExerciseReport).recentTrainingPattern,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('운동 강점'),
                    Text(
                      (data as ExerciseReport).strengthsAndGoodHabits,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('개선 사항'),
                    Text(
                      (data as ExerciseReport).weaknesses,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('트레이너 코멘트'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (data as ExerciseReport).trainerMent,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else if ((title as Text).data == '식단 리포트') ...[
                    _buildScoreRow(
                      '식단 평가 점수',
                      (data as DietReport).dietScore ?? 0,
                    ),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 12),
                    _buildSectionTitle('식단 평가 요약'),
                    Text(
                      (data as DietReport).recentDietPattern ?? '데이터가 없습니다',
                      style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('식단 강점'),
                    Text(
                      (data as DietReport).strengths ?? '데이터가 없습니다',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('개선 사항'),
                    Text(
                      (data as DietReport).problems ?? '데이터가 없습니다',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('트레이너 코멘트'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (data as DietReport).trainerMent ?? '데이터가 없습니다',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ] else if ((title as Text).data == '인바디 리포트') ...[
                    Wrap(
                      spacing: 16,
                      runSpacing: 2,
                      children: [
                        _buildScoreRow(
                          'BMI 점수',
                          (data as InbodyReport).bmiScore,
                        ),
                        _buildScoreRow(
                          '골격근량 점수',
                          (data as InbodyReport).skeletalMuscleScore,
                        ),
                        _buildScoreRow(
                          '체지방률 점수',
                          (data as InbodyReport).bodyFatScore,
                        ),
                      ],
                    ),
                    Divider(color: Colors.grey[200], thickness: 1),
                    const SizedBox(height: 12),
                    _buildSectionTitle('체성분 현황'),
                    Text(
                      '${(data as InbodyReport).bmiAnalysis}\n${(data as InbodyReport).skeletalMuscleAnalysis}\n${(data as InbodyReport).bodyFatAnalysis}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('인바디 평가'),
                    Text(
                      (data as InbodyReport).summary,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    _buildSectionTitle('트레이너 코멘트'),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue, width: 1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (data as InbodyReport).trainerMent,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, dynamic score) {
    final int scoreValue = score is int ? score : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _getScoreColor(scoreValue),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getScoreColor(scoreValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getScoreColor(scoreValue), width: 1),
            ),
            child: Text(
              '$scoreValue점',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _getScoreColor(scoreValue),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String text;
  final bool isSelected;

  const _LegendItem({
    required this.color,
    required this.text,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isSelected ? color : Colors.grey, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isSelected ? color : Colors.black54,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class ExerciseReportTab extends StatefulWidget {
  final int ptContractId;

  const ExerciseReportTab({super.key, required this.ptContractId});

  @override
  State<ExerciseReportTab> createState() => _ExerciseReportTabState();
}

class _ExerciseReportTabState extends State<ExerciseReportTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['종합', '운동 패턴 분석', '운동 기록'];
  final MemberPersonalExerciseService _personalExerciseService =
      MemberPersonalExerciseService();
  final PtLogsService _ptLogsService = PtLogsService();
  List<GroupedExerciseRecord> _exerciseRecords = [];
  List<GroupedPtLogExercise> _ptLogExercises = [];
  bool _isLoading = true;
  String? _error;
  String? _selectedDate;
  bool _isChipsExpanded = false;
  int? _selectedExerciseIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadExerciseRecords();
    _loadPtLogExercises();
  }

  void _selectDateAndSwitchTab(String date) {
    setState(() {
      _selectedDate = date;
    });
    _tabController.animateTo(2);

    Future.delayed(const Duration(milliseconds: 100), () {
      final context = this.context;
      if (!context.mounted) return;

      final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final scrollController = PrimaryScrollController.of(context);
        scrollController.animateTo(
          position.dy + 155,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _loadExerciseRecords() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final records = await _personalExerciseService
          .getExerciseRecordsForReport(widget.ptContractId);

      // 날짜 기준 내림차순 정렬
      records.sort((a, b) => b.date.compareTo(a.date));

      setState(() {
        _exerciseRecords = records;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('개인 운동 기록 로드 중 오류 발생: $e');
      }
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPtLogExercises() async {
    try {
      final exercises = await _ptLogsService.getPtLogExercisesForReport(
        widget.ptContractId,
      );

      setState(() {
        _ptLogExercises = exercises;
      });
    } catch (e) {
      if (kDebugMode) {
        print('PT 운동 기록 로드 중 오류 발생: $e');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          dividerColor: Colors.grey[300],
          dividerHeight: 1.0,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildExerciseTrendTab(),
              _buildExerciseLogTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExerciseRecords,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSummaryCards(),
          const SizedBox(height: 32),
          Text(
            '최근 개인 운동',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildRecentStats(),
          const SizedBox(height: 32),
          Text(
            '주요 운동 TOP 3',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          _buildTopExercises(),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    final totalExercises = _exerciseRecords.fold<int>(
      0,
      (sum, record) => sum + record.records.length,
    );

    final totalPtExercises = _ptLogExercises.fold<int>(
      0,
      (sum, record) => sum + record.exercises.length,
    );

    final uniqueExercises =
        _exerciseRecords
            .expand((record) => record.records)
            .map((exercise) => exercise.exerciseName)
            .toSet()
            .length;

    final uniquePtExercises =
        _ptLogExercises
            .expand((record) => record.exercises)
            .map((exercise) => exercise.exerciseName)
            .toSet()
            .length;

    final totalWeight = _exerciseRecords.fold<double>(
      0,
      (sum, record) =>
          sum +
          record.records.fold<double>(
            0,
            (exerciseSum, exercise) =>
                exerciseSum + (exercise.recordData['weight'] as int? ?? 0),
          ),
    );

    final totalPtWeight = _ptLogExercises.fold<double>(
      0,
      (sum, record) =>
          sum +
          record.exercises.fold<double>(
            0,
            (exerciseSum, exercise) => exerciseSum + (exercise.weight),
          ),
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Text(
            '개인 운동 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        '개인 운동 횟수',
                        '${_exerciseRecords.length}회',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '누적 세트',
                        '$totalExercises세트',
                        Icons.fitness_center,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '운동 종류',
                        '$uniqueExercises종류',
                        Icons.category,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '누적 중량',
                        '${totalWeight.toStringAsFixed(1)}kg',
                        Icons.monitor_weight,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          alignment: Alignment.centerLeft,
          child: Text(
            'PT 통계',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide.none,
          ),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        'PT 횟수',
                        '${_ptLogExercises.length}회',
                        Icons.calendar_today,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '누적 세트',
                        '$totalPtExercises세트',
                        Icons.fitness_center,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '운동 종류',
                        '$uniquePtExercises종류',
                        Icons.category,
                        Colors.orange,
                      ),
                    ),
                    Expanded(
                      child: _buildSummaryCard(
                        '누적 중량',
                        '${totalPtWeight.toStringAsFixed(1)}kg',
                        Icons.monitor_weight,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentStats() {
    if (_exerciseRecords.isEmpty) {
      return const Center(child: Text('최근 운동 기록이 없습니다.'));
    }

    final recentRecords = _exerciseRecords.take(5).toList();
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...recentRecords.asMap().entries.map((entry) {
                final index = entry.key;
                final record = entry.value;
                final date = DateTime.parse(record.date);
                return InkWell(
                  onTap: () => _selectDateAndSwitchTab(record.date),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: index == recentRecords.length - 1 ? 0 : 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${record.records.length}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${date.year}년 ${date.month}월 ${date.day}일',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${record.records.length}개의 운동',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey[400]),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopExercises() {
    final exerciseCounts = <String, int>{};
    for (var record in _exerciseRecords) {
      for (var exercise in record.records) {
        exerciseCounts[exercise.exerciseName] =
            (exerciseCounts[exercise.exerciseName] ?? 0) + 1;
      }
    }

    final sortedExercises =
        exerciseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedExercises.isEmpty) {
      return const Center(child: Text('운동 기록이 없습니다.'));
    }

    final top3Exercises = sortedExercises.take(3).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ...top3Exercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          exercise.key,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        '${exercise.value}회',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseTrendTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top 3 운동 기록 비교',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          _buildExerciseComparisonChart(),
          const SizedBox(height: 24),
          const Text(
            '운동 종류 분포',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildExerciseTypeDistribution(),
        ],
      ),
    );
  }

  Widget _buildExerciseLogTab() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExerciseRecords,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 운동 기록',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (_exerciseRecords.isEmpty && _ptLogExercises.isEmpty)
            const Center(child: Text('최근 30일간의 운동 기록이 없습니다.'))
          else ...[
            if (_ptLogExercises.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
                  ),
                ),
                child: const Text(
                  'PT 운동 기록',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _ptLogExercises.length,
                itemBuilder: (context, index) {
                  final groupedExercise = _ptLogExercises[index];
                  return ExpansionTile(
                    initiallyExpanded: false,
                    title: Text(
                      '${groupedExercise.date.year}년 ${groupedExercise.date.month}월 ${groupedExercise.date.day}일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children:
                        groupedExercise.exercises.map((exercise) {
                          return Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                              side: BorderSide.none,
                            ),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
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
                                    if (exercise.feedback?.isNotEmpty ??
                                        false) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        '피드백:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(exercise.feedback ?? ''),
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
            if (_exerciseRecords.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey[200]!, width: 1.0),
                  ),
                ),
                child: const Text(
                  '개인 운동 기록',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _exerciseRecords.length,
                itemBuilder: (context, index) {
                  final record = _exerciseRecords[index];
                  final date = DateTime.parse(record.date);

                  return ExpansionTile(
                    initiallyExpanded: _selectedDate == record.date,
                    title: Text(
                      '${date.year}년 ${date.month}월 ${date.day}일',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children:
                        record.records
                            .map(
                              (exercise) => Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide.none,
                                ),
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            _buildExerciseDetail(
                                              '무게',
                                              '${exercise.recordData['weight'] ?? 0}kg',
                                            ),
                                            _buildExerciseDetail(
                                              '횟수',
                                              exercise.recordData['reps']
                                                      ?.toString() ??
                                                  '0',
                                            ),
                                            _buildExerciseDetail(
                                              '세트',
                                              exercise.recordData['sets']
                                                      ?.toString() ??
                                                  '0',
                                            ),
                                          ],
                                        ),
                                        if (exercise
                                                .memoData['memo']
                                                ?.isNotEmpty ??
                                            false) ...[
                                          const SizedBox(height: 8),
                                          const Text(
                                            '메모:',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(exercise.memoData['memo'] ?? ''),
                                        ],
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                            .toList(),
                  );
                },
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildExerciseDetail(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildExerciseComparisonChart() {
    if (_exerciseData.isEmpty) {
      return const Center(child: Text('운동 기록이 없습니다.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 250,
          padding: const EdgeInsets.only(
            top: 16,
            left: 0,
            right: 24,
            bottom: 0,
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxWeight() + 10,
              barGroups:
                  _exerciseData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final colors = [
                      Colors.blue,
                      Colors.red,
                      Colors.green,
                      Colors.orange,
                      Colors.purple,
                    ];
                    final color = colors[index % colors.length];

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: data['initialWeight'],
                          color: color.withOpacity(0.5),
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: data['maxWeight'],
                          color: color,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 10,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: Colors.grey.withOpacity(0.3),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      final exercise =
                          _exerciseData[value.toInt()]['exercise'] as String;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          exercise,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Text('초기 기록 (${_formatDate(_exerciseData.first['initialDate'])})'),
            const SizedBox(width: 16),
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            const Text('최고 기록'),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.only(
            top: 8,
            left: 12,
            right: 12,
            bottom: 8,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                _exerciseData.map((data) {
                  final improvement = _formatImprovement(
                    data['initialWeight'] as double,
                    data['maxWeight'] as double,
                  );
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${data['exercise']}: $improvement',
                          style: TextStyle(
                            color:
                                improvement.contains('증가')
                                    ? Colors.green
                                    : improvement.contains('감소')
                                    ? Colors.red
                                    : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '최고 기록: ${_formatDate(data['maxDate'])} (${data['maxType']})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  double _getMaxWeight() {
    double maxWeight = 0;
    for (var data in _exerciseData) {
      maxWeight = math.max(maxWeight, data['initialWeight']);
      maxWeight = math.max(maxWeight, data['maxWeight']);
    }
    return maxWeight;
  }

  List<Map<String, dynamic>> get _exerciseData {
    final Map<String, List<Map<String, dynamic>>> exerciseRecords = {};

    // 개인 운동 기록 수집
    for (var record in _exerciseRecords) {
      final recordDate = DateTime.parse(record.date);
      for (var exercise in record.records) {
        final weight = (exercise.recordData['weight'] as int? ?? 0).toDouble();
        if (!exerciseRecords.containsKey(exercise.exerciseName)) {
          exerciseRecords[exercise.exerciseName] = [];
        }
        exerciseRecords[exercise.exerciseName]!.add({
          'weight': weight,
          'date': recordDate,
          'type': '개인',
        });
      }
    }

    // PT 운동 기록 수집
    for (var record in _ptLogExercises) {
      for (var exercise in record.exercises) {
        if (!exerciseRecords.containsKey(exercise.exerciseName)) {
          exerciseRecords[exercise.exerciseName] = [];
        }
        exerciseRecords[exercise.exerciseName]!.add({
          'weight': exercise.weight.toDouble(),
          'date': record.date,
          'type': 'PT',
        });
      }
    }

    // 각 운동별로 초기 기록과 최고 중량 기록 찾기
    final List<Map<String, dynamic>> result = [];
    for (var entry in exerciseRecords.entries) {
      final records = entry.value;
      if (records.length < 2) continue; // 최소 2개 이상의 기록이 있는 운동만 포함

      records.sort(
        (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
      );

      // 최고 중량 기록 찾기
      final maxWeightRecord = records.reduce(
        (curr, next) =>
            (curr['weight'] as double) > (next['weight'] as double)
                ? curr
                : next,
      );

      result.add({
        'exercise': entry.key,
        'initialWeight': records.first['weight'],
        'maxWeight': maxWeightRecord['weight'],
        'initialDate': records.first['date'],
        'maxDate': maxWeightRecord['date'],
        'maxType': maxWeightRecord['type'],
      });
    }

    // 운동 횟수 기준으로 상위 3개 운동 선택
    final exerciseCounts = <String, int>{};
    for (var record in _exerciseRecords) {
      for (var exercise in record.records) {
        exerciseCounts[exercise.exerciseName] =
            (exerciseCounts[exercise.exerciseName] ?? 0) + 1;
      }
    }
    for (var record in _ptLogExercises) {
      for (var exercise in record.exercises) {
        exerciseCounts[exercise.exerciseName] =
            (exerciseCounts[exercise.exerciseName] ?? 0) + 1;
      }
    }

    final sortedExercises =
        exerciseCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final top3Exercises = sortedExercises.take(3).map((e) => e.key).toSet();

    return result
        .where((data) => top3Exercises.contains(data['exercise']))
        .toList();
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }

  String _formatImprovement(double initialWeight, double maxWeight) {
    final improvement = (maxWeight - initialWeight).toInt();
    if (improvement > 0) {
      return '초기 대비 ${improvement}Kg 증가했습니다.';
    } else if (improvement < 0) {
      return '초기 대비 ${improvement.abs()}Kg 감소했습니다.';
    } else {
      return '초기 무게를 유지하고 있습니다.';
    }
  }

  Widget _buildExerciseTypeDistribution() {
    final exerciseTypes = <String, int>{};

    // 개인 운동 기록 수집
    for (var record in _exerciseRecords) {
      for (var exercise in record.records) {
        exerciseTypes[exercise.exerciseName] =
            (exerciseTypes[exercise.exerciseName] ?? 0) + 1;
      }
    }

    // PT 운동 기록 수집
    for (var record in _ptLogExercises) {
      for (var exercise in record.exercises) {
        exerciseTypes[exercise.exerciseName] =
            (exerciseTypes[exercise.exerciseName] ?? 0) + 1;
      }
    }

    // 더 선명한 색상 팔레트 정의
    final colors = [
      const Color(0xFF2196F3), // 파랑
      const Color(0xFF4CAF50), // 초록
      const Color(0xFFFFC107), // 노랑
      const Color(0xFFE91E63), // 분홍
      const Color(0xFF9C27B0), // 보라
      const Color(0xFF00BCD4), // 하늘
      const Color(0xFFFF5722), // 주황
      const Color(0xFF795548), // 갈색
    ];

    final total = exerciseTypes.values.fold<int>(
      0,
      (sum, count) => sum + count,
    );

    final entries = exerciseTypes.entries.toList();
    final sections =
        entries.asMap().entries.map((entry) {
          final index = entry.key;
          final exercise = entry.value;
          final percentage = (exercise.value / total * 100).round();
          final color = colors[index % colors.length];
          final isSelected = _selectedExerciseIndex == index;

          return PieChartSectionData(
            value: exercise.value.toDouble(),
            title: '$percentage%',
            color: color,
            radius: isSelected ? 70 : 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 파이 차트 부분
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sections: sections,
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(width: 48),
          // 칩들 부분
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...entries
                    .asMap()
                    .entries
                    .map((entry) {
                      final index = entry.key;
                      final exercise = entry.value;
                      final percentage = (exercise.value / total * 100).round();
                      final color = colors[index % colors.length];
                      final isSelected = _selectedExerciseIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedExerciseIndex =
                                  isSelected ? null : index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: color.withOpacity(isSelected ? 0.3 : 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: color, width: 1.5),
                            ),
                            child: Text(
                              '${exercise.key} ($percentage%)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.bold
                                        : FontWeight.w500,
                                color: color,
                              ),
                            ),
                          ),
                        ),
                      );
                    })
                    .take(_isChipsExpanded ? entries.length : 3)
                    .toList(),
                if (entries.length > 3)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isChipsExpanded = !_isChipsExpanded;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _isChipsExpanded ? '접기' : '더보기',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _isChipsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            size: 16,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DietReportTab extends StatefulWidget {
  final int ptContractId;

  const DietReportTab({super.key, required this.ptContractId});

  @override
  State<DietReportTab> createState() => _DietReportTabState();
}

class _DietReportTabState extends State<DietReportTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['종합', '영양소 분석', '식사 패턴', '식단 갤러리'];
  Report? _currentReport;
  bool _isLoading = true;
  String? _error;
  bool _isDisposed = false; // dispose 상태 추적을 위한 플래그 추가

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _loadReport();
  }

  Future<void> _loadReport() async {
    if (_isDisposed) return; // dispose된 상태면 early return
    try {
      final reports = await ReportService.getLatestReports(widget.ptContractId);
      if (_isDisposed || !mounted) return; // 두 번째 체크
      setState(() {
        _currentReport = reports.isNotEmpty ? reports[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      if (_isDisposed || !mounted) return; // 두 번째 체크
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _isDisposed = true; // dispose 상태 설정
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReport, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_currentReport == null) {
      return const Center(child: Text('식단 리포트가 없습니다.'));
    }

    return Column(
      children: [
        TabBar(
          controller: _tabController,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          dividerColor: Colors.grey[300],
          dividerHeight: 1.0,
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverallTab(),
              _buildNutritionAnalysisTab(),
              _buildMealPatternTab(),
              _buildDietGalleryTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverallTab() {
    final dietReport = _currentReport!.dietReport;
    final dietData = [
      ReportData(
        category: '식단 평가 점수',
        score: (dietReport.dietScore ?? 0).toDouble(),
        description: dietReport.recentDietPattern ?? '데이터가 없습니다.',
      ),
      ReportData(
        category: '강점 및 잘 구성된 습관',
        score: 80,
        description: dietReport.strengths ?? '데이터가 없습니다.',
      ),
      ReportData(
        category: '개선이 필요한 부분',
        score: 50,
        description: dietReport.problems ?? '데이터가 없습니다.',
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '식단 리포트',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...dietData.map((data) => _ReportCard(data: data)),
          const SizedBox(height: 24),
          const Text(
            '트레이너 코멘트',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                dietReport.trainerMent ?? '데이터가 없습니다.',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionAnalysisTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '일일 영양소 섭취량',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: 60,
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: 80,
                        color: Colors.green,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: 40,
                        color: Colors.orange,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const titles = ['단백질', '탄수화물', '지방'];
                        return Text(titles[value.toInt()]);
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '주간 칼로리 추이',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 1800),
                      const FlSpot(1, 2000),
                      const FlSpot(2, 2200),
                      const FlSpot(3, 1900),
                      const FlSpot(4, 2100),
                      const FlSpot(5, 2500),
                      const FlSpot(6, 2300),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMealPatternTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '식사 시간대 분포',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: 30,
                    title: '아침',
                    color: Colors.orange,
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: 40,
                    title: '점심',
                    color: Colors.blue,
                    radius: 80,
                  ),
                  PieChartSectionData(
                    value: 30,
                    title: '저녁',
                    color: Colors.purple,
                    radius: 80,
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 30,
              ),
            ),
          ),
          const SizedBox(height: 60),
          const Text(
            '주간 식사 패턴',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: true),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['월', '화', '수', '목', '금', '토', '일'];
                        return Text(days[value.toInt()]);
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 3),
                      const FlSpot(1, 4),
                      const FlSpot(2, 3),
                      const FlSpot(3, 4),
                      const FlSpot(4, 3),
                      const FlSpot(5, 5),
                      const FlSpot(6, 4),
                    ],
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.green.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDietGalleryTab() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Expanded(
                child: Image.network(
                  'https://picsum.photos/200/200?random=$index',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '식단 ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class InbodyReportTab extends StatefulWidget {
  final int ptContractId;

  const InbodyReportTab({super.key, required this.ptContractId});

  @override
  State<InbodyReportTab> createState() => _InbodyReportTabState();
}

class _InbodyReportTabState extends State<InbodyReportTab> {
  Report? _currentReport;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    try {
      final reports = await ReportService.getLatestReports(widget.ptContractId);
      setState(() {
        _currentReport = reports.isNotEmpty ? reports[0] : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('오류가 발생했습니다: $_error'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadReport, child: const Text('다시 시도')),
          ],
        ),
      );
    }

    if (_currentReport == null) {
      return const Center(child: Text('인바디 리포트가 없습니다.'));
    }

    final inbodyReport = _currentReport!.inbodyReport;
    final inbodyData = [
      ReportData(
        category: 'BMI 점수',
        score: inbodyReport.bmiScore.toDouble(),
        description: inbodyReport.bmiAnalysis,
      ),
      ReportData(
        category: '골격근량 점수',
        score: inbodyReport.skeletalMuscleScore.toDouble(),
        description: inbodyReport.skeletalMuscleAnalysis,
      ),
      ReportData(
        category: '체지방률 점수',
        score: inbodyReport.bodyFatScore.toDouble(),
        description: inbodyReport.bodyFatAnalysis,
      ),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '인바디 리포트',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          ...inbodyData.map((data) => _ReportCard(data: data)),
          const SizedBox(height: 24),
          const Text(
            '인바디 평가',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                inbodyReport.summary,
                style: const TextStyle(fontSize: 14),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '트레이너 코멘트',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                inbodyReport.trainerMent,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.blue,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final ReportData data;

  const _ReportCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.category,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: data.score / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getScoreColor(data.score),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              data.description,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }
}

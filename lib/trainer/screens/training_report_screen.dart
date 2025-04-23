// ignore_for_file: deprecated_member_use

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../models/report.dart';
import '../../services/report_service.dart';

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
  const TrainingReportScreen({super.key});

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
          bottom: const TabBar(
            labelColor: Colors.black,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.blue,
            tabs: [
              Tab(text: '비교'),
              Tab(text: '운동'),
              Tab(text: '식단'),
              Tab(text: '인바디'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ReportComparisonTab(ptContractId: 10,),
            ExerciseReportTab(),
            DietReportTab(),
            InbodyReportTab(),
          ],
        ),
      ),
    );
  }
}

class ReportComparisonTab extends StatefulWidget {
  final int ptContractId;
  
  const ReportComparisonTab({
    super.key,
    required this.ptContractId,
  });

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
      _controller.forward();
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
            ElevatedButton(
              onPressed: _loadReports,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_reports == null || _reports!.length < 2) {
      return const Center(
        child: Text('비교할 리포트가 충분하지 않습니다.'),
      );
    }

    final currentReport = _reports![1];
    final previousReport = _reports![0];

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
          const SizedBox(height: 24),
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
                          _selectedDataSetIndex == 1 ? 0.5 : 0.3,
                        ),
                        borderColor: Colors.green,
                        borderWidth: _selectedDataSetIndex == 1 ? 3 : 2,
                        entryRadius: 4,
                        dataEntries: [
                          RadarEntry(
                            value: previousReport.exerciseReport.diligenceScore.toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value: previousReport.exerciseReport.personalExerciseScore.toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value: (previousReport.dietReport.dietScore ?? 0).toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value: previousReport.inbodyReport.bmiScore.toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value: previousReport.inbodyReport.bodyFatScore.toDouble() *
                                _greenAnimation.value,
                          ),
                          RadarEntry(
                            value: previousReport.inbodyReport.skeletalMuscleScore.toDouble() *
                                _greenAnimation.value,
                          ),
                        ],
                      ),
                      RadarDataSet(
                        fillColor: Colors.blue.withOpacity(
                          _selectedDataSetIndex == 0 ? 0.5 : 0.3,
                        ),
                        borderColor: Colors.blue,
                        borderWidth: _selectedDataSetIndex == 0 ? 3 : 2,
                        entryRadius: 4,
                        dataEntries: [
                          RadarEntry(
                            value: currentReport.exerciseReport.diligenceScore.toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value: currentReport.exerciseReport.personalExerciseScore.toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value: (currentReport.dietReport.dietScore ?? 0).toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value: currentReport.inbodyReport.bmiScore.toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value: currentReport.inbodyReport.bodyFatScore.toDouble() *
                                _blueAnimation.value,
                          ),
                          RadarEntry(
                            value: currentReport.inbodyReport.skeletalMuscleScore.toDouble() *
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
                      color: Colors.grey.withOpacity(0.5),
                      width: 0.5,
                    ),
                    radarBorderData: BorderSide(
                      color: Colors.grey.withOpacity(0.5),
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
            title: '운동 리포트',
            data: _showCurrentData
                ? currentReport.exerciseReport
                : previousReport.exerciseReport,
          ),
          const SizedBox(height: 24),
          _ReportDetailSection(
            title: '식단 리포트',
            data: _showCurrentData
                ? currentReport.dietReport
                : previousReport.dietReport,
          ),
          const SizedBox(height: 24),
          _ReportDetailSection(
            title: '인바디 리포트',
            data: _showCurrentData
                ? currentReport.inbodyReport
                : previousReport.inbodyReport,
          ),
        ],
      ),
    );
  }
}

class _ReportDetailSection extends StatelessWidget {
  final String title;
  final dynamic data;

  const _ReportDetailSection({required this.title, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title == '운동 리포트') ...[
                  _buildScoreRow('성실도 점수', (data as ExerciseReport).diligenceScore),
                  _buildScoreRow('개인운동 점수', (data as ExerciseReport).personalExerciseScore),
                  const SizedBox(height: 16),
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
                ] else if (title == '식단 리포트') ...[
                  _buildScoreRow('식단 평가 점수', (data as DietReport).dietScore ?? 0),
                  const SizedBox(height: 16),
                  _buildSectionTitle('식단 평가 요약'),
                  Text(
                    (data as DietReport).recentDietPattern ?? '데이터가 없습니다.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('식단 강점'),
                  Text(
                    (data as DietReport).strengths ?? '데이터가 없습니다.',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  _buildSectionTitle('개선 사항'),
                  Text(
                    (data as DietReport).problems ?? '데이터가 없습니다.',
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
                      (data as DietReport).trainerMent ?? '데이터가 없습니다.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ] else if (title == '인바디 리포트') ...[
                  _buildScoreRow('BMI 점수', (data as InbodyReport).bmiScore),
                  _buildScoreRow('골격근량 점수', (data as InbodyReport).skeletalMuscleScore),
                  _buildScoreRow('체지방률 점수', (data as InbodyReport).bodyFatScore),
                  const SizedBox(height: 16),
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
      ],
    );
  }

  Widget _buildScoreRow(String label, dynamic score) {
    final int scoreValue = score is int ? score : 0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _getScoreColor(scoreValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _getScoreColor(scoreValue), width: 1),
            ),
            child: Text(
              '$scoreValue점',
              style: TextStyle(
                fontSize: 14,
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
  const ExerciseReportTab({super.key});

  @override
  State<ExerciseReportTab> createState() => _ExerciseReportTabState();
}

class _ExerciseReportTabState extends State<ExerciseReportTab>
    with SingleTickerProviderStateMixin {
  // 상수 및 변수 선언
  late TabController _tabController;
  final List<String> _tabs = ['종합', '운동 추이', 'PT 비교', '운동 기록'];

  // 샘플 데이터
  final List<Map<String, dynamic>> weeklyData = [
    {'week': '1주차', 'count': 3},
    {'week': '2주차', 'count': 4},
    {'week': '3주차', 'count': 2},
    {'week': '4주차', 'count': 5},
  ];

  final List<Map<String, dynamic>> exerciseData = [
    {'exercise': '벤치프레스', 'weight': 80, 'reps': 8},
    {'exercise': '데드리프트', 'weight': 120, 'reps': 5},
    {'exercise': '스쿼트', 'weight': 100, 'reps': 10},
  ];

  // 생명주기 메서드
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // UI 빌드 메서드
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
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildSummaryTab(),
              _buildExerciseTrendTab(),
              _buildPTComparisonTab(),
              _buildExerciseLogTab(),
            ],
          ),
        ),
      ],
    );
  }

  // 탭별 위젯 빌드 메서드
  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '운동 성과 요약',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildSummaryCard(),
        ],
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
            '주간 운동 추이',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildWeeklyTrendChart(),
          const SizedBox(height: 32),
          const Text(
            '주요 운동별 추이',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildExerciseComparisonChart(),
        ],
      ),
    );
  }

  Widget _buildPTComparisonTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PT 수업과 자율 훈련 비교',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 32),
          _buildPTComparisonChart(),
        ],
      ),
    );
  }

  Widget _buildExerciseLogTab() {
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
          _buildExerciseLogList(),
        ],
      ),
    );
  }

  // 차트 관련 메서드
  Widget _buildWeeklyTrendChart() {
    return SizedBox(
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
                  return Text(weeklyData[value.toInt()]['week'] as String);
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots:
                  weeklyData.asMap().entries.map((entry) {
                    return FlSpot(
                      entry.key.toDouble(),
                      (entry.value['count'] as int).toDouble(),
                    );
                  }).toList(),
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseComparisonChart() {
    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 150,
          barGroups:
              exerciseData.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: (entry.value['weight'] as int).toDouble(),
                      color: Colors.blue,
                      width: 20,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                    ),
                  ],
                );
              }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const titles = ['벤치프레스', '데드리프트', '스쿼트'];
                  return Text(titles[value.toInt()]);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPTComparisonChart() {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              value: 60,
              title: 'PT 수업\n60%',
              color: Colors.blue,
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              value: 40,
              title: '자율 훈련\n40%',
              color: Colors.green,
              radius: 100,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 유틸리티 메서드
  Widget _buildSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryItem('주간 운동 횟수', '4회'),
            _buildSummaryItem('평균 운동 시간', '1시간 30분'),
            _buildSummaryItem('주요 운동', '벤치프레스, 데드리프트, 스쿼트'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseLogList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: exerciseData.length,
      itemBuilder: (context, index) {
        final exercise = exerciseData[index];
        return Card(
          child: ListTile(
            title: Text(exercise['exercise'] as String),
            subtitle: Text('${exercise['weight']}kg x ${exercise['reps']}회'),
            trailing: const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class DietReportTab extends StatefulWidget {
  const DietReportTab({super.key});

  @override
  State<DietReportTab> createState() => _DietReportTabState();
}

class _DietReportTabState extends State<DietReportTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['종합', '영양소 분석', '식사 패턴', '식단 갤러리'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
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
    final dietData = [
      ReportData(
        category: '식단 평가 점수',
        score: 65,
        description:
            '현재 식단은 기본적인 영양소 균형은 갖추었으나, 단백질 섭취량이 목표치에 비해 부족하고, 탄수화물의 비중이 높은 편입니다.',
      ),
      ReportData(
        category: '강점 및 잘 구성된 습관',
        score: 80,
        description:
            '닭가슴살과 같은 저지방 고단백 식품을 주로 섭취하는 점은 체형 관리 목표에 부합합니다. 또한, 다양한 과일과 채소(블루베리, 사과 등)를 포함하여 비타민과 미네랄 섭취를 고려한 점이 긍정적입니다.',
      ),
      ReportData(
        category: '개선이 필요한 부분',
        score: 50,
        description:
            '간식 섭취가 잦고, 특히 저녁 시간대의 과도한 탄수화물 섭취가 체지방 감소에 방해가 되고 있습니다. 또한, 수분 섭취량이 부족한 편입니다.',
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

class InbodyReportTab extends StatelessWidget {
  const InbodyReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final inbodyData = [
      ReportData(
        category: 'BMI 점수',
        score: 80,
        description: '현재 BMI 21은 적정 범위인 21~23에 해당하여 80점 이상으로 평가됩니다.',
      ),
      ReportData(
        category: '골격근량 점수',
        score: 85,
        description: '현재 골격근량 33.0kg은 남성 기준 32kg 이상에 해당하여 80점 이상으로 평가됩니다.',
      ),
      ReportData(
        category: '체지방률 점수',
        score: 85,
        description: '현재 체지방률 17.4%는 남성 기준 13~17%에 해당하여 80점 이상으로 평가됩니다.',
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

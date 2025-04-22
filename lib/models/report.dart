class Report {
  final ExerciseReport exerciseReport;
  final DietReport dietReport;
  final InbodyReport inbodyReport;
  final DateTime createdAt;

  Report({
    required this.exerciseReport,
    required this.dietReport,
    required this.inbodyReport,
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      exerciseReport: ExerciseReport.fromJson(json['exerciseReport']),
      dietReport: DietReport.fromJson(json['dietReport']),
      inbodyReport: InbodyReport.fromJson(json['inbodyReport']),
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'exerciseReport': exerciseReport.toJson(),
      'dietReport': dietReport.toJson(),
      'inbodyReport': inbodyReport.toJson(),
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class ExerciseReport {
  final int diligenceScore;
  final int personalExerciseScore;
  final String diligenceScoreReason;
  final String strengthsAndGoodHabits;
  final String personalExerciseScoreReason;
  final String improvementSuggestions;
  final String trainerMent;
  final String progressStatus;
  final String recentTrainingPattern;
  final String ptClassConsistency;
  final String weaknesses;

  ExerciseReport({
    required this.diligenceScore,
    required this.personalExerciseScore,
    required this.diligenceScoreReason,
    required this.strengthsAndGoodHabits,
    required this.personalExerciseScoreReason,
    required this.improvementSuggestions,
    required this.trainerMent,
    required this.progressStatus,
    required this.recentTrainingPattern,
    required this.ptClassConsistency,
    required this.weaknesses,
  });

  factory ExerciseReport.fromJson(Map<String, dynamic> json) {
    return ExerciseReport(
      diligenceScore: json['성실도 점수'],
      personalExerciseScore: json['개인운동 점수'],
      diligenceScoreReason: json['성실도 점수 근거'],
      strengthsAndGoodHabits: json['강점 및 좋은 습관'],
      personalExerciseScoreReason: json['개인운동 점수 근거'],
      improvementSuggestions: json['구체적인 개선 제안'],
      trainerMent: json['트레이너 멘트 제안'],
      progressStatus: json['계획 대비 진행 상태'],
      recentTrainingPattern: json['최근 훈련 패턴 요약'],
      ptClassConsistency: json['PT 수업과의 일치 여부'],
      weaknesses: json['약점 또는 비효율적인 부분'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '성실도 점수': diligenceScore,
      '개인운동 점수': personalExerciseScore,
      '성실도 점수 근거': diligenceScoreReason,
      '강점 및 좋은 습관': strengthsAndGoodHabits,
      '개인운동 점수 근거': personalExerciseScoreReason,
      '구체적인 개선 제안': improvementSuggestions,
      '트레이너 멘트 제안': trainerMent,
      '계획 대비 진행 상태': progressStatus,
      '최근 훈련 패턴 요약': recentTrainingPattern,
      'PT 수업과의 일치 여부': ptClassConsistency,
      '약점 또는 비효율적인 부분': weaknesses,
    };
  }
}

class DietReport {
  final int? dietScore;
  final String? scoreReason;
  final String? improvementSuggestions;
  final String? trainerMent;
  final String? recentDietPattern;
  final String? strengths;
  final String? problems;

  DietReport({
    this.dietScore,
    this.scoreReason,
    this.improvementSuggestions,
    this.trainerMent,
    this.recentDietPattern,
    this.strengths,
    this.problems,
  });

  factory DietReport.fromJson(Map<String, dynamic> json) {
    if (json.isEmpty) return DietReport();
    
    return DietReport(
      dietScore: json['식단 평가 점수'],
      scoreReason: json['점수 평가 근거'],
      improvementSuggestions: json['구체적인 개선 제안'],
      trainerMent: json['트레이너 멘트 제안'],
      recentDietPattern: json['최근 식사 패턴 요약'],
      strengths: json['강점 및 잘 구성된 습관'],
      problems: json['문제점 또는 개선이 필요한 부분'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '식단 평가 점수': dietScore,
      '점수 평가 근거': scoreReason,
      '구체적인 개선 제안': improvementSuggestions,
      '트레이너 멘트 제안': trainerMent,
      '최근 식사 패턴 요약': recentDietPattern,
      '강점 및 잘 구성된 습관': strengths,
      '문제점 또는 개선이 필요한 부분': problems,
    };
  }
}

class InbodyReport {
  final String bmiAnalysis;
  final int bmiScore;
  final String improvementSuggestions;
  final String summary;
  final String bmiScoreReason;
  final String skeletalMuscleAnalysis;
  final int skeletalMuscleScore;
  final String bodyFatAnalysis;
  final int bodyFatScore;
  final String skeletalMuscleScoreReason;
  final String bodyFatScoreReason;
  final String trainerMent;

  InbodyReport({
    required this.bmiAnalysis,
    required this.bmiScore,
    required this.improvementSuggestions,
    required this.summary,
    required this.bmiScoreReason,
    required this.skeletalMuscleAnalysis,
    required this.skeletalMuscleScore,
    required this.bodyFatAnalysis,
    required this.bodyFatScore,
    required this.skeletalMuscleScoreReason,
    required this.bodyFatScoreReason,
    required this.trainerMent,
  });

  factory InbodyReport.fromJson(Map<String, dynamic> json) {
    return InbodyReport(
      bmiAnalysis: json['BMI 분석'],
      bmiScore: json['BMI 점수'],
      improvementSuggestions: json['개선 제안'],
      summary: json['종합 요약'],
      bmiScoreReason: json['BMI 점수 근거'],
      skeletalMuscleAnalysis: json['골격근량 분석'],
      skeletalMuscleScore: json['골격근량 점수'],
      bodyFatAnalysis: json['체지방률 분석'],
      bodyFatScore: json['체지방률 점수'],
      skeletalMuscleScoreReason: json['골격근량 점수 근거'],
      bodyFatScoreReason: json['체지방률 점수 근거'],
      trainerMent: json['트레이너 멘트 제안'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'BMI 분석': bmiAnalysis,
      'BMI 점수': bmiScore,
      '개선 제안': improvementSuggestions,
      '종합 요약': summary,
      'BMI 점수 근거': bmiScoreReason,
      '골격근량 분석': skeletalMuscleAnalysis,
      '골격근량 점수': skeletalMuscleScore,
      '체지방률 분석': bodyFatAnalysis,
      '체지방률 점수': bodyFatScore,
      '골격근량 점수 근거': skeletalMuscleScoreReason,
      '체지방률 점수 근거': bodyFatScoreReason,
      '트레이너 멘트 제안': trainerMent,
    };
  }
} 
import 'package:flutter/foundation.dart';

class ExerciseRecord {
  final int exerciseId;
  final String exerciseName;
  final Map<String, dynamic> recordData;
  final Map<String, dynamic> memoData;

  ExerciseRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.recordData,
    required this.memoData,
  });

  factory ExerciseRecord.fromJson(Map<String, dynamic> json) {
    try {
      return ExerciseRecord(
        exerciseId: json['exerciseId'] as int,
        exerciseName: json['exerciseName'] as String,
        recordData: {
          'reps': json['reps'],
          'sets': json['sets'],
          'weight': json['weight'],
        },
        memoData: {
          'memo': json['memo'],
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing ExerciseRecord: $e');
        print('JSON: $json');
      }
      // 오류 발생 시 기본값으로 안전하게 생성
      return ExerciseRecord(
        exerciseId: json['exerciseId'] as int? ?? 0,
        exerciseName: json['exerciseName'] as String? ?? '알 수 없는 운동',
        recordData: {},
        memoData: {},
      );
    }
  }

  Map<String, String> get translatedRecordData {
    final Map<String, String> translated = {};
    for (var entry in recordData.entries) {
      if (entry.key == 'memo') continue;
      
      String keyName = entry.key;
      switch (entry.key) {
        case 'reps':
          keyName = '횟수';
          break;
        case 'sets':
          keyName = '세트';
          break;
        case 'weight':
          keyName = '무게';
          break;
      }
      translated[keyName] = entry.value?.toString() ?? '없음';
    }
    return translated;
  }
}

class GroupedExerciseRecord {
  final String date;
  final List<ExerciseRecord> records;

  GroupedExerciseRecord({
    required this.date,
    required this.records,
  });

  factory GroupedExerciseRecord.fromJson(Map<String, dynamic> json) {
    try {
      return GroupedExerciseRecord(
        date: json['date'] as String,
        records: (json['exercises'] as List<dynamic>?)
                ?.map((e) => ExerciseRecord.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error parsing GroupedExerciseRecord: $e');
        print('JSON: $json');
      }
      // 오류 발생 시 빈 레코드로 안전하게 생성
      return GroupedExerciseRecord(
        date: json['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0],
        records: [],
      );
    }
  }
} 
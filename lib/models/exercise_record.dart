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
    return ExerciseRecord(
      exerciseId: json['exerciseId'],
      exerciseName: json['exerciseName'],
      recordData: json['recordData'] ?? {},
      memoData: json['memoData'] ?? {},
    );
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
    return GroupedExerciseRecord(
      date: json['date'],
      records: (json['records'] as List)
          .map((record) => ExerciseRecord.fromJson(record))
          .toList(),
    );
  }
} 
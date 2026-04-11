import 'package:equatable/equatable.dart';

class QuestionModel extends Equatable {
  final int index;
  final String topicName;
  final String questionText;
  final int timeLimitSeconds;
  final bool isAnswered;
  final String? videoUrl;

  const QuestionModel({
    required this.index,
    required this.topicName,
    required this.questionText,
    required this.timeLimitSeconds,
    required this.isAnswered,
    this.videoUrl,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      index: json['index'] ?? 0,
      topicName: json['topicName'] ?? '',
      questionText: json['questionText'] ?? '',
      timeLimitSeconds: json['timeLimitSeconds'] ?? 0,
      isAnswered: json['isAnswered'] ?? false,
      videoUrl: json['videoUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'index': index,
      'topicName': topicName,
      'questionText': questionText,
      'timeLimitSeconds': timeLimitSeconds,
      'isAnswered': isAnswered,
      'videoUrl': videoUrl,
    };
  }

  QuestionModel copyWith({
    int? index,
    String? topicName,
    String? questionText,
    int? timeLimitSeconds,
    bool? isAnswered,
    String? videoUrl,
  }) {
    return QuestionModel(
      index: index ?? this.index,
      topicName: topicName ?? this.topicName,
      questionText: questionText ?? this.questionText,
      timeLimitSeconds: timeLimitSeconds ?? this.timeLimitSeconds,
      isAnswered: isAnswered ?? this.isAnswered,
      videoUrl: videoUrl ?? this.videoUrl,
    );
  }

  @override
  List<Object?> get props => [
        index,
        topicName,
        questionText,
        timeLimitSeconds,
        isAnswered,
        videoUrl,
      ];
}

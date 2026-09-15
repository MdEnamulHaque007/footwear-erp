import 'package:equatable/equatable.dart';

import '../../../domain/entities/timelapse/timelapse_data_entity.dart';

sealed class TimelapseState extends Equatable {
  const TimelapseState();

  @override
  List<Object?> get props => [];
}

class TimelapseInitial extends TimelapseState {
  const TimelapseInitial();
}

class TimelapseLoading extends TimelapseState {
  const TimelapseLoading();
}

class TimelapseLoaded extends TimelapseState {
  const TimelapseLoaded({
    required this.data,
    required this.durationSeconds,
    this.isPlaying = false,
    this.progress = 0,
    this.visiblePoints = 0,
    this.playbackSpeed = 1,
  });

  final TimelapseData data;
  final int durationSeconds;
  final bool isPlaying;
  final double progress;
  final int visiblePoints;
  final double playbackSpeed;

  int get elapsedSeconds => (durationSeconds * progress).round();

  TimelapseLoaded copyWith({
    bool? isPlaying,
    double? progress,
    int? visiblePoints,
    double? playbackSpeed,
  }) => TimelapseLoaded(
    data: data,
    durationSeconds: durationSeconds,
    isPlaying: isPlaying ?? this.isPlaying,
    progress: progress ?? this.progress,
    visiblePoints: visiblePoints ?? this.visiblePoints,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
  );

  @override
  List<Object?> get props => [
    data,
    durationSeconds,
    isPlaying,
    progress,
    visiblePoints,
    playbackSpeed,
  ];
}

class TimelapseError extends TimelapseState {
  const TimelapseError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

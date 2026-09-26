/// ============================================================================
/// ফাইল: lib/presentation/blocs/timelapse/timelapse_state.dart
/// স্তর: Presentation BLoC | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: TimelapseState, TimelapseInitial, TimelapseLoading, TimelapseLoaded, TimelapseError
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
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

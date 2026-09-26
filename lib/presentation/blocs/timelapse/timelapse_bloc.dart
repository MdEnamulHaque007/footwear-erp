/// ============================================================================
/// ফাইল: lib/presentation/blocs/timelapse/timelapse_bloc.dart
/// স্তর: Presentation BLoC | মডিউল: Time-lapse Dashboard
/// উদ্দেশ্য: Time-lapse Dashboard screen-এর event গ্রহণ করে state তৈরি এবং UI update নিয়ন্ত্রণ করে।
/// প্রধান অংশ: TimelapseBloc
/// ডেটা প্রবাহ: UI → BLoC/Use Case → Repository → Firebase; এই ফাইলটি তার নির্ধারিত স্তরের দায়িত্বই পালন করে।
/// রক্ষণাবেক্ষণ নির্দেশনা: business rule পরিবর্তনের সময় সংশ্লিষ্ট validation, permission ও unit test একসঙ্গে পর্যালোচনা করুন।
/// সতর্কতা: এই বাংলা documentation কেবল ব্যাখ্যার জন্য; executable logic বা public API পরিবর্তন করে না।
/// ============================================================================
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/timelapse/get_timelapse_data_usecase.dart';
import 'timelapse_event.dart';
import 'timelapse_state.dart';

class TimelapseBloc extends Bloc<TimelapseEvent, TimelapseState> {
  TimelapseBloc({required GetTimelapseDataUseCase getTimelapseData})
    : _getTimelapseData = getTimelapseData,
      super(const TimelapseInitial()) {
    on<LoadTimelapseData>(_onLoadTimelapseData);
    on<PlayTimelapse>(_onPlay);
    on<PauseTimelapse>(_onPause);
    on<ResetTimelapse>(_onReset);
    on<SetPlaybackSpeed>(_onSetPlaybackSpeed);
    on<TickTimelapse>(_onTick);
  }

  final GetTimelapseDataUseCase _getTimelapseData;
  Timer? _timer;

  Future<void> _onLoadTimelapseData(
    LoadTimelapseData event,
    Emitter<TimelapseState> emit,
  ) async {
    _stopTimer();
    if (emit.isDone) return;
    final config = event.config;
    if (config.departments.isEmpty) {
      emit(const TimelapseError('Select at least one department.'));
      return;
    }
    if (!config.fromDate.isBefore(config.toDate)) {
      emit(const TimelapseError('The start date must be before the end date.'));
      return;
    }
    if (config.durationSeconds < 30 || config.durationSeconds > 120) {
      emit(const TimelapseError('Duration must be between 30 and 120 seconds.'));
      return;
    }

    emit(const TimelapseLoading());
    final result = await _getTimelapseData(config);
    if (emit.isDone) return;
    result.fold(
      (message) => emit(TimelapseError(message)),
      (data) => emit(
        TimelapseLoaded(data: data, durationSeconds: config.durationSeconds),
      ),
    );
  }

  Future<void> _onPlay(
    PlayTimelapse event,
    Emitter<TimelapseState> emit,
  ) async {
    if (emit.isDone) return;
    final current = state;
    if (current is! TimelapseLoaded) return;
    if (current.visiblePoints >= current.data.totalPoints) {
      emit(current.copyWith(isPlaying: false));
      return;
    }
    emit(current.copyWith(isPlaying: true));
    _startTimer();
  }

  Future<void> _onPause(
    PauseTimelapse event,
    Emitter<TimelapseState> emit,
  ) async {
    _stopTimer();
    if (emit.isDone) return;
    final current = state;
    if (current is TimelapseLoaded) emit(current.copyWith(isPlaying: false));
  }

  Future<void> _onReset(
    ResetTimelapse event,
    Emitter<TimelapseState> emit,
  ) async {
    _stopTimer();
    if (emit.isDone) return;
    final current = state;
    if (current is TimelapseLoaded) {
      emit(current.copyWith(isPlaying: false, visiblePoints: 0, progress: 0));
    }
  }

  Future<void> _onSetPlaybackSpeed(
    SetPlaybackSpeed event,
    Emitter<TimelapseState> emit,
  ) async {
    if (emit.isDone) return;
    final current = state;
    if (current is! TimelapseLoaded) return;
    final speed = event.speed.clamp(0.5, 2.0).toDouble();
    emit(current.copyWith(playbackSpeed: speed));
    if (current.isPlaying) _startTimer();
  }

  Future<void> _onTick(
    TickTimelapse event,
    Emitter<TimelapseState> emit,
  ) async {
    if (emit.isDone) return;
    final current = state;
    if (current is! TimelapseLoaded || !current.isPlaying) return;
    final next = math.min(event.visiblePoints, current.data.totalPoints).toInt();
    final complete = next >= current.data.totalPoints;
    if (complete) _stopTimer();
    emit(
      current.copyWith(
        visiblePoints: next,
        progress: current.data.totalPoints == 0 ? 0 : next / current.data.totalPoints,
        isPlaying: !complete,
      ),
    );
  }

  void _startTimer() {
    _stopTimer();
    final current = state;
    if (current is! TimelapseLoaded || !current.isPlaying) return;
    final milliseconds = math.max(
      16,
      ((current.durationSeconds * 1000) /
              current.data.totalPoints /
              current.playbackSpeed)
          .round(),
    ).toInt();
    _timer = Timer.periodic(Duration(milliseconds: milliseconds), (_) {
      final snapshot = state;
      if (snapshot is TimelapseLoaded && snapshot.isPlaying) {
        add(TickTimelapse(snapshot.visiblePoints + 1));
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  Future<void> close() {
    _stopTimer();
    return super.close();
  }
}

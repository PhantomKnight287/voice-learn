part of 'application_bloc.dart';

@immutable
abstract class ApplicationEvent {
  final bool hasVibrator;
  final bool hasAmplituteControl;

  const ApplicationEvent({
    required this.hasAmplituteControl,
    required this.hasVibrator,
  });
}

class SetApplicationVibrationOption extends ApplicationEvent {
  const SetApplicationVibrationOption({
    required super.hasAmplituteControl,
    required super.hasVibrator,
  });
}

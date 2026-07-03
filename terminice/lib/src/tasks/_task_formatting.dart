part of 'async_task.dart';

const _taskSuccessStatus = 'OK';
const _taskFailureStatus = 'ERROR';
const _taskCancelStatus = 'CANCELED';

int _validateTotal(int total) {
  if (total <= 0) {
    throw ArgumentError.value(total, 'total', 'must be greater than zero');
  }
  return total;
}

int _validateProgressWidth(int width) {
  if (width <= 0) {
    throw ArgumentError.value(
      width,
      'progressWidth',
      'must be greater than zero',
    );
  }
  return width;
}

int _validateMaxDots(int maxDots) {
  if (maxDots <= 0) {
    throw ArgumentError.value(maxDots, 'maxDots', 'must be greater than zero');
  }
  return maxDots;
}

int _clampCurrent(int current, int total) {
  if (current < 0) return 0;
  if (current > total) return total;
  return current;
}

String _statusLine(String status, String message, String suffix) {
  return '$status: $message$suffix';
}

String _runningText(String prompt, String? detail) {
  if (detail == null || detail.isEmpty) return prompt;
  return '$prompt - $detail';
}

String _dotsFrame(int frame, int maxDots) {
  return '.' * (frame % (maxDots + 1));
}

String _spinnerFrame(SpinnerStyle style, int frame) {
  final frames = InlineSpinner.framesForStyle(style);
  return frames[frame % frames.length];
}

String _progressSummary(TaskProgress progress) {
  final display = progressDisplay(
    current: progress.current,
    total: progress.total,
  );
  return '${display.current}/${display.total}, ${display.percent}%';
}

String _progressBar(TaskProgress progress, int width) {
  final filled = progressDisplay(
    current: progress.current,
    total: progress.total,
  ).filledUnits(width);
  final buffer = StringBuffer('[');
  for (var i = 0; i < width; i++) {
    buffer.write(i < filled ? '█' : '░');
  }
  buffer.write(']');
  return buffer.toString();
}

part of 'async_task.dart';

Future<T> _runTask<T>({
  required String prompt,
  required _TaskRenderer renderer,
  required FutureOr<T> Function() run,
  required String? success,
  required TaskErrorMessage? failure,
  required TaskErrorMessage? cancel,
  required TaskCancelPredicate? isCanceled,
}) async {
  try {
    renderer.start();

    late T result;
    try {
      result = await _awaitTaskOrRenderFailure(run, renderer);
    } on _TaskRenderFailure catch (failure) {
      Error.throwWithStackTrace(failure.error, failure.stackTrace);
    } catch (error, stackTrace) {
      if (isCanceled?.call(error) ?? false) {
        renderer.cancel(cancel?.call(error, stackTrace) ?? '$prompt canceled');
      } else {
        renderer.failure(
          failure?.call(error, stackTrace) ?? '$prompt failed: $error',
        );
      }
      Error.throwWithStackTrace(error, stackTrace);
    }

    renderer.success(success ?? prompt);
    return result;
  } finally {
    renderer.stop();
  }
}

Future<T> _awaitTaskOrRenderFailure<T>(
  FutureOr<T> Function() run,
  _TaskRenderer renderer,
) {
  final renderFailure = renderer.renderFailure;
  if (renderFailure == null) return Future<T>.sync(run);

  final completer = Completer<T>();
  var completed = false;

  void completeValue(T value) {
    if (completed) return;
    completed = true;
    completer.complete(value);
  }

  void completeError(Object error, StackTrace stackTrace) {
    if (completed) return;
    completed = true;
    completer.completeError(error, stackTrace);
  }

  renderFailure.then(
    (failure) => completeError(
      _TaskRenderFailure(failure),
      failure.stackTrace,
    ),
  );
  Future<T>.sync(run).then(completeValue, onError: completeError);

  return completer.future;
}

void _notifyProgressChanged(_TaskRenderer renderer, TaskProgress progress) {
  try {
    renderer.progress(progress);
  } catch (error, stackTrace) {
    renderer.recordRenderFailure(error, stackTrace);
    throw _TaskRenderFailure(_RenderFailure(error, stackTrace));
  }
}

class _RenderFailure {
  final Object error;
  final StackTrace stackTrace;

  _RenderFailure(this.error, this.stackTrace);
}

class _TaskRenderFailure implements Exception {
  final _RenderFailure failure;

  _TaskRenderFailure(this.failure);

  Object get error => failure.error;

  StackTrace get stackTrace => failure.stackTrace;
}

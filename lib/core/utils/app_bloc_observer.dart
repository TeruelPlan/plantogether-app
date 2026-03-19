import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

class AppBlocObserver extends BlocObserver {
  final _logger = Logger();

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    _logger.e('BlocError', error: error, stackTrace: stackTrace);
    super.onError(bloc, error, stackTrace);
  }
}

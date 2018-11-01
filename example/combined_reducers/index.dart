import 'dart:async';
import 'dart:html';

import 'package:redux/redux.dart';

void render(AppState state) {
  querySelector('#value').innerHtml = '${state.count}';
  querySelector('#clickValue').innerHtml = '${state.clickCount}';
}

class AppState {
  final int count;
  final int clickCount;

  AppState(this.count, this.clickCount);
}

enum AppAction { increment, decrement, throwInReducer, throwInMiddleware }

// Create a Reducer. A reducer is a pure function that takes the
// current State (int) and the Action that was dispatched. It should
// combine the two into a new state without mutating the state passed
// in! After the state is updated, the store will emit the update to
// the `onChange` stream.
//
// Because reducers are pure functions, they should not perform any
// side-effects, such as making an HTTP request or logging messages
// to a console. For that, use Middleware.
AppState counterReducer(AppState state, dynamic action) {
  if (action == AppAction.increment) {
    return new AppState(state.count + 1, state.clickCount);
  }
  if (action == AppAction.decrement) {
    return new AppState(state.count - 1, state.clickCount);
  }

  return state;
}

// Create a Reducer with a State (int) and an Action (String) Any dart object
// can be used for Action and State.
AppState clickCounterReducer(AppState state, dynamic action) {
  if (action == AppAction.increment) {
    return new AppState(state.count, state.clickCount + 1);
  }
  if (action == AppAction.decrement) {
    return new AppState(state.count, state.clickCount + 1);
  }

  return state;
}

AppState throwingReducer(AppState state, dynamic action) {
  if (action == AppAction.throwInReducer) {
    throw new Exception('throwing in reducer');
  }

  return state;
}

void throwingMiddleware(Store<AppState> store, dynamic action, NextDispatcher next) {
  if (action == AppAction.throwInMiddleware) {
    throw new Exception('throwing in middleware');
  }

  next(action);
}

/// Returns a Redux middleware that runs the rest of the middlewares and reducers
/// in the specified [zone] (defaulting to the current zone).
///
/// Useful as the first middleware when actions can be dispatched from an
/// unknown zone, and it's desired for Redux code to get run in a certain zone
/// (e.g., for error handling purposes).
///
/// __In most cases, this should be the first middleware in the list.__
Middleware<T> getZonedMiddleware<T>({Zone zone}) {
  zone ??= Zone.current;
  void zonedMiddleware(Store<T> store, dynamic action, NextDispatcher next) {
    // Use `runGuarded` instead of `run` so that uncaught synchronous errors
    // are passed along to this zone's error handler.
    zone.runGuarded(() => next(action));
  }
  return zonedMiddleware;
}

void main() {
  Store<AppState> store;
  runZoned(() {
    // Create a new reducer and store for the app.
    final combined = combineReducers<AppState>([
      counterReducer,
      clickCounterReducer,
      throwingReducer,
    ]);
    store = new Store<AppState>(
      combined,
      middleware: [
        // Try commenting this out to see how errors are normally handled
        // (and not caught by this zone's onError callback).
        getZonedMiddleware(),
        throwingMiddleware,
      ],
      initialState: new AppState(0, 0),
    );
  }, onError: (dynamic error, StackTrace stackTrace) {
    print('Error handled by zone that initialized the Store: $error\n$stackTrace');
  });

  render(store.state);
  store.onChange.listen(render);

  querySelector('#increment').onClick.listen((_) {
    store.dispatch(AppAction.increment);
  });

  querySelector('#decrement').onClick.listen((_) {
    store.dispatch(AppAction.decrement);
  });

  querySelector('#incrementIfOdd').onClick.listen((_) {
    if (store.state.count % 2 != 0) {
      store.dispatch(AppAction.increment);
    }
  });

  querySelector('#incrementAsync').onClick.listen((_) {
    new Future<Null>.delayed(new Duration(milliseconds: 1000)).then((_) {
      store.dispatch(AppAction.increment);
    });
  });

  querySelector('#throwInReducer').onClick.listen((_) {
    store.dispatch(AppAction.throwInReducer);
  });

  querySelector('#throwInMiddleware').onClick.listen((_) {
    store.dispatch(AppAction.throwInMiddleware);
  });
}

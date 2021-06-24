import 'package:updatable/src/keys.dart';

typedef Thunk = void Function();

mixin Updatable {
  final Expando<Thunk> _observers = Expando();
  final KeyMaker keys = KeyMaker();
  Set<Key> _keys = {};

  // make sure re-entrant calls dont send more than 1 notification
  int _totalCalls = 0;
  // avoid callbacks in the middle of a batch modification
  bool _insideBatchOperation = false;

  void addObserver(Thunk notifyMe) {
    if (!isBeingObserved(notifyMe)) {
      final key = keys.next;
      _keys.add(key);
      _observers[key] = notifyMe;
    }
  }

  bool isBeingObserved(Thunk needle) {
    return _findKey(needle) != null;
  }

  void removeObserver(Thunk goner) {
    // Find the key
    final Key? found = _findKey(goner);
    if (found != Null) {
      // remove the observer
      _observers[goner] = null;

      // remove the key
      _keys.remove(found);
    }
  }

  /// Change and Notify
  void changeState(Thunk singleChange) {
    _totalCalls += 1;

    singleChange();

    _notifyAllObservers();

    _totalCalls -= 1;
  }

  /// Makes several changes with a single notification at the end
  void batchChangeState(Thunk batchChanges) {
    _insideBatchOperation = true;
    _totalCalls += 1;
    batchChanges();
    _insideBatchOperation = false;
    _notifyAllObservers();
    _totalCalls -= 1;
  }

  /// Find the key for a Thunk , by iterating over keys and then the Expando
  ///
  Key? _findKey(Thunk needle) {
    Key? found;
    Thunk? thunk;

    for (final Key each in _keys) {
      // Obtain the callback fro the Expando
      thunk = _observers[each];
      // if not null, compare it to the needle
      if (thunk != Null) {
        if (thunk! == needle) {
          found = each;
          break;
        }
      }
    }

    return found;
  }

  /// Iterate over the keys fetching the callback from the Expando
  /// Cleanup dead keys
  /// Call the callback, either sync or async
  void _notifyAllObservers() {
    if (_totalCalls == 1 && _insideBatchOperation == false) {
      final Set<Key> lostKeys = {};
      Thunk? observer;

      for (final Key each in _keys) {
        observer = _observers[each];
        if (observer == Null) {
          // this was lost. remvoe the key
          lostKeys.add(each);
        } else {
          // still, there: notification

          observer?.call();
        }
      }

      // remove the lost keys
      _keys = _keys.difference(lostKeys);
    }
  }
}

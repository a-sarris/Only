[![Run unit tests](https://github.com/a-sarris/Only/actions/workflows/main.yml/badge.svg)](https://github.com/a-sarris/Only/actions/workflows/main.yml)
# Only

Throttler implementation as an SPM Package that runs a closure only if specific conditions are met.

## Sample Usage

### Create a key that serves as an identifier for the closure:

```
enum Key: String, CaseIterable {
    case showTutorial
}
```
### At the appropriate place in your application's lifecycle, add the throttler:

```
Only(.once(Key.showTutorial)) { [weak self] in
    self?.showTutorial()
}
```

`self?.showTutorial()` will only run once and never again until the application is uninstalled or the backing storage is cleared. For each key a record is created prefixed by `com.execute.only.` (configurable)

The default backing storage is `UserDefaults.standard`.

### Available options are described by `OnlyFrequency`:
```
enum OnlyFrequency<T: OnlyKey> where T.RawValue == String {
    case once(T)
    case oncePerSession(T)
    case ifTimePassed(T, DispatchTimeInterval)
    case `if`(() -> Bool)
    case every(T, times: Int)
}
```

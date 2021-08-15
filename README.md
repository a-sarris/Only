[![Run unit tests](https://github.com/a-sarris/Only/actions/workflows/main.yml/badge.svg)](https://github.com/a-sarris/Only/actions/workflows/main.yml)
# Only

Throttler implementation that runs a closure only if specific conditions are met.

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

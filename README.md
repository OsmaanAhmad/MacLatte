# MacLatte

A tiny menu bar app that keeps your Mac awake, like `caffeinate` with a UI.

## Features

- Menu bar icon (coffee cup) — filled when active, outline when idle
- Toggle "Keep Awake Indefinitely" on/off
- Preset timers: 15 min, 30 min, 1 hour, 2 hours, 4 hours
- Custom timer (enter any number of minutes)
- Live countdown shown next to the menu bar icon when a timer is running
- Optional "Launch at Login"
- No Dock icon — lives only in the menu bar

Under the hood it uses `IOPMAssertionCreateWithName` with
`kIOPMAssertionTypeNoDisplaySleep`, the same mechanism `caffeinate -d` uses,
so it prevents both display sleep and idle system sleep.

## Build

Requires Xcode command line tools (Swift 5.9+) and macOS 13+.

```bash
./build.sh
```

This compiles a release binary via Swift Package Manager and packages it into
`MacLatte.app`, ad-hoc code-signed so `Launch at Login` works.

## Install / Run

```bash
# Try it in place:
open MacLatte.app

# Or install it properly:
cp -R MacLatte.app /Applications/
open /Applications/MacLatte.app
```

Click the coffee cup icon in the menu bar to toggle keep-awake or start a timer.

## Uninstall

Quit the app from its menu, then delete `MacLatte.app` from wherever you
installed it. If you enabled "Launch at Login", toggle it off first.

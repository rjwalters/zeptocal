# zeptocal

The tiniest possible macOS menu-bar calendar. No events, no accounts, no
permissions — just a month grid for answering *"what day of the week was that?"*

- Menu bar shows today (e.g. `Wed 22`); click for a month grid.
- ISO-style week numbers down the left edge.
- Jump by month (`‹ ›`) or year (`« »`), or hit **Today** to snap back.
- Click any day to read its full weekday in the header.

Pure `Calendar` date math via SwiftUI `MenuBarExtra`. One binary, no dependencies.

## Build & run

```sh
./build.sh
open Zeptocal.app
```

Requires macOS 14+ and a Swift 6 toolchain (Xcode Command Line Tools is enough).

To launch at login: System Settings → General → Login Items → add `Zeptocal.app`.

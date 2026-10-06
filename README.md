# zeptocal

The tiniest possible macOS menu-bar calendar. No events, no accounts, no
permissions — just a month grid for answering *"what day of the week was that?"*

- Calendar icon in the menu bar; click for a month grid.
- Week numbers down the left edge (from your system calendar settings).
- Jump by month (`‹ ›`) or year (`« »`), click the year to type one, or hit
  **Today** to snap back.
- Click any day to mark it — label, repeat (once/weekly/monthly/yearly), shape,
  fill, and color. Marks are saved locally, and a countdown to the next one
  shows under the grid.

Pure `Calendar` date math via SwiftUI `MenuBarExtra`. One binary, no dependencies.

## Build & run

```sh
./build.sh
open Zeptocal.app
```

To install into `/Applications` (quitting and relaunching any running copy):

```sh
./build.sh --install
```

Requires macOS 14+ and a Swift 6 toolchain (Xcode Command Line Tools is enough).

To launch at login: System Settings → General → Login Items → add `/Applications/Zeptocal.app`.

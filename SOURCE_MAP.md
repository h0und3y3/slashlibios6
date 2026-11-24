# Original Swift source → Objective-C port map

| Original file | Current Objective-C location | Port status |
|---|---|---|
| `API.swift` | `SLAPI.h/.m` | Core requests ported; response edge cases still need fixtures |
| `App.swift` | `main.m`, `SLAppDelegate.h/.m` | Application lifecycle and tab navigation ported |
| `AuthStore.swift` | `SLAuthStore.h/.m` | Token/keychain layer ported; refresh/session parity needs testing |
| `CatalogViewController.swift` | `SLAppDelegate.h/.m` | Search/catalog UI combined in app delegate; not a one-to-one view port |
| `Config.swift` | API constants and app configuration | No dedicated Objective-C config module yet |
| `Diagnostics.swift` | `SLDiagnostics.h/.m` | Memory/event/crash diagnostics implemented; not all original report details |
| `Downloads.swift` | `SLDownloadManager.h/.m` | Basic offline download support; queue/retry parity remains |
| `FavoritesViewController.swift` | `SLLibraryViewController.h/.m`, `SLStore.m` | Combined library screen |
| `Helpers.swift` | Helpers distributed among `SLTheme`, `SLImageLoader`, reader and store | Partial; not all helpers mapped individually |
| `HistoryViewController.swift` | `SLLibraryViewController.h/.m`, `SLStore.m` | Combined library screen |
| `Home.swift` | `SLHomeViewController.h/.m` | Base home screen ported; filters/recommendations remain partial |
| `PageStore.swift` | `SLPageStore.h/.m` | Disk streaming cache, LRU trim and ImageIO downsampling; strip renderer not complete |
| `ReaderSettings.swift` | `SLReaderSettingsViewController.h/.m` | Core settings ported; quick theme selector is still in global settings |
| `ReaderViewController.swift` | `SLReaderViewController.h/.m` | Reader basics and lazy neighbor loading; advanced rendering parity remains |
| `SettingsViewController.swift` | `SLSettingsViewController.h/.m` | Main settings ported; some advanced preferences remain |
| `Storage.swift` | `SLStore.h/.m` | Favorites/history/bookmark persistence ported; migration tests needed |
| `Sync.swift` | `SLSyncService.h/.m` | Gist synchronization implementation exists; schema/conflict tests needed |
| `Theme.swift` | `SLTheme.h/.m` | Basic light/dark theme ported; animation/palette parity partial |
| `TitleViewController.swift` | `SLTitleViewController.h/.m` | Title/chapter screen ported; API edge cases need verification |

This map records the current implementation layout; it does not imply complete feature parity.

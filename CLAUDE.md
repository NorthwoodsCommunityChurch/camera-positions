# Camera Positions

## Purpose
Displays camera operator assignments (name, camera number, lenses) on a monitor near the camera prep area. Admin configures via SwiftUI app; camera ops view via web browser.

## Architecture
- **SwiftUI admin app** — ProPresenter-inspired 3-pane layout (sidebar, camera grid, lens tray)
- **NWListener HTTP server** — serves web display on port 8080
- **JSON file persistence** — `~/Library/Application Support/CameraPositions/`
- **Planning Center OAuth** — pulls team members and weekends from PCO Services API

## Key Files

### App
- `CameraPositions/App/CameraPositionsApp.swift` — entry point, Sparkle integration
- `CameraPositions/ViewModels/AppViewModel.swift` — all app state and business logic
- `CameraPositions/Models/` — CameraPosition, Lens, CameraAssignment, WeekendConfig, PublishedDisplay

### Views
- `CameraPositions/Views/ContentView.swift` — main 3-pane layout
- `CameraPositions/Views/Sidebar/SidebarView.swift` — weekends list, PCO login, team members
- `CameraPositions/Views/CameraGrid/CameraColumnView.swift` — individual camera column with drop zones
- `CameraPositions/Views/LensTray/` — lens inventory with CRUD editor

### Services
- `CameraPositions/Services/PersistenceService.swift` — JSON file read/write
- `CameraPositions/Services/ImageStorage.swift` — angle photos and lens photos
- `CameraPositions/Services/Web/DisplayServer.swift` — NWListener HTTP server
- `CameraPositions/Services/Web/HTTPTypes.swift` — HTTP request/response types
- `CameraPositions/Services/PlanningCenter/` — OAuth, API client, token storage, config
- `CameraPositions/Services/ESP32DisplayService.swift` — pushes assignments to ESP32 OLED boards

### ESP32 OLED Integration
- `ESP32Connection` struct: maps a camera number → ESP32 IP address; stored in UserDefaults
- `ESP32DisplayService.push(display:)` is called in `autoPublish()` — fires-and-forgets HTTP POSTs
- Each ESP32 receives `POST /api/display` with `{"operator": "...", "lens": "..."}` JSON
- Settings UI: sidebar → "ESP32 Displays" button → `ESP32SettingsSheet` (add/remove IP+camera pairs)
- ESP32 firmware: `CAMERA_NUMBER` define (0 = unset); OLED rows: cam#/tally, operator, lens, status

### Web Display
- `CameraPositions/Resources/Web/index.html` — display page structure
- `CameraPositions/Resources/Web/styles.css` — dark theme, large fonts
- `CameraPositions/Resources/Web/display.js` — polls /api/config every 5 seconds

## Build
```bash
./build.sh   # xcodegen → xcodebuild → sign → launch
```

## Data Flow
1. Admin adds team members (manually or from PCO) and lenses
2. Admin drags names and lenses into camera columns
3. Admin clicks Save → writes `published-display.json`
4. Web display polls `/api/config` → renders camera cards
5. Images served from `/api/images/{filename}`

## Planning Center Setup
1. Register app at https://developer.planning.center
2. Add Client ID and Secret to `PCOConfig.swift`
3. Click "Connect Planning Center" in sidebar
4. Select camera team from picker

## Known Patterns
- `Color.accentColor` must be explicit in `.foregroundStyle()` (SwiftUI type inference issue)
- `lazy` doesn't work in `@Observable` classes — use init pattern instead
- OneDrive xattrs break code signing — `xattr -cr` in build.sh before signing
- Web resources embedded in app bundle via `path: Resources/Web, type: folder` in project.yml

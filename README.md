# Camera Positions

Camera operator assignment display for live production teams. Configure camera assignments in the admin app, and operators view their positions on a shared monitor via web browser.

<!-- TODO: Add screenshot -->
<!-- ![Camera Positions](docs/images/screenshot.png) -->

## Features

- **Drag-and-drop assignments** — drag team members and lenses onto camera positions
- **Web display** — full-screen browser view shows camera numbers, operator names, lenses, and angle photos
- **Planning Center integration** — pull team members and service schedules from PCO Services
- **Person photos** — assign photos to operators that display on the web view
- **Camera angle photos** — attach reference photos showing each camera's shot
- **Lens management** — create a lens inventory with names and photos
- **Multiple weekends** — manage assignments for upcoming services
- **Auto-publish** — changes publish instantly to the web display
- **Clock display** — web view shows the current time with seconds
- **Auto-updates** — built-in update checking via Sparkle

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon Mac (aarch64)

## Installation

1. Download the latest `.zip` from [Releases](https://github.com/NorthwoodsCommunityChurch/camera-positions/releases)
2. Extract the zip file
3. Move **Camera Positions.app** to your Applications folder
4. Open the app — macOS will block it the first time
5. Go to **System Settings > Privacy & Security** and click **Open Anyway**
6. The app will open normally from now on

## Usage

### Admin App (3-pane layout)

- **Left sidebar** — select weekends, manage team members, connect Planning Center
- **Center grid** — camera positions with drop zones for operators and lenses
- **Right tray** — lens inventory with add/edit/delete

### Web Display

Once the app is running, open a browser on any device on the same network to:

```
http://<your-mac-ip>:8080
```

The web display auto-refreshes every 5 seconds.

### Quick Start

1. Launch the app
2. Add camera positions (default: 5 cameras)
3. Add team members manually or connect Planning Center
4. Add lenses to your inventory
5. Drag operators onto camera positions
6. Drag lenses onto camera positions
7. Open `http://localhost:8080` in a browser to see the display

## Configuration

### Planning Center Integration

1. Go to [Planning Center Developer](https://api.planningcenteronline.com/oauth/applications) and create a Personal Access Token
2. In the app sidebar, click **Connect Planning Center**
3. Enter your Application ID and Secret
4. Select your service type and camera team from the dropdowns
5. Upcoming services and team members will sync automatically

### Camera Angle Photos

Right-click a camera column in the admin app to set an angle reference photo. This photo displays as the background in the web view.

### Person Photos

Right-click a team member in the sidebar to assign a photo. When that person is assigned to a camera, their photo overrides the angle photo in the web display.

## Building from Source

### Prerequisites

- Xcode 16.0+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

### Build

```bash
git clone https://github.com/NorthwoodsCommunityChurch/camera-positions.git
cd camera-positions
./build.sh
```

The build script generates the Xcode project, builds a Release binary, bundles and signs the Sparkle framework, ad-hoc signs the app, and launches it.

## Project Structure

```
Camera Positions/
├── build.sh                          # Build, sign, and launch script
├── project.yml                       # XcodeGen project definition
├── CameraPositions/
│   ├── App/
│   │   └── CameraPositionsApp.swift  # Entry point, Sparkle integration
│   ├── Models/
│   │   ├── CameraAssignment.swift    # Operator + lens assignments
│   │   ├── CameraPosition.swift      # Camera number, label, photo
│   │   ├── Lens.swift                # Lens name and photo
│   │   ├── PublishedDisplay.swift     # Data model for web display
│   │   ├── Version.swift             # App version string
│   │   └── WeekendConfig.swift       # Service date and assignments
│   ├── ViewModels/
│   │   └── AppViewModel.swift        # All app state and business logic
│   ├── Views/
│   │   ├── ContentView.swift         # Main 3-pane layout
│   │   ├── CameraGrid/              # Camera position columns
│   │   ├── LensTray/                # Lens inventory CRUD
│   │   ├── PlanningCenter/          # PCO login sheet
│   │   ├── Sidebar/                 # Weekend list, team members
│   │   └── TeamMembers/             # Team member tiles with photos
│   ├── Services/
│   │   ├── ImageStorage.swift        # Photo file management
│   │   ├── PersistenceService.swift  # JSON file read/write
│   │   ├── PlanningCenter/          # PCO OAuth, API client, token storage
│   │   └── Web/                     # NWListener HTTP server
│   └── Resources/
│       ├── Assets.xcassets/          # App icon, accent color
│       └── Web/                     # HTML, CSS, JS for web display
├── LICENSE
├── CREDITS.md
└── SECURITY.md
```

## License

MIT License — see [LICENSE](LICENSE) for details.

## Credits

See [CREDITS.md](CREDITS.md) for third-party libraries, tools, and assets.

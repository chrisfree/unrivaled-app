# Unrivaled Basketball App

iOS app for the Unrivaled Basketball League - a women's professional 3v3 basketball league.

## Features

- 📅 **Schedule** - View upcoming games
- 🏀 **Results** - See completed game scores
- ⭐ **Favorites** - Track your favorite team
- 📱 **Widgets** - Home screen widgets for quick score updates
- 🔴 **Live Scores** - Real-time updates when games are in progress

## Setup

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- macOS with Homebrew (for xcodegen)

### Generate Xcode Project

1. Install xcodegen if you don't have it:
   ```bash
   brew install xcodegen
   ```

2. Generate the project:
   ```bash
   cd unrivaled-app
   xcodegen generate
   ```

3. Open in Xcode:
   ```bash
   open Unrivaled.xcodeproj
   ```

### Dependencies

Add SwiftSoup for HTML parsing (used by live score scraper fallback):

In Xcode: File → Add Package Dependencies → Enter:
```
https://github.com/scinfu/SwiftSoup.git
```

### Manual Setup (Alternative)

If you prefer not to use xcodegen:

1. Create a new iOS App project in Xcode named "Unrivaled"
2. Add a Widget Extension target named "UnrivaledWidget"
3. Copy the source files into the appropriate groups
4. Add App Group capability (`group.com.unrivaled.app`) to both targets
5. Set deployment target to iOS 17.0
6. Add SwiftSoup package dependency

### App Group Setup

Both the main app and widget need the App Group capability:
- Go to Signing & Capabilities
- Add "App Groups"
- Create group: `group.com.unrivaled.app`

### API Key Setup

1. Get a free or premium API key from [TheSportsDB](https://www.thesportsdb.com)
2. Open the app → Settings → Enter your API key
3. Premium ($9/mo) unlocks full schedule (56 games vs 15)

## API

Uses [TheSportsDB](https://www.thesportsdb.com) API.
- Free tier: Key `123`, limited to 15 games per endpoint
- Premium ($9/mo): Full data access, livescores
- League ID: 5622

### Live Score Fallback

TheSportsDB may not have live score coverage for Unrivaled. The app includes a scraper fallback that fetches live data directly from unrivaled.basketball when the API has no live games.

## Project Structure

```
unrivaled-app/
├── UnrivaledApp/
│   ├── Sources/
│   │   ├── Models/
│   │   │   └── Models.swift          # Data models
│   │   ├── Services/
│   │   │   ├── APIService.swift      # API client
│   │   │   └── LiveScoreScraper.swift # Fallback scraper
│   │   ├── ViewModels/
│   │   │   └── GamesViewModel.swift  # Main view model
│   │   ├── Views/
│   │   │   ├── ContentView.swift     # Main app views
│   │   │   └── GameComponents.swift  # Reusable components
│   │   └── UnrivaledApp.swift        # App entry point
│   └── Resources/
│       ├── Info.plist
│       └── Unrivaled.entitlements
├── UnrivaledWidget/
│   ├── UnrivaledWidget.swift         # Widget implementation
│   ├── Info.plist
│   └── UnrivaledWidget.entitlements
├── project.yml                        # XcodeGen spec
├── Claude.md                          # AI guidelines
└── tasks/
    ├── todo.md                        # Project tasks
    └── lessons.md                     # Lessons learned
```

## Teams

| Team | ID |
|------|-----|
| Breeze BC | 154048 |
| Hive BC | 154049 |
| Laces BC | 151477 |
| Lunar Owls BC | 150651 |
| Mist BC | 151962 |
| Phantom BC | 151478 |
| Rose BC | 151481 |
| Vinyl BC | 150736 |

## License

This is a personal project. Unrivaled Basketball is a trademark of Unrivaled LLC.

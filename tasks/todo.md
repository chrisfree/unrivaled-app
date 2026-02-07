# Unrivaled Basketball iOS App - TODO

## Project Overview
iOS app showing schedule and scores for the Unrivaled Basketball League (women's 3v3 league).
- **API**: TheSportsDB (Free tier - key: 123)
- **League ID**: 5622
- **Features**: Schedule, Scores/Results, Widgets (favorite team / most recent)

## API Details
- Base URL: `https://www.thesportsdb.com/api/v1/json/123/`
- Rate limit: 30 req/min (free tier)
- Key endpoints:
  - `eventsseason.php?id=5622&s=2026` - Season schedule (15 results free)
  - `eventspastleague.php?id=5622` - Recent results  
  - `eventsnextleague.php?id=5622` - Upcoming games
  - `lookuptable.php?l=5622` - Standings
  - `search_all_teams.php?l=Unrivaled_Basketball` - All teams

## Teams (8 total)
- Breeze BC (154048)
- Hive BC (154049)
- Laces BC (151477)
- Lunar Owls BC (150651)
- Mist BC (151962)
- Phantom BC (151478)
- Rose BC (151481)
- Vinyl BC (150736)

---

## Phase 1: Project Setup
- [ ] Create Xcode project (SwiftUI, iOS 17+)
- [ ] Set up project structure (MVVM)
- [ ] Add App Group for widget data sharing
- [ ] Configure Info.plist for network access

## Phase 2: Core Data Layer
- [ ] Create API service for TheSportsDB
- [ ] Define data models (Team, Game, Event)
- [ ] Implement caching layer (UserDefaults/file-based)
- [ ] Add error handling

## Phase 3: Main App Views
- [ ] Schedule view (upcoming games list)
- [ ] Results view (completed games with scores)
- [ ] Game detail view
- [ ] Team selection/favorites (stored in UserDefaults)
- [ ] Settings view (favorite team picker)

## Phase 4: Widgets
- [ ] Create Widget Extension
- [ ] Small widget (next game for favorite team)
- [ ] Medium widget (recent scores or upcoming schedule)
- [ ] Widget configuration (team selection)
- [ ] Background refresh via Timeline

## Phase 5: Polish
- [ ] App icon
- [ ] Launch screen
- [ ] Pull-to-refresh
- [ ] Loading states
- [ ] Error states
- [ ] Test on device

---

## Review Section
*(To be filled after implementation)*

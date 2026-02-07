# Turbulence Forecast

A free iOS app that provides turbulence forecasts for any flight route worldwide. Built for both anxious passengers who want peace of mind and aviation professionals who need detailed wind shear data.

**Bundle ID:** `com.turbulenceforecastapp`
**Platform:** iOS 17+ (iPhone & iPad)
**Language:** Swift / SwiftUI

---

## Features

### Route Forecast
Enter departure and arrival airports to get a detailed 3-day turbulence forecast. The app computes Clear Air Turbulence (CAT) predictions using upper-atmosphere pressure level wind data from 200 hPa to 700 hPa (FL100–FL390).

### Severity Levels
Forecasts are classified into FAA-aligned severity levels:
- **Smooth** — No significant turbulence
- **Light** — Minor bumps, very common
- **Moderate** — Noticeable bumps, walking may be difficult
- **Severe** — Strong turbulence, keep seatbelt fastened at all times

### Flight Level Breakdown
Detailed altitude analysis showing turbulence severity, wind shear (kt/1000ft), and jet stream speed at each flight level — useful for pilots and aviation professionals.

### Live Pilot Reports (PIREPs)
Real-time turbulence reports from pilots worldwide via the FAA Aviation Weather Center, updated every 5 minutes. Reports are filtered to show only those along your route corridor.

### Turbulence Map
Interactive map showing PIREP locations, SIGMET/AIRMET polygons, and forecast turbulence annotations with color-coded severity markers.

### Flight Reminders
Schedule a notification before your flight to get an updated turbulence forecast. Configurable timing: 12, 24, or 48 hours before departure.

### Full iPad Support
Adaptive layouts for all screens — optimized for both iPhone and iPad with proper Split View support.

---

## Data Sources

| Source | Data |
|--------|------|
| **Open-Meteo API** | Upper-atmosphere wind data at pressure levels (200–700 hPa) for turbulence computation |
| **FAA Aviation Weather Center** | PIREPs (Pilot Reports), SIGMETs, G-AIRMETs |
| **NOAA** | Atmospheric models powering Open-Meteo forecasts |

---

## Turbulence Computation

The app computes turbulence from vertical wind shear between adjacent pressure levels:

1. Fetches wind speed and direction at 6 pressure levels (200, 250, 300, 400, 500, 700 hPa)
2. Decomposes wind into u/v vector components
3. Calculates shear magnitude between adjacent levels in kt/1000ft
4. Applies jet stream amplification factor (1.3x for >80kt, 1.15x for >60kt)
5. Classifies severity: ≥8 severe, 6–8 moderate, 4–6 light, <4 smooth

---

## Architecture

```
TurboTrack/
├── Models/
│   ├── Airport.swift              # 44+ airports worldwide with search
│   ├── PIREPReport.swift          # PIREP data model
│   ├── SIGMET.swift               # SIGMET/AIRMET data model
│   └── TurbulenceForecast.swift   # Forecast model with layers, points, daily summary
├── Services/
│   ├── AviationWeatherService.swift    # FAA AWC API (PIREPs, SIGMETs)
│   ├── TurbulenceForecastService.swift # Open-Meteo API + wind shear computation
│   ├── LocationService.swift           # CLLocationManager wrapper
│   └── NotificationService.swift       # Local notification scheduling
├── ViewModels/
│   ├── RouteViewModel.swift       # Route search, forecast, notifications
│   ├── MapViewModel.swift         # Map data, filtering, auto-refresh
│   └── ReportsViewModel.swift     # PIREP list, filtering, search
├── Views/
│   ├── ContentView.swift          # Tab bar + onboarding gate
│   ├── Onboarding/
│   │   └── OnboardingView.swift   # 13-step onboarding flow
│   ├── Route/
│   │   ├── RouteInputView.swift   # Airport input with autocomplete
│   │   ├── ForecastResultView.swift # Forecast results display
│   │   └── RouteMapView.swift     # Route map with annotations
│   ├── Map/
│   │   ├── TurbulenceMapView.swift     # Interactive turbulence map
│   │   ├── TurbulenceAnnotation.swift  # Severity marker view
│   │   └── ReportDetailSheet.swift     # PIREP detail sheet
│   ├── Reports/
│   │   ├── ReportsListView.swift  # PIREP list with filters
│   │   └── ReportRow.swift        # Individual report row
│   └── Settings/
│       └── SettingsView.swift     # App settings
└── Utils/
    ├── TurbulenceSeverity.swift   # Severity enum with colors
    └── Extensions.swift           # Utility extensions
```

---

## Onboarding Flow

The app includes a 13-step onboarding flow (shown on first launch only):

### Feature Screens (Steps 0–5)

| Step | Screen | Visual | Title | Subtitle |
|------|--------|--------|-------|----------|
| 0 | **Welcome** | App icon with pulsing glow | **Turbulence Forecast** | "Know what to expect before you fly" |
| 1 | **Check Any Route** | Mock route input card (KJFK → EGLL) | **Check Any Route** | "Enter departure and arrival to get a detailed turbulence forecast" |
| 2 | **3-Day Forecast** | Fan of 5 animated severity cards (Mon–Fri) + App Store rating request | **3-Day Turbulence Forecast** | "Plan ahead with predictions based on upper-atmosphere wind data" |
| 3 | **Every Altitude** | Dual scrolling carousels — flight levels (FL100–FL390) + turbulence types (Wind Shear, Jet Stream, CAT, Mountain Wave, Convective, SIGMET) | **Every Altitude Covered** | "Turbulence data at every flight level from FL100 to FL390" |
| 4 | **Pilot Reports** | 3 animated PIREP cards (B738 Moderate, A320 Light, B777 Severe) | **Live Pilot Reports** | "Real-time turbulence reports from pilots around the world, updated every 5 minutes" |
| 5 | **Data Sources** | 2×2 grid (NOAA, FAA AWC, Open-Meteo, PIREPs) | **Trusted Aviation Data** | "Powered by official weather services and real pilot reports worldwide" |

### Quiz Screens (Steps 6–10)

| Step | Question | Options |
|------|----------|---------|
| 6 | **How do you feel about flying?** | I love flying · A bit nervous · Quite anxious · Fear of flying |
| 7 | **How often do you fly?** | Frequent flyer · Regular traveler · Occasional · Rare / First time |
| 8 | **How familiar are you with turbulence?** | Pilot / Aviation pro · I know the basics · Heard of it · Complete beginner |
| 9 | **What would help you most?** (multi-select) | Route turbulence forecast · Detailed flight level data · Tips for handling turbulence · Pre-flight notifications · Real-time turbulence map · Multi-day forecast · Pilot-grade weather data · Anxiety management advice |
| 10 | **When do you usually check your flight?** | Day of the flight · 1–2 days before · 3–5 days before · A week or more |

### Setup & Completion (Steps 11–12)

| Step | Screen | Description |
|------|--------|-------------|
| 11 | **Dark Setup Screen** | Dark background with animated progress bar. Four setup steps animate sequentially: "Loading atmospheric models…", "Calibrating turbulence algorithms…", "Connecting to weather stations…", "Personalizing your experience…". After completion, shows "Trusted by Travelers & Pilots" with a horizontal carousel of 4 testimonial cards (5-star reviews). Auto-advances to step 12. |
| 12 | **Completion** | ✈️ emoji, "You're Ready to Fly", "Your personalized turbulence forecast is set up and ready to go." Black "Get Started" button → main app. |

### Onboarding Animations
- Spring animations for icon/card entrances
- Floating gradient orbs in background (3 circles with different periods)
- Fan card spread animation (step 2)
- Dual-direction scrolling carousels (step 3)
- Staggered card scale-in animations (steps 4, 5)
- Sequential progress bar with step indicators (step 11)
- All transitions use `.opacity` with `.easeInOut`

---

## Main App Screens

### Tab 1: Map
Interactive MapKit map showing PIREPs as color-coded severity dots, SIGMET polygons, and map controls (compass, scale, user location). Altitude filter sheet available.

### Tab 2: Reports
Searchable list of PIREP reports with severity filter chips (All, Light, Moderate, Severe, Extreme), stats bar showing counts, and pull-to-refresh.

### Tab 3: Forecast
The main feature — airport input with autocomplete suggestions, "Check Turbulence" button. Results screen shows:
- **Status banner** — color-coded severity with icon
- **Passenger advisory** — plain-language advice
- **Route map** — with turbulence forecast annotations
- **Daily forecast** — day-by-day severity breakdown
- **Flight level breakdown** — altitude analysis with wind shear and jet stream data
- **PIREP summary** — real-time pilot reports along the route
- **Notification prompt** — offer to set a reminder before the flight
- **Disclaimer** — informational purposes only

### Tab 4: Settings
- **Notifications** — Flight reminders toggle, timing selector (12/24/48h), pending count
- **Units** — Altitude units (feet/meters)
- **Data Refresh** — Auto-refresh toggle and interval
- **Data Sources** — Links to Aviation Weather Center
- **Support** — Contact Developers (hello@britetodo.com)
- **About** — Version, disclaimer

---

## Build & Run

Requires [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```bash
brew install xcodegen
cd "turbulence forecast"
xcodegen generate
open TurboTrack.xcodeproj
```

Select your Development Team in Signing & Capabilities, then build and run.

---

## Version History

### 1.0.0
- Initial release
- Route turbulence forecast using Open-Meteo pressure level wind data
- Live PIREP reports and SIGMET/AIRMET map
- 13-step onboarding with feature screens and quizzes
- Flight reminder notifications
- Full iPhone and iPad support
- Contact developers via email

---

## Contact

**Email:** hello@britetodo.com

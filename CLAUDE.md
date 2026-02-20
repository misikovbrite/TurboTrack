# TurboTrack (Turbulence Forecast)

## Project Info

- **App Name**: Turbulence Forecast
- **Bundle ID**: `com.turbulenceforecastapp`
- **App Store ID**: `6758868326`
- **App Store URL**: https://apps.apple.com/us/app/turbulence-forecast-flight/id6758868326
- **GitHub**: `misikovbrite/TurboTrack` (public)
- **Platform**: iOS 17+ (iPhone & iPad)
- **Stack**: SwiftUI + StoreKit 2 + Firebase Analytics + Firebase Remote Config

## Build

- **Xcode project**: Generated from `project.yml` via XcodeGen
- **Dev Team (project.yml)**: `HQ59Y7A4T2` (Brite Technologies LLC)
- **Dev Team (pbxproj target)**: `5487HDH2B9` — this is what actually signs the build
- **Firebase**: `GoogleService-Info.plist` (not in git, copy from iCloud if missing)
- **Build command**: `xcodebuild archive` + `xcodebuild -exportArchive` with `-allowProvisioningUpdates` and `CODE_SIGN_STYLE=Automatic`
- **Swift version**: 5.9, Firebase iOS SDK 11.6.0

## ASC API

- **Issuer ID**: `f7dc851a-bdcb-47d6-b5c7-857f48cadb17`
- **Key ID**: `C37442BRFH`
- **Key path**: `~/Downloads/AuthKey_C37442BRFH.p8`

## Subscription

- **Product IDs**: `turbulence_forecast_weekly`, `turbulence_forecast_yearly`
- **Current paywall**: Weekly only ($2.99/week), yearly removed from UI in v1.3.0
- **Paywall file**: `TurboTrack/Views/Onboarding/PaywallView.swift`
- **Subscription service**: `TurboTrack/Services/SubscriptionService.swift`
- **Feature gate**: `TurboTrack/Services/FeatureGate.swift`

## Locales

- **App locales (9)**: en (base), da, de, es, fr, nb, pt-BR, ru, sv
- **ASC locales (22)**: ar-SA, da, de-DE, el, en-US, es-ES, es-MX, fi, fr-FR, he, hi, hu, id, it, ja, ko, ms, nl-NL, no, pt-BR, ru, sv, th, tr, uk, vi, zh-Hans, zh-Hant
- **String catalog**: `TurboTrack/Localizable.xcstrings`

## Key Architecture

```
TurboTrack/
├── Models/          # Airport, PIREPReport, SIGMET, TurbulenceForecast
├── Services/        # SubscriptionService, FeatureGate, AviationWeather, Location, Notification
├── ViewModels/      # RouteViewModel, MapViewModel, ReportsViewModel
├── Views/
│   ├── Onboarding/  # OnboardingView, PaywallView
│   ├── Route/       # RouteInputView, ForecastResultView, RouteMapView
│   ├── Map/         # TurbulenceMapView, annotations, detail sheets
│   ├── Reports/     # ReportsListView, ReportRow
│   └── Settings/    # SettingsView
└── Utils/           # TurbulenceSeverity, Extensions
```

## Version Release Workflow

1. Bump version in `project.pbxproj` (MARKETING_VERSION + CURRENT_PROJECT_VERSION)
2. Archive: `xcodebuild archive -project TurboTrack.xcodeproj -scheme TurboTrack -archivePath /tmp/TurboTrack.xcarchive -allowProvisioningUpdates CODE_SIGN_STYLE=Automatic DEVELOPMENT_TEAM=5487HDH2B9`
3. Export: `xcodebuild -exportArchive -archivePath /tmp/TurboTrack.xcarchive -exportPath /tmp/TurboTrackExport -exportOptionsPlist /tmp/exportOptions.plist -allowProvisioningUpdates`
4. Upload: `xcrun altool --upload-app -f /tmp/TurboTrackExport/TurboTrack.ipa -t ios -u britetodo@gmail.com -p <app-specific-password>`
5. ASC API: set encryption → create/update version → add release notes → link build → submit

## Changelog

### 2026-02-20 — v1.3.0 (build 5)

**Paywall redesign: weekly-only + money-back guarantee**

Changes made:
- `PaywallView.swift`: Removed yearly plan, removed `selectedPlanId` state, made weekly plan single centered card
- `PaywallView.swift`: Changed "How Your Free Trial Works" → "How Your Trial Works" (removed all "free" mentions)
- `PaywallView.swift`: Added `weeklyPlanCard` view (shows price/week + "Cancel anytime")
- `PaywallView.swift`: Added `moneyBackBadge` view (shield icon + "14-Day Money-Back Guarantee")
- `PaywallView.swift`: Updated timeline steps: Today/Full Access/14-Day Guarantee/After 7 Days
- `PaywallView.swift`: Subscribe button always uses weekly product
- `SettingsView.swift`: Removed "Learn" section with FAQ (TurbulenceFAQView was deleted from project)
- `Localizable.xcstrings`: Added 9 new strings translated to 8 locales
- `project.pbxproj`: Removed stale references to ForecastHistory.swift, PremiumBannerView.swift, TurbulenceFAQView.swift
- `project.pbxproj`: Version bumped to 1.3.0 build 5

ASC actions:
- Release notes added to all 22 locales: "Improved turbulence forecasting system"
- In-App Event "14-Day Turbulence Forecast" created with card+detail images, 175 territories
- Version + event submitted together for accelerated review (WAITING_FOR_REVIEW)

Reason: Yearly subscription with free trial had poor conversion — users trialed but didn't convert. Weekly at $2.99 performs better. Money-back guarantee adds trust signal.

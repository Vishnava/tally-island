# Repository survey and product decisions

Reviewed 2026-11-01. Scope: **all 52 public repositories returned by GitHub for Ebullioscopic**, plus the projects named in Atoll's acknowledgments. This is a product/README/metadata survey, not a source-code security audit or a benchmark of every project. Private repositories are not included. Where READMEs are absent or minimal, recommendations are explicitly limited to metadata.

## Decision

Build **Tally Island**, an original native macOS app centered on readable dot-matrix numbers and a small set of everyday actions. Preserve the numeric presentation the user liked in Gentra Island. Ship real local features before adding account systems, private macOS APIs, model runtimes, or network services.

The most useful cluster is Atoll + its extension ecosystem + Teleprompter. The rest spans health, ML, environmental research, virtual try-on, assistants, and learning projects. Those can inspire separate products but are not a coherent dependency stack for a notch app.

## Every public repository

The license column reflects GitHub metadata at review time; “not detected” is not a grant of reuse rights. README license badges are not treated as a substitute for verified license files. No code/assets from these projects are redistributed by Tally v0.1.

| Repository | License metadata | Assessment | Decision / opportunity |
|---|---|---|---|
| [Atoll](https://github.com/Ebullioscopic/Atoll) | GPL-3.0 | Core reference | Expandable native island; rich media/system tools. Original implementation in Tally; no Atoll code copied. |
| [AtollExtensionKit](https://github.com/Ebullioscopic/AtollExtensionKit) | LGPL-3.0 | Integration reference | Typed activities, priorities and permission controls; consider an optional adapter later. |
| [SilentFit](https://github.com/Ebullioscopic/SilentFit) | Not detected | Future idea | Health tracking suggests optional break/hydration nudges, not a full health database in the island. |
| [atoll-js](https://github.com/Ebullioscopic/atoll-js) | MIT | Integration reference | JavaScript activity client; useful future interoperability candidate. Tally currently uses its own local protocol. |
| [hold-for-2x](https://github.com/Ebullioscopic/hold-for-2x) (fork) | MIT | Separate product | Fork of a video-speed extension; belongs in the browser, not the native island. |
| [AtollRPC](https://github.com/Ebullioscopic/AtollRPC) | MIT | Integration reference | WebSocket SDK. Revisit once Tally has a versioned, authenticated extension architecture. |
| [awesome-macos](https://github.com/Ebullioscopic/awesome-macos) (fork) | MIT | Discovery only | Forked software catalog; useful ecosystem research, not an implementation dependency. |
| [Dino](https://github.com/Ebullioscopic/Dino) | AGPL-3.0 | Later / optional | Notch game is feasible but would distract from the first productivity release. |
| [Ebullioscopic](https://github.com/Ebullioscopic/Ebullioscopic) | Not detected | Excluded | Profile repository; not an app building block. |
| [Teleprompter](https://github.com/Ebullioscopic/Teleprompter) | MIT | Shipped concept | Inspired the paced, near-camera reader. Tally has an original timer-based implementation, not voice recognition. |
| [SketchStory](https://github.com/Ebullioscopic/SketchStory) | NOASSERTION | Separate product | Sketch/story workflow; would require a separate canvas and model pipeline. |
| [Invasive-Species-Detection](https://github.com/Ebullioscopic/Invasive-Species-Detection) | MIT | Separate product | Remote-sensing classification; suitable for a research dashboard, unrelated to the island. |
| [Cheatly-macOS](https://github.com/Ebullioscopic/Cheatly-macOS) | Not detected | Excluded from v0.1 | Auto-typing utility; system-wide typing adds Accessibility requirements and is outside this release. |
| [homebrew-atoll](https://github.com/Ebullioscopic/homebrew-atoll) | Not detected | Distribution reference | Tap scaffolding; consider our own formula/cask after stable signed releases. |
| [BluePrint](https://github.com/Ebullioscopic/BluePrint) | Not detected | Separate product | Marine eDNA analysis; requires domain datasets and independent validation. |
| [Adobe-GFG-Gensolve-Curvetopia](https://github.com/Ebullioscopic/Adobe-GFG-Gensolve-Curvetopia) | MIT | Separate product | Shape regularization/symmetry; potential drawing utility, not an island module. |
| [boring.notch](https://github.com/Ebullioscopic/boring.notch) (fork) | GPL-3.0 | Upstream reference | Fork; study TheBoredTeam upstream for media/shelf concepts and attribution history. |
| [Radio](https://github.com/Ebullioscopic/Radio) | Not detected | Future idea | Radio playback could become an optional media module; metadata only, README unavailable. |
| [FarmHand](https://github.com/Ebullioscopic/FarmHand) | Not detected | Separate product | Consumer/farmer app; no substantive README. Not a reusable island foundation. |
| [TailorFit](https://github.com/Ebullioscopic/TailorFit) | Not detected | Separate product | Body measurement/virtual try-on; metadata only. Different privacy and model requirements. |
| [SkinsIntel](https://github.com/Ebullioscopic/SkinsIntel) | Not detected | Not enough evidence | Empty README and zero-size metadata; no implementation to assess. |
| [DSA-Practice](https://github.com/Ebullioscopic/DSA-Practice) | Not detected | Excluded | Practice repository; no README retrieved. |
| [HospitalManagementSystem](https://github.com/Ebullioscopic/HospitalManagementSystem) | Not detected | Separate product | Hospital app; placeholder README and unrelated workflow. |
| [WaterDrop](https://github.com/Ebullioscopic/WaterDrop) | Not detected | Future idea | Cross-device transfer is useful alongside a shelf; networking and peer identity need a dedicated implementation. |
| [DARG](https://github.com/Ebullioscopic/DARG) | Not detected | Separate product | Vector search/graph exploration; performance claims were not benchmarked in this review. |
| [Resume](https://github.com/Ebullioscopic/Resume) | Not detected | Excluded | Personal resume sources; not product code. |
| [dgx-server-url](https://github.com/Ebullioscopic/dgx-server-url) | Not detected | Excluded | Infrastructure pointer; not an app component. |
| [ImageGroup](https://github.com/Ebullioscopic/ImageGroup) | Not detected | Future idea | Image grouping could inform shelf organization; README unavailable, metadata only. |
| [Forms](https://github.com/Ebullioscopic/Forms) | Not detected | Separate product | Forms web project; no clear island integration. |
| [TryIt-FastAPI](https://github.com/Ebullioscopic/TryIt-FastAPI) | NOASSERTION | Separate product | Virtual try-on endpoint; minimal README. |
| [Phi-3-Math-FineTuned](https://github.com/Ebullioscopic/Phi-3-Math-FineTuned) | Not detected | Separate product | Math model fine-tuning project; not needed for local numeric displays. |
| [Lab-Report-Extractor](https://github.com/Ebullioscopic/Lab-Report-Extractor) | Not detected | Separate product | Medical document OCR pipeline; do not import its endpoint or medical workflow into this utility. |
| [RA2211026010183](https://github.com/Ebullioscopic/RA2211026010183) | Not detected | Not enough evidence | Repository identifier and placeholder README provide no clear product direction. |
| [FinSense](https://github.com/Ebullioscopic/FinSense) | Not detected | Separate product | Financial/document extraction pipeline; separate product and data-handling requirements. |
| [BirdWatch](https://github.com/Ebullioscopic/BirdWatch) | Not detected | Not enough evidence | Swift repository without retrieved README; no validated feature assumptions. |
| [BirdSpotter](https://github.com/Ebullioscopic/BirdSpotter) | Not detected | Not enough evidence | No retrieved README; no validated feature assumptions. |
| [StockViewer](https://github.com/Ebullioscopic/StockViewer) | Apache-2.0 | Future idea | An opt-in market tile is possible, but needs API keys and stale-data handling; outside v0.1. |
| [TryIt](https://github.com/Ebullioscopic/TryIt) | Not detected | Not enough evidence | Small Swift repo without retrieved README; no implementation reused. |
| [TailorFit-Backend](https://github.com/Ebullioscopic/TailorFit-Backend) | Not detected | Separate product | Try-on backend family; README unavailable. |
| [Student-Performance-Predictor](https://github.com/Ebullioscopic/Student-Performance-Predictor) | MIT | Separate product | CoreML learning example; prediction workflow does not belong in this island. |
| [HLS-Burn-Scars-Transformer](https://github.com/Ebullioscopic/HLS-Burn-Scars-Transformer) (fork) | Not detected | Separate product | Forked remote-sensing research; unrelated to everyday Mac utilities. |
| [PET-Bottle-Classifier](https://github.com/Ebullioscopic/PET-Bottle-Classifier) | Not detected | Separate product | Bottle-classification project with placeholder README. |
| [Gordon](https://github.com/Ebullioscopic/Gordon) | Not detected | Separate product | Food/assistant project from metadata; README unavailable. |
| [TravelSafe](https://github.com/Ebullioscopic/TravelSafe) | Not detected | Separate product | Route-safety concept; insufficient evidence for a dependable consumer feature. |
| [git-demo](https://github.com/Ebullioscopic/git-demo) (fork) | Not detected | Excluded | Forked collaboration tutorial. |
| [WatchOS-HealthKit-and-WorkoutKit-API-Caller](https://github.com/Ebullioscopic/WatchOS-HealthKit-and-WorkoutKit-API-Caller) | Not detected | Future idea | Wearable companion might support optional wellness features; README unavailable. |
| [Prediction-Vending-Machines](https://github.com/Ebullioscopic/Prediction-Vending-Machines) | Not detected | Separate product | Time-series forecasting scripts; unrelated to island utilities. |
| [Rollie](https://github.com/Ebullioscopic/Rollie) | Not detected | Separate product | Smart-home assistant with minimal README; could eventually report status via tally. |
| [Socks](https://github.com/Ebullioscopic/Socks) | Not detected | Separate product | Fine-tuned assistant with minimal README; no integration used. |
| [CareerShield](https://github.com/Ebullioscopic/CareerShield) | Not detected | Not enough evidence | Placeholder README; no grounded reuse recommendation. |
| [Machine-Learning](https://github.com/Ebullioscopic/Machine-Learning) | Not detected | Excluded | Learning exercises, not a focused product component. |
| [TechTrack](https://github.com/Ebullioscopic/TechTrack) | Not detected | Not enough evidence | Empty repository. |

## Atoll acknowledgments: what they mean for Tally

| Project | Useful idea | v0.1 decision |
|---|---|---|
| [Boring.Notch](https://github.com/TheBoredTeam/boring.notch) | Native expansion, media and file shelf | Original AppKit panel and file-reference shelf. No upstream source copied. |
| [Alcove](https://tryalcove.com/) | Compact interaction and restrained presentation | Visual/product reference only. No proprietary assets or code used. |
| [Stats](https://github.com/exelban/stats) | System metrics and feature-level resource costs | Read CPU ticks, VM counters, battery and disk through system APIs. No SMC, fan control, GPU or temperature support in v0.1. |
| [Open-Meteo](https://open-meteo.com/) | Optional weather without a user API key | Future opt-in feature. Requires location choice, attribution, caching and compliance with commercial-use terms. No weather requests in v0.1. |
| [SkyLightWindow](https://github.com/Lakr233/SkyLightWindow) | Rendering over the lock screen using private APIs | Not included. Tally uses ordinary AppKit panels and makes no lock-screen claim. |
| [rtaudio](https://github.com/ZephyrCodesStuff/rtaudio) | CoreAudio/Metal visualization, stop rendering on silence | Not included. Its README calls it a proof of concept; an audio feature needs permission and energy testing. |
| [SwiftTerm](https://github.com/migueldeicaza/SwiftTerm) | Native terminal emulation | Defer; a full terminal in a small island would expand scope. The tally bridge is a display-only tool. |
| [DynamicNotch](https://github.com/jackson-storm/DynamicNotch) | Battery HUDs and fallback for screens without notches | Original compact battery display and floating fallback. Multi-display behavior still needs more hardware testing. |
| Wick | Timer styling acknowledged by Atoll | No source link supplied or implementation verified. No code/design assets reused. |
| [OpenUsage](https://github.com/robinebers/openusage) | Provider-reported usage and account ownership | Future explicit account adapter. Tally only displays caller-supplied counts, with no claimed plan limits or costs. |
| [OpenRouter](https://openrouter.ai/docs/api/api-reference/models/list-all-models-and-their-properties) | Model pricing metadata | Future optional estimator with model/cache/date labels. No pricing or billing estimates in v0.1. |
| [Gentra Island](https://github.com/Adamfatur/gentra-island) | Dot-number presentation, focus, clipboard, agent status | Main numeric-style inspiration. Original circle-based glyph renderer and local implementations; no source/assets copied. |

## Prioritized next steps

1. **Daily-use hardening:** test non-notched/secondary displays, macOS 14–26, VoiceOver, reduced motion, long-running CPU/energy use; sign and notarize a stable release.
2. **Media:** implement permission-aware Music/Spotify controls and truthful unavailable states. Artwork and audio visualization are separate capabilities.
3. **Agent adapters:** explicit lifecycle integrations, then optional account-owned provider usage. Keep status, token counts, plan limits and billing separate.
4. **Wellness + weather:** configurable gentle reminders, with opt-in weather and explicit city selection.
5. **Interoperability:** evaluate an Atoll bridge or versioned local SDK. Preserve attribution and review actual dependency licenses before incorporating code.
6. **Optional modules:** voice-following teleprompter, cross-device transfer, calendar and terminal. Each needs its own design, privacy and reliability review.

## Provenance

The implementation was written for this project using Apple platform frameworks and Swift/Foundation. The repository survey informed feature choices; it did not involve copying source files from the reviewed projects. Tally's MIT license covers its own code only. It does not change any upstream project's license or imply endorsement.

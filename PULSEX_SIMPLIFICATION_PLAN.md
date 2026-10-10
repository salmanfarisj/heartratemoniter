# PulseX Simplification Plan

## Context

PulseX is a Flutter heart-rate monitor + activity tracker (50 Dart files, ~8.0K LOC). The codebase works but is over-engineered for a beginner reader: fake data hardcoded in widgets, two parallel repositories, a "legacy" alias method kept for safety, dead UI pages (Display Mode segmented selector, Sensors grid), and a daily-aggregate table that the UI never reads. Goal: keep the app's visible behavior identical while making every file self-explanatory in 2–3 minutes. After this plan lands, a beginner can open any file and know (a) what feature it belongs to, (b) what the data flow is, and (c) where to look next.

Target end state: same four tabs (Workout/History/Record/Settings), same live HR chart, same BLE scanning, same activity logging, same SQLite storage — but with dead code, fake data, dual API surfaces, and unused export plumbing removed.

## Approach

Apply changes as a sequence of vertical cuts. Each cut is independently verifiable; passing existing tests + a manual smoke run after each step. Steps 1–4 are the high-value cuts (data + state). Steps 5–8 are UI simplification. Step 9 is documentation.

### Step 1 — Remove unused `DeviceRepository` and `DeviceRepositoryImpl`

Grep returns zero callsites for `DeviceRepository`/`DeviceRepositoryImpl` outside the file itself; the `devices` SQLite table is written to but never read (the BLE service uses in-memory `HeartRateDevice` objects).

- `rm lib/features/home/data/repositories/device_repository_impl.dart`
- `rm lib/features/home/domain/repositories/device_repository.dart`
- Keep the `devices` SQLite table — its `_onCreate` is harmless; removing it would require a schema migration. Document the table as "reserved for future paired-devices UI" in a single line of comment in `database_helper.dart`.
- Update `lib/main.dart`: delete the `DeviceRepositoryImpl` import path reference if present (none found, confirm by re-grep after delete).

No behavioral change.

### Step 2 — Remove `live_hr_readings` table and all "live buffer" plumbing

The live buffer is written to by `appendLiveReading` but never read by the app. `HistoryPage` reads `live_hr_readings` via `HistoryRepositoryImpl.getTodayHrTrend` — that chart becomes a 30-sample in-memory ring buffer (see Step 6). `pruneLiveBuffer`, `saveReading`, `getReadingsForDate`, `getReadingsInRange` are dead.

- Edit `lib/core/database/database_helper.dart`: remove `live_hr_readings` table from `_onCreate` and from `_onUpgrade` v2→v3. Bump `version` to 4. In `_onUpgrade`, add a `if (oldVersion < 4)` branch that drops `live_hr_readings`.
- Edit `lib/features/home/domain/repositories/heart_rate_repository.dart`: remove `appendLiveReading`, `pruneLiveBuffer`, `saveReading`, `getReadingsForDate`, `getReadingsInRange` declarations.
- Edit `lib/features/home/data/repositories/heart_rate_repository_impl.dart`: delete the matching `// Single-buffer writes` and `// Legacy API` sections (lines 19–189). Keep only `recordAggregated`, `getStatsForDate`, `getDailySummaries`, `clearAll`. Remove the now-unused `import '../../domain/models/heart_rate_reading.dart'`. Keep the file's `DailyHrSummary` class.
- `HeartRateReading` model (`lib/features/home/domain/models/heart_rate_reading.dart`) is now unreferenced; delete it.
- Remove `DatabaseHelper.liveBufferSeconds` constant.

After this step the only writes to the database from the heart-rate feature are daily aggregates.

### Step 3 — Wire home's zone legend to real daily aggregates

`_ZoneLegend` in `home_page.dart` (lines 437–495) renders 4 hardcoded rows with fake percentages. The DB already stores per-zone seconds in `daily_hr_aggregates`.

- Edit `lib/features/home/data/repositories/heart_rate_repository_impl.dart`: in `getStatsForDate`, also return zone seconds. Add a new query selecting the four `zone_*_seconds` columns and return them.
- Edit `lib/features/home/domain/models/heart_rate_stats.dart`: add `final Map<HeartRateZone, int> zoneSeconds;` (default empty map). Update `HeartRateStats.empty()`, `fromAggregate`, `copyWith`, `props`.
- Edit `lib/features/home/presentation/bloc/heart_rate_bloc.dart` (line ~233, `_onAggregateTick`): no change needed — `todayStats` is already emitted with the new shape.
- Edit `lib/features/home/presentation/pages/home_page.dart`:
  - Delete `_ZoneLegend`, `_ZoneRow`, `_ZoneDivider`, `_ZoneBar` classes (lines 437–620).
  - Add a new `_ZoneLegend` that reads `state.todayStats.zoneSeconds`, computes `(seconds / total) * 100` for each zone, and renders one `_ZoneRow` per zone. Use the same `AppColors.zone*` colors and the same row layout (zone label, range, percent bar, time label formatted as `m:ss`).
  - Add a top-level `List<HeartRateZone> _kZonesOrdered = [HeartRateZone.rest, HeartRateZone.fatBurn, HeartRateZone.cardio, HeartRateZone.peak];` constant for the iteration order.

After this step the home page zone legend is real.

### Step 4 — Replace the fake home chart with a 30-sample rolling buffer

`_HrAreaChart` in `home_page.dart` (lines 290–345) uses 13 hardcoded `FlSpot` values. User confirmed: real 30-sample in-memory ring buffer.

- Edit `lib/features/home/presentation/bloc/heart_rate_state.dart`: add `final List<int> recentBpm;` defaulting to `const []`. Update `copyWith` (use `List<int>? recentBpm` — assign `recentBpm ?? this.recentBpm`), `props`.
- Edit `lib/features/home/presentation/bloc/heart_rate_bloc.dart`, in `_onHeartRateUpdated` (around line 196):
  - After emitting, mutate an in-memory `_recentBpm` list (instance field) and emit a follow-up state with the new list. Keep the list capped at 30: `if (_recentBpm.length >= 30) _recentBpm.removeAt(0);` before `add`.
  - Simplest implementation: emit a new `state.copyWith(recentBpm: List<int>.from(_recentBpm))` from the same handler. The list is then visible to the UI.
  - Reset `_recentBpm = []` in `_onConnectionStateChanged` when disconnecting and in `_onDisconnectDevice` (alongside the existing `clearCurrentBpm: true`).
- Edit `lib/features/home/presentation/pages/home_page.dart`:
  - In `_LiveHrChartCard` (line 199), pass `recentBpm: state.recentBpm` to `_HrAreaChart`.
  - In `_HrAreaChart`, replace the hardcoded `spots` with `final spots = [for (var i = 0; i < recentBpm.length; i++) FlSpot(i.toDouble(), recentBpm[i].toDouble())];`.
  - Handle the empty case: when `recentBpm.isEmpty`, show the existing `_EmptyChart` widget (already present at line 348).

After this step the home chart reflects the actual last 30 BLE samples.

### Step 5 — Remove the `Devices` table from the SQL writes (already covered in Step 1, just confirm)

Already removed as part of Step 1. No further action.

### Step 6 — Simplify `HistoryRepositoryImpl` + remove the `live_hr_readings` read in `getTodayHrTrend`

After Step 2, `HistoryRepositoryImpl.getTodayHrTrend` reads from a table that no longer exists. Replace it.

- Edit `lib/features/history/data/repositories/history_repository_impl.dart`:
  - Delete `getHrReadingsInRange` method (it queried `live_hr_readings`).
  - Delete the import of `HeartRateReading` and `HeartRateZone` from that file.
  - Change `getTodayHrTrend` to accept the in-memory list from the bloc instead. New signature: `Future<HrTrend> getTodayHrTrend({required List<int> recentBpm, double distanceKm = 0})`. The bloc passes `recentBpm` (already a state field per Step 4) and the function computes `distanceKm` from today's activities (kept logic).
  - Keep `getWeeklyHrData` and `getActivitiesInRange` as-is.
- Edit `lib/features/history/presentation/bloc/history_bloc.dart`: add a `LoadHrTrend` event field carrying the bpm list, OR simpler: change the event to `LoadHrTrend` (no args) and have the bloc read `HeartRateBloc`'s state via a callback. **Chosen approach**: have `HistoryBloc` keep a reference to the `HeartRateRepository` aggregate endpoint instead — read the same row that the home page reads (sum of `zone_*_seconds` for today via `getStatsForDate`) and return a synthesized `HrTrend` with `samples: []` (the chart now shows the home tab's chart, not a duplicate). Concretely:
  - `getTodayHrTrend` returns `HrTrend(samples: const [], distanceKm: ...)` (no samples) — the `_HrTrendChart` already handles the empty case via `_emptyState()`. The History page then drops the chart entirely (Step 7) so this method becomes unused; delete it from the repo too.
- Edit `lib/features/history/presentation/bloc/history_event.dart`: delete the now-unused `LoadHrTrend` event.
- Edit `lib/features/history/presentation/bloc/history_state.dart`: remove the `hrTrend` field (no consumers after Step 7).
- Edit `lib/features/history/presentation/bloc/history_bloc.dart`: remove the `_onLoadHrTrend` handler, remove the `import` of `hr_trend.dart` if no longer needed.

### Step 7 — Simplify `HistoryPage`

`HistoryPage` (952 LOC) has: device header card (static), sensors grid (static, "Connected" hardcoded, "Searching…" sub-text), route picker pill (no onTap), and a "Recent Heart Rate" empty card. All of these are static decorations with no data binding.

- Edit `lib/features/history/presentation/pages/history_page.dart`:
  - Delete `_DeviceHeaderCard`, `_SensorsGrid`, `_SensorCard`, `_RoutePicker`, `_HrTrendChart`, `_TrendHeader`, `_WeeklyHeader`, `_WeeklyLegend`, `_LegendDot` classes.
  - Delete the `BlocListener<HeartRateBloc>` wrapper (no longer needed — the trend chart that triggered it is gone).
  - Keep `_WeeklyHrChart` and rename to `_HrChart`. Bind it directly to `state.weeklyHrData`.
  - Keep `_ActivitySummary`, `_StatColumn` (still renders `ActivityBloc` totals — these are real).
  - Delete `_RecentHrCard` (the "Recent HR" list was never populated anyway).
  - Result: a page that shows the 7-day weekly chart + activity summary, both real. Top section becomes a simple header card that reads `HeartRateBloc` for the connected-device name + battery (move that into the existing `_SectionLabel` block, or delete the header card entirely).

  Trade-off decision: delete the header card entirely. The Settings tab is where the user manages their device, and the home tab shows the live reading. The History tab's job is "what has your training looked like" — pure data.

  File shrinks from 952 to ~250 LOC.

### Step 8 — Remove dead UI in `SettingsPage`

`SettingsPage` has a `_DisplayMode` segmented selector (Heartrate/Speed/Control) where `onChanged: (_) {}` does nothing, and `ExportData` shows a "coming soon" snackbar while the bloc/CsvExportService are fully wired.

- Edit `lib/features/settings/presentation/pages/settings_page.dart`:
  - Delete the `_DisplayMode` enum (lines 319–323) and the `SegmentedSelector<_DisplayMode>` block in the `Display Mode` section (lines 58–69). Delete the `_SectionLabel('Display Mode')` line above it. Replace the section with nothing (just collapse the spacing).
  - Replace `_showExportDialog` (lines 256–294): call `settingsBloc.add(const ExportData('hr'))` directly on the first button, `settingsBloc.add(const ExportData('activities'))` on the second, drop the snackbar. Use the real exported path from `settingsState.exportedFilePath` to show a `SnackBar` with "Saved to: <path>" only after `SettingsStatus.exported`. Wire the listener at the page level with `BlocListener<SettingsBloc, SettingsState>` listening on `status == exported` or `errorMessage != null`.
- The `CsvExportService` already writes the file to `getApplicationDocumentsDirectory()` and triggers the share sheet via `Share.shareXFiles`. The path is already stored in `state.exportedFilePath`. Just surface it.

  Result: Settings tab shrinks by ~40 LOC and the segmented selector placeholder is gone.

### Step 9 — Trim miscellaneous cruft

- Delete `lib/core/widgets/pulsex_logo.dart` `PulseXLogo` (the full-screen splash variant — never used) and `PulseXHomeLogo` (never used). Keep `PulseXHeart` (used in shell nav) and `PulseXAboutTile` (used in Settings). File shrinks from 300 to ~120 LOC.
- Delete `lib/features/settings/data/repositories/settings_repository_impl.dart` `resetMaxHeartRateUserSet` method (only mentioned as "Exposed for tests" but no tests use it).
- In `lib/features/home/presentation/bloc/heart_rate_bloc.dart` and `lib/features/settings/presentation/bloc/settings_bloc.dart` and the activity/history blocs: remove the `// ignore_for_file: prefer_initializing_formals` lines and rename `_repository` → `repository`, `_heartRateRepository` → `heartRateRepository`, etc. to use initializing formals. This satisfies the linter and is the idiomatic Flutter form.
- In `lib/features/activities/presentation/pages/activities_page.dart`: the `_getIconForType` method on the state (line 22 + line 24) is a duplicate of the file-level `iconForActivity` function. Delete both `_getIconForType` declarations. Already a one-line cleanup.
- In `lib/main.dart`: the 8 `final ...Repository ...` lines plus the eager `SettingsBloc` construction can stay (they're all real) — but the comment "Prefer initializing formals (kept as-is to silence `prefer_initializing_formals`)" history comments in many files (e.g. heart_rate_bloc, settings_bloc) can be deleted once the rename lands.

### Step 10 — Replace the boilerplate placeholder test

`test/widget_test.dart` is `expect(true, isTrue)` — useless.

- Replace with a real test of the simplest pure function in the codebase: `HeartRateZone.fromBpm`. Add `import 'package:flutter_test/flutter_test.dart';` and `import 'package:pulsex/features/home/domain/models/heart_rate_zone.dart';`. Add four assertions covering the four zone boundaries at maxHr=180:
  - `fromBpm(70, maxHr: 180)` → `HeartRateZone.rest` (39%)
  - `fromBpm(110, maxHr: 180)` → `HeartRateZone.fatBurn` (61%)
  - `fromBpm(140, maxHr: 180)` → `HeartRateZone.cardio` (78%)
  - `fromBpm(160, maxHr: 180)` → `HeartRateZone.peak` (89%)

  This is the smallest possible "this code is real" signal for a beginner reading the repo.

## Critical files & anchors

- `lib/features/home/data/repositories/heart_rate_repository_impl.dart` — after Step 2 holds the only heart-rate DB code; after Step 3 also returns zone seconds. Anchors: lines 19–189 (delete), lines 80–95 (extend).
- `lib/core/database/database_helper.dart` — schema definition. Anchors: lines 47–52 (drop live_hr_readings), line 18 (bump version), lines 134–158 (v3→v4 migration).
- `lib/features/home/presentation/bloc/heart_rate_bloc.dart` — `_onHeartRateUpdated` around line 196 (Step 4), `_onConnectionStateChanged` around line 268 (Step 4 reset), `on<LoadTodayStats>` around line 280.
- `lib/features/home/presentation/pages/home_page.dart` — `_ZoneLegend` line 437, `_HrAreaChart` line 290, `_LiveHrChartCard` line 199, the 13 hardcoded `FlSpot`s inside `_HrAreaChart` (the fake data).
- `lib/features/history/presentation/pages/history_page.dart` — full file rewrite target; the `_SensorsGrid` static widget at line 186 is the clearest "this is decoration" signal.
- `lib/features/settings/presentation/pages/settings_page.dart` — `_DisplayMode` enum line 319, segmented selector block lines 58–69.

## Verification

After each step run the existing app and confirm the four tabs still render. The end-to-end proof:

1. `flutter pub get` (working dir: project root, no env vars needed).
2. `flutter analyze` — must return 0 errors. (Re-passes the linter after the `_repository` → `repository` rename in Step 9.)
3. `flutter test` — placeholder test in Step 10 must pass (4 assertions, ~50ms).
4. `flutter run -d <device>` and exercise:
   - **Workout tab**: open app → "Not Connected" pill. Tap pill → "Connect Device" sheet opens with empty state. Tap "Scan for Devices" → permission prompt → scanner turns on. Stop scan → button toggles. (Confirm no crashes, no missing imports.)
   - **History tab**: shows the 7-day weekly chart (empty state if no data). Activity Summary shows "0 activities, 0 min, 0 kcal". (Confirms `_SensorsGrid` removal didn't break the layout — it shouldn't, it's a child of the page.)
   - **Record tab**: scroll the form, pick a type chip, toggle "Manual — No GPS", fill name + duration, tap Save → snackbar "Activity saved!", form clears.
   - **Settings tab**: tap Age → enter 40 → Save → "Max HR" row updates to 180 (= 220 - 40). Tap Export Data → Heart Rate → native share sheet opens with a CSV file. Tap Clear History → confirm → snackbar "Data cleared".
5. For Step 4 specifically: connect a real BLE HR strap (Polar H10 is the cheapest reliable choice; the codebase already lists 'polar' in its name-pattern match list), confirm the home chart animates as new samples land — the rolling buffer should make the line visibly shift each second.

## Assumptions & contingencies

- **Schema version bump (Step 2)**: bumping to v4 drops `live_hr_readings` on first launch of an upgraded app. The table is write-only and ephemeral (auto-pruned every hour) so dropping it is safe. If the user objects to losing any unread live samples, fall back to keeping the table but never reading it — but that leaves the dead-write problem the plan is trying to fix. Going with the drop.
- **`HeartRateReading` model removal (Step 2)**: the model is now unreferenced. If a future feature legitimately needs raw samples, it can be reintroduced; the SQLite schema can be re-added in a v5 migration. Don't preemptively keep the model "just in case".
- **History chart sample source (Step 6)**: the simplest correct path is "delete the trend chart entirely and let the home tab be the live chart." A beginner reading the History page now sees: "this page shows the 7-day weekly trend (real SQL aggregate) and the activity totals (real SQL aggregate)." Two widgets, two queries, no fakes.
- **Display Mode segmented selector (Step 8)**: dropped entirely. The four tabs already separate concerns (Workout = live, History = trends, Record = log, Settings = config). Adding a "Display Mode" inside Settings was a placeholder; if the user later wants to switch between metric views, it can be reintroduced as a real feature with actual side-effects.
- **Removed tests (Step 10)**: the placeholder `expect(true, isTrue)` test is replaced. No existing tests are deleted because there are no real ones.
- **Window of `_recentBpm` (Step 4)**: 30 samples ≈ 30 seconds of BLE stream at 1 Hz. Sufficient for a live waveform look. If user wants a longer window, the constant is one line; not pre-deciding.
- **Settings file name (Step 8 export snackbar)**: uses `getApplicationDocumentsDirectory()` on iOS, which is the iCloud-Documents folder — fine for a dev build. Surfacing the path in a snackbar (not a dialog) keeps the UX simple.

# Telugu Riddles iOS

A standalone SwiftUI iOS app for playing Telugu riddles during a family gathering.

## What Is Included

- 1,120 bundled Telugu riddles in `TeluguRiddles/Resources/riddles.json`
- Telugu, Hybrid, and English modes
  - Telugu: Telugu riddles and Telugu app chrome
  - Hybrid: Telugu riddles with English controls and common app text
  - English: English riddles with English controls and common app text
- Solo play by default, with optional team mode
- Category filter for choosing the style of riddles
- Team names and score tracking
- 10, 20, 30, or endless rounds
- Hint and answer reveal controls
- Favorites and seen-riddle tracking
- A polished app icon and launch screen
- Unit and UI test targets
- Local-only gameplay with no network requirement

## Open In Xcode

Open:

```sh
open TeluguRiddles.xcworkspace
```

Then choose the `TeluguRiddles` scheme and run on an iPhone simulator or device.

## Regenerate Riddles

The riddle deck is generated from original Telugu clue patterns, then augmented with English riddle fields:

```sh
node tools/generate-riddles.js
```

The generated JSON is checked in so the app works immediately in Xcode.

If you edit only the English metadata script, run:

```sh
node tools/add-english-riddles.js
```

## Audit Riddle Quality

```sh
node tools/audit-riddles.js
```

See `docs/RIDDLE_CURATION.md` for the current manual review notes and the release curation checklist.

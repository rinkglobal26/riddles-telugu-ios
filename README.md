# Telugu Riddles iOS

A standalone SwiftUI iOS app for playing Telugu riddles during a family gathering.

## What Is Included

- 1,120 bundled Telugu riddles in `TeluguRiddles/Resources/riddles.json`
- Category filter for choosing the style of riddles
- Team names and score tracking
- 10, 20, 30, or endless rounds
- Hint and answer reveal controls
- Local-only gameplay with no network requirement

## Open In Xcode

Open:

```sh
open TeluguRiddles.xcworkspace
```

Then choose the `TeluguRiddles` scheme and run on an iPhone simulator or device.

This machine currently has Command Line Tools selected instead of full Xcode, so command-line iOS builds with `xcodebuild` cannot run until Xcode is installed/selected:

```sh
sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
```

## Regenerate Riddles

The riddle deck is generated from original Telugu clue patterns:

```sh
node tools/generate-riddles.js
```

The generated JSON is checked in so the app works immediately in Xcode.

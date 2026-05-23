# Telugu Riddle Curation Notes

This deck is generated from original Telugu clue patterns and is useful for app testing, but it should be curated before App Store release.

## First Manual Review Pass

- The JSON has more than 1,000 entries, unique IDs, and no missing Telugu or English question, answer, category, or hint fields.
- Telugu rendering is valid in the bundled JSON.
- English mode currently uses direct answer/hint metadata with reusable English question templates. It is serviceable for testing and early demos, but should be rewritten by a fluent editor before App Store release.
- The current deck is intentionally family-safe and avoids external copied sources.
- The largest quality issue is repetition: each answer has multiple template variations, so the app has volume but not yet the feel of 1,000 distinct traditional riddles.
- Several clues are straightforward descriptions rather than classic poetic riddles. This is fine for young-family play, but the store listing should not promise a fully traditional folklore collection until the deck is expanded by hand.

## Release Curation Checklist

- Replace repetitive generated variants with distinct human-reviewed riddles.
- Ask at least two fluent Telugu speakers to review spelling, naturalness, and answer clarity.
- Tag each riddle with audience suitability: kids, all ages, harder, wordplay.
- Remove duplicate concepts that feel too similar in one sitting.
- Keep a source note for every externally contributed riddle. Do not copy riddles from websites or books without permission.
- Run `node tools/audit-riddles.js` after each deck update.

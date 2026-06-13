# Signal Deck for iPhone

Coming soon to the app store possibly - but until then:

Signal Deck is a SwiftUI probability, statistics, and quantitative-finance quiz app. It includes configurable quizzes, generated question variants, a learning center, custom cards, personal decks, quiz history, recovery codes, and trophies.

## Requirements

- macOS with Xcode
- iOS 17 or later
- An Apple ID for installing a development build on a physical iPhone

## Run the app

1. Clone or download this repository.
2. Open `SignalDeck.xcodeproj` in Xcode.
3. Select the `SignalDeck` target.
4. Open **Signing & Capabilities**.
5. Choose your own development team.
6. Replace `com.example.signaldeck` with a bundle identifier unique to you.
7. Select an iPhone simulator or connected iPhone.
8. Press **Run**.

## Project structure

- `SignalDeck/ContentView.swift`: SwiftUI interface
- `SignalDeck/WebView.swift`: app state, quiz logic, data models, recovery, and learning-center rendering
- `SignalDeck/AppData.json`: bundled topics and question bank
- `SignalDeck/LearningGuideContent.html`: bundled learning-center reference content
- `SignalDeck/Assets.xcassets`: colors and app icons
- `scripts/`: source and generator for the app icon

## License

Released under the MIT License. See `LICENSE`.

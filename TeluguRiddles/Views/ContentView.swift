import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: RiddleStore
    @EnvironmentObject private var progressStore: RiddleProgressStore
    @StateObject private var dailyNotifier = DailyRiddleNotifier()
    @AppStorage("dailyRiddleNotificationsEnabled") private var dailyRiddleNotificationsEnabled = false
    @State private var languageMode: LanguageMode = .telugu
    @State private var playMode: PlayMode = .solo
    @State private var selectedCategory = "అన్ని"
    @State private var gameLength: GameLength = .twenty
    @State private var skipSeenRiddles = true
    @State private var teams: [GameTeam] = [
        GameTeam(name: "జట్టు 1"),
        GameTeam(name: "జట్టు 2")
    ]
    @State private var isPlaying = false

    private var copy: AppCopy {
        AppCopy(mode: languageMode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        quickStats
                        languageOptions
                        gameOptions
                        progressOptions
                        dailyRiddleOptions
                        answerStats
                        if playMode == .teams {
                            teamEditor
                        }
                        startButton
                    }
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $isPlaying) {
                GameView(
                    riddles: gameDeck,
                    gameLength: gameLength,
                    playMode: playMode,
                    languageMode: languageMode,
                    teams: playMode == .teams ? teams : []
                )
            }
            .onAppear {
                refreshDailyRiddleNotificationsIfNeeded()
            }
            .onChange(of: languageMode) { _ in
                refreshDailyRiddleNotificationsIfNeeded()
            }
        }
    }

    private var gameDeck: [Riddle] {
        skipSeenRiddles
            ? store.riddles(in: selectedCategory, excludingSeen: progressStore.seenIDs)
            : store.riddles(in: selectedCategory)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(copy.appTitle)
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.75)

            Text(copy.subtitle)
                .font(.title3)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(store.riddles.count)", label: copy.riddles)
            StatTile(value: "\(max(store.categories.count - 1, 0))", label: copy.categories)
            StatTile(value: "\(progressStore.favoriteIDs.count)", label: copy.favorites)
        }
    }

    private var languageOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.language)

            Picker(copy.language, selection: $languageMode) {
                ForEach(LanguageMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var gameOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.gameOptions)

            Picker(copy.playMode, selection: $playMode) {
                ForEach(PlayMode.allCases) { mode in
                    Text(mode.title(for: languageMode)).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Picker(copy.category, selection: $selectedCategory) {
                ForEach(store.categories, id: \.self) { category in
                    Text(store.title(for: category, mode: languageMode, allTitle: copy.allCategories))
                        .tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Picker(copy.rounds, selection: $gameLength) {
                ForEach(GameLength.allCases) { length in
                    Text(length.title(for: languageMode)).tag(length)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var progressOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.memory)

            Toggle(isOn: $skipSeenRiddles) {
                Label(copy.skipSeen, systemImage: "eye.slash")
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Button {
                progressStore.clearSeen()
            } label: {
                Label(copy.clearSeen, systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(progressStore.seenIDs.isEmpty)
        }
    }

    private var dailyRiddleOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.dailyRiddle)

            Toggle(isOn: Binding(
                get: { dailyRiddleNotificationsEnabled },
                set: setDailyRiddleNotifications
            )) {
                Label(copy.dailyRiddleNotification, systemImage: "bell.badge")
                    .foregroundStyle(AppTheme.ink)
            }
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            if dailyNotifier.authorizationDenied {
                InfoStrip(title: copy.notificationsOff, text: copy.notificationsOffMessage, systemImage: "bell.slash")
            }
        }
    }

    private var answerStats: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.stats)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(value: "\(progressStore.correctAnswerCount)", label: copy.correctAnswers)
                StatTile(value: "\(progressStore.wrongAnswerCount)", label: copy.wrongAnswers)
                StatTile(value: "\(progressStore.currentStreak)", label: copy.currentStreak)
                StatTile(value: "\(progressStore.longestStreak)", label: copy.longestStreak)
            }

            Button {
                progressStore.clearAnswerStats()
            } label: {
                Label(copy.clearStats, systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(SecondaryButtonStyle())
            .disabled(!progressStore.hasAnswerStats)
        }
    }

    private var teamEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle(copy.teams)

            ForEach($teams) { $team in
                TextField(copy.teamName, text: $team.name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button {
                    guard teams.count < 6 else { return }
                    teams.append(GameTeam(name: copy.defaultTeamName(teams.count + 1)))
                } label: {
                    Label(copy.addTeam, systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(teams.count >= 6)

                Button {
                    guard teams.count > 1 else { return }
                    teams.removeLast()
                } label: {
                    Label(copy.remove, systemImage: "minus")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(teams.count <= 1)
            }
        }
    }

    private var startButton: some View {
        Button {
            isPlaying = true
        } label: {
            Label(copy.start, systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.riddles.isEmpty)
        .padding(.top, 6)
    }

    private func setDailyRiddleNotifications(_ enabled: Bool) {
        dailyRiddleNotificationsEnabled = enabled

        if enabled {
            refreshDailyRiddleNotificationsIfNeeded()
        } else {
            dailyNotifier.cancelDailyRiddles()
        }
    }

    private func refreshDailyRiddleNotificationsIfNeeded() {
        guard dailyRiddleNotificationsEnabled else { return }

        Task {
            let scheduled = await dailyNotifier.scheduleDailyRiddles(from: store.riddles, mode: languageMode)
            if !scheduled {
                dailyRiddleNotificationsEnabled = false
            }
        }
    }
}

struct GameView: View {
    let riddles: [Riddle]
    let gameLength: GameLength
    let playMode: PlayMode
    let languageMode: LanguageMode

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var progressStore: RiddleProgressStore
    @State private var session: GameSession
    @State private var showHint = false
    @State private var showAnswer = false
    @State private var showResults = false
    @State private var answerText = ""
    @State private var answerFeedback: AnswerFeedback?
    @State private var attemptRecordedForCurrentRiddle = false

    private var copy: AppCopy {
        AppCopy(mode: languageMode)
    }

    init(riddles: [Riddle], gameLength: GameLength, playMode: PlayMode, languageMode: LanguageMode, teams: [GameTeam]) {
        self.riddles = riddles
        self.gameLength = gameLength
        self.playMode = playMode
        self.languageMode = languageMode
        _session = State(initialValue: GameSession(riddles: riddles, gameLength: gameLength, teams: teams))
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let riddle = session.currentRiddle {
                ScrollView {
                    VStack(spacing: 18) {
                        topBar
                        if playMode == .teams {
                            scoreBoard
                        }
                        riddleCard(riddle)
                        answerEntry(riddle)
                        actionRow
                    }
                    .padding(20)
                }
                .scrollDismissesKeyboard(.interactively)
            } else {
                EmptyDeckView(copy: copy)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if let riddle = session.currentRiddle {
                progressStore.markSeen(riddle)
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(copy.end) {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(teams: session.teams, playMode: playMode, copy: copy) {
                dismiss()
            }
            .interactiveDismissDisabled()
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            if playMode == .teams {
                Text("\(copy.now): \(session.activeTeamName)")
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.ink)
            } else {
                Text(copy.soloPlay)
                    .font(.title2.bold())
                    .foregroundStyle(AppTheme.ink)
            }

            Text(session.progressText(for: languageMode))
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var scoreBoard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(session.teams.enumerated()), id: \.element.id) { index, team in
                    VStack(spacing: 4) {
                        Text(team.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("\(team.score)")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(index == session.activeTeamIndex ? .white : AppTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(index == session.activeTeamIndex ? AppTheme.primary : AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func riddleCard(_ riddle: Riddle) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(riddle.category(for: languageMode))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Text(riddle.difficulty(for: languageMode))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)

                Button {
                    progressStore.toggleFavorite(riddle)
                } label: {
                    Image(systemName: progressStore.isFavorite(riddle) ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundStyle(progressStore.isFavorite(riddle) ? AppTheme.primary : AppTheme.muted)
                        .accessibilityLabel(progressStore.isFavorite(riddle) ? copy.removeFavorite : copy.addFavorite)
                }
                .buttonStyle(.plain)
            }

            Text(riddle.question(for: languageMode))
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(7)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
                .multilineTextAlignment(.center)

            if showHint {
                InfoStrip(title: copy.hint, text: riddle.hint(for: languageMode), systemImage: "lightbulb")
            }

            if showAnswer {
                InfoStrip(title: copy.answer, text: riddle.answer(for: languageMode), systemImage: "checkmark.circle")
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.08), radius: 18, y: 8)
    }

    private var actionRow: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button {
                    showHint.toggle()
                } label: {
                    Label(copy.hint, systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    showAnswer.toggle()
                } label: {
                    Label(showAnswer ? copy.hideAnswer : copy.answer, systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            if playMode == .teams {
                HStack(spacing: 12) {
                    Button {
                        nextRound(scored: false)
                    } label: {
                        Label(copy.pass, systemImage: "forward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    Button {
                        nextRound(scored: true)
                    } label: {
                        Label(copy.correct, systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
            } else {
                Button {
                    nextRound(scored: false)
                } label: {
                    Label(copy.next, systemImage: "arrow.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func answerEntry(_ riddle: Riddle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                TextField(copy.answerPlaceholder, text: $answerText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .submitLabel(.done)
                    .onSubmit {
                        submitAnswer(for: riddle)
                    }
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Button {
                    submitAnswer(for: riddle)
                } label: {
                    Label(copy.submitAnswer, systemImage: "paperplane.fill")
                        .labelStyle(.iconOnly)
                        .frame(width: 48, height: 48)
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(answerText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .accessibilityLabel(copy.submitAnswer)
            }

            if let answerFeedback {
                InfoStrip(
                    title: answerFeedback.isCorrect ? copy.correct : copy.tryAgain,
                    text: answerFeedback.isCorrect ? copy.correctAnswerMessage : copy.wrongAnswerMessage,
                    systemImage: answerFeedback.isCorrect ? "checkmark.circle" : "xmark.circle"
                )
            }
        }
    }

    private func nextRound(scored: Bool) {
        if playMode == .teams && !attemptRecordedForCurrentRiddle {
            progressStore.recordAttempt(isCorrect: scored)
        }

        session.advance(scored: scored)
        showHint = false
        showAnswer = false
        answerText = ""
        answerFeedback = nil
        attemptRecordedForCurrentRiddle = false

        if session.isFinished {
            showResults = true
            return
        }

        if let riddle = session.currentRiddle {
            progressStore.markSeen(riddle)
        }
    }

    private func submitAnswer(for riddle: Riddle) {
        let isCorrect = AnswerValidator.isCorrect(answerText, for: riddle, mode: languageMode)
        answerFeedback = isCorrect ? .correct : .wrong
        showAnswer = true

        guard !attemptRecordedForCurrentRiddle else { return }
        progressStore.recordAttempt(isCorrect: isCorrect)
        attemptRecordedForCurrentRiddle = true
    }
}

private enum AnswerFeedback {
    case correct
    case wrong

    var isCorrect: Bool {
        self == .correct
    }
}

struct ResultsView: View {
    let teams: [GameTeam]
    let playMode: PlayMode
    let copy: AppCopy
    let done: () -> Void

    private var sortedTeams: [GameTeam] {
        teams.sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Text(playMode == .teams ? copy.results : copy.complete)
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)

                if playMode == .teams {
                    ForEach(sortedTeams) { team in
                        HStack {
                            Text(team.name)
                                .font(.headline)
                            Spacer()
                            Text("\(team.score)")
                                .font(.title3.bold())
                        }
                        .foregroundStyle(AppTheme.ink)
                        .padding(16)
                        .background(AppTheme.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } else {
                    Text(copy.completeMessage)
                        .font(.title3)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(AppTheme.muted)
                        .padding(.horizontal)
                }

                Button(copy.backToStart) {
                    done()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.top, 8)
            }
            .padding(20)
        }
    }
}

struct EmptyDeckView: View {
    let copy: AppCopy

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.app")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primary)
            Text(copy.noRiddles)
                .font(.title2.bold())
                .foregroundStyle(AppTheme.ink)
        }
        .padding()
    }
}

struct StatTile: View {
    let value: String
    let label: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundStyle(AppTheme.ink)
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SectionTitle: View {
    let title: String

    init(_ title: String) {
        self.title = title
    }

    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(AppTheme.ink)
    }
}

struct InfoStrip: View {
    let title: String
    let text: String
    let systemImage: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(AppTheme.primary)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.muted)
                Text(text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppTheme.background)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppTheme.primary.opacity(configuration.isPressed ? 0.78 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(AppTheme.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(AppTheme.surface.opacity(configuration.isPressed ? 0.72 : 1))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

enum AppTheme {
    static let background = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let surface = Color.white
    static let ink = Color(red: 0.16, green: 0.13, blue: 0.10)
    static let muted = Color(red: 0.46, green: 0.39, blue: 0.32)
    static let primary = Color(red: 0.70, green: 0.18, blue: 0.16)
}

struct AppCopy {
    let mode: LanguageMode

    private var english: Bool {
        mode.usesEnglishChrome
    }

    var appTitle: String { english ? "Telugu Riddles" : "తెలుగు పొడుపు కథలు" }
    var subtitle: String { english ? "A family riddle game for a lively evening together." : "కుటుంబం కలిసి సాయంత్రం ఆడుకునే సరదా ప్రశ్నల ఆట." }
    var riddles: String { english ? "Riddles" : "పొడుపులు" }
    var categories: String { english ? "Categories" : "వర్గాలు" }
    var favorites: String { english ? "Favorites" : "ఇష్టమైనవి" }
    var language: String { english ? "Language" : "భాష" }
    var gameOptions: String { english ? "Game Options" : "ఆట ఎంపికలు" }
    var playMode: String { english ? "Play Mode" : "ఆట విధానం" }
    var category: String { english ? "Category" : "వర్గం" }
    var allCategories: String { english ? "All" : "అన్ని" }
    var rounds: String { english ? "Rounds" : "రౌండ్లు" }
    var memory: String { english ? "Memory" : "గుర్తుంచుకోవడం" }
    var skipSeen: String { english ? "Skip seen riddles" : "చూసిన పొడుపులను దాటవేయి" }
    var clearSeen: String { english ? "Clear seen list" : "చూసిన జాబితా తొలగించు" }
    var dailyRiddle: String { english ? "Daily Riddle" : "రోజువారీ పొడుపు" }
    var dailyRiddleNotification: String { english ? "Riddle of the day at 7 PM" : "సాయంత్రం 7కి ఈరోజు పొడుపు" }
    var notificationsOff: String { english ? "Notifications Off" : "నోటిఫికేషన్లు ఆఫ్" }
    var notificationsOffMessage: String { english ? "Enable notifications in Settings to receive the daily riddle." : "రోజువారీ పొడుపు రావాలంటే Settings లో notifications ప్రారంభించండి." }
    var stats: String { english ? "Stats" : "గణాంకాలు" }
    var correctAnswers: String { english ? "Correct" : "సరైనవి" }
    var wrongAnswers: String { english ? "Wrong" : "తప్పైనవి" }
    var currentStreak: String { english ? "Streak" : "వరుస" }
    var longestStreak: String { english ? "Best Streak" : "ఉత్తమ వరుస" }
    var clearStats: String { english ? "Clear stats" : "గణాంకాలు తొలగించు" }
    var teams: String { english ? "Teams" : "జట్లు" }
    var teamName: String { english ? "Team name" : "జట్టు పేరు" }
    var addTeam: String { english ? "Add Team" : "జట్టు జోడించు" }
    var remove: String { english ? "Remove" : "తీసివేయి" }
    var start: String { english ? "Start Game" : "ఆట ప్రారంభించు" }
    var end: String { english ? "End" : "ముగించు" }
    var now: String { english ? "Now" : "ఇప్పుడు" }
    var soloPlay: String { english ? "Solo Play" : "ఒంటరి ఆట" }
    var hint: String { english ? "Hint" : "సూచన" }
    var answer: String { english ? "Answer" : "జవాబు" }
    var answerPlaceholder: String { english ? "Type your answer" : "మీ జవాబు టైప్ చేయండి" }
    var submitAnswer: String { english ? "Submit answer" : "జవాబు పంపు" }
    var tryAgain: String { english ? "Not Quite" : "సరిపోలేదు" }
    var correctAnswerMessage: String { english ? "Nice. The answer is revealed below." : "బాగుంది. జవాబు క్రింద చూపించాం." }
    var wrongAnswerMessage: String { english ? "Good try. The answer is revealed below." : "మంచి ప్రయత్నం. జవాబు క్రింద చూపించాం." }
    var hideAnswer: String { english ? "Hide" : "దాచు" }
    var pass: String { english ? "Pass" : "పాస్" }
    var correct: String { english ? "Correct" : "సరైంది" }
    var next: String { english ? "Next" : "తర్వాత" }
    var results: String { english ? "Results" : "ఫలితాలు" }
    var complete: String { english ? "Complete" : "పూర్తైంది" }
    var completeMessage: String { english ? "You finished this round of riddles." : "ఈ పొడుపుల రౌండ్ పూర్తైంది." }
    var backToStart: String { english ? "Back to Start" : "మళ్లీ మొదలుకు" }
    var noRiddles: String { english ? "No riddles found" : "పొడుపులు కనిపించలేదు" }
    var addFavorite: String { english ? "Add Favorite" : "ఇష్టమైనది చేయి" }
    var removeFavorite: String { english ? "Remove Favorite" : "ఇష్టమైనది తొలగించు" }

    func defaultTeamName(_ number: Int) -> String {
        english ? "Team \(number)" : "జట్టు \(number)"
    }
}

#Preview {
    ContentView()
        .environmentObject(RiddleStore())
        .environmentObject(RiddleProgressStore())
}

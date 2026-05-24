import SwiftUI

#if canImport(GoogleMobileAds)
import GoogleMobileAds
#endif

struct ContentView: View {
    @EnvironmentObject private var store: RiddleStore
    @EnvironmentObject private var progressStore: RiddleProgressStore
    @StateObject private var dailyNotifier = DailyRiddleNotifier()
    @AppStorage("dailyRiddleNotificationsEnabled") private var dailyRiddleNotificationsEnabled = false
    @State private var languageMode: LanguageMode = .hybrid
    @State private var playMode: PlayMode = .solo
    @State private var selectedCategory = "అన్ని"
    @State private var selectedLevel: RiddleLevel = .shuffle
    @State private var gameLength: GameLength = .twenty
    @State private var skipSeenRiddles = true
    @State private var teams: [GameTeam] = [
        GameTeam(name: ""),
        GameTeam(name: "")
    ]
    @State private var isPlaying = false

    private var copy: AppCopy {
        AppCopy(mode: languageMode)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppBackground()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        quickStats
                        languageOptions
                        gameOptions
                        progressOptions
                        dailyRiddleOptions
                        answerStats
                    }
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(20)
                    .padding(.bottom, AdConfiguration.homeBottomContentPadding)
                }
                .scrollIndicators(.visible)
                .scrollDismissesKeyboard(.interactively)
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 8) {
                    startButton
                    AdBannerSlot(placement: .home)
                }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 10)
                    .background(AppTheme.background.opacity(0.96))
            }
            .navigationDestination(isPresented: $isPlaying) {
                GameView(
                    riddles: gameDeck,
                    gameLength: gameLength,
                    playMode: playMode,
                    languageMode: languageMode,
                    teams: playMode == .teams ? preparedTeams : []
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
            ? store.riddles(in: selectedCategory, level: selectedLevel, excludingSeen: progressStore.seenIDs)
            : store.riddles(in: selectedCategory, level: selectedLevel)
    }

    private var preparedTeams: [GameTeam] {
        teams.enumerated().map { index, team in
            var prepared = team
            let trimmedName = team.name.trimmingCharacters(in: .whitespacesAndNewlines)
            prepared.name = trimmedName.isEmpty ? "Team \(index + 1)" : trimmedName
            return prepared
        }
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
            NavigationLink {
                FavoritesView(languageMode: languageMode)
            } label: {
                StatTile(value: "\(progressStore.favoriteIDs.count)", label: copy.favorites, systemImage: "heart.fill")
            }
            .buttonStyle(.plain)
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

            if playMode == .teams {
                teamEditor
                    .padding(.top, 2)
            }

            levelSelector

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

    private var levelSelector: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(copy.level)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(RiddleLevel.allCases) { level in
                    Button {
                        selectedLevel = level
                    } label: {
                        HStack(spacing: 9) {
                            Image(systemName: level.systemImage)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(selectedLevel == level ? .white : AppTheme.levelColor(for: level))
                                .frame(width: 26, height: 26)
                                .background(selectedLevel == level ? .white.opacity(0.18) : AppTheme.levelColor(for: level).opacity(0.12))
                                .clipShape(Circle())

                            Text(level.title(for: languageMode))
                                .font(.subheadline.weight(.bold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)

                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(selectedLevel == level ? .white : AppTheme.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 11)
                        .frame(maxWidth: .infinity)
                        .background(selectedLevel == level ? AppTheme.levelColor(for: level) : AppTheme.surface.opacity(0.88))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(selectedLevel == level ? .white.opacity(0.34) : AppTheme.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .shadow(color: selectedLevel == level ? AppTheme.levelColor(for: level).opacity(0.18) : .black.opacity(0.04), radius: 8, x: 0, y: 4)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.58))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.70), lineWidth: 1)
        )
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

            ForEach(teams.indices, id: \.self) { index in
                TextField(copy.teamNamePlaceholder(index + 1), text: $teams[index].name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button {
                    guard teams.count < 6 else { return }
                    teams.append(GameTeam(name: ""))
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

    private var canRevealAnswer: Bool {
        showHint || attemptRecordedForCurrentRiddle
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
            AppBackground()

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
                InfoStrip(title: copy.hint, text: riddle.hint(for: languageMode), systemImage: "lightbulb.fill", tone: AppTheme.warning)
            }

            if showAnswer {
                InfoStrip(title: copy.answer, text: riddle.answer(for: languageMode), systemImage: "checkmark.seal.fill", tone: AppTheme.success)
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.surface,
                            Color(red: 1.0, green: 0.985, blue: 0.94)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: AppTheme.primary.opacity(0.10), radius: 18, x: 0, y: 10)
        .shadow(color: .black.opacity(0.04), radius: 3, x: 0, y: 1)
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
                    guard canRevealAnswer else { return }
                    showAnswer.toggle()
                } label: {
                    Label(showAnswer ? copy.hideAnswer : copy.answer, systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(!canRevealAnswer)
                .accessibilityHint(canRevealAnswer ? "" : copy.answerRevealLocked)
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
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.surface)
                            .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 5)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(answerFeedback?.isCorrect == true ? AppTheme.success : AppTheme.border, lineWidth: 1.2)
                    )
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
                    systemImage: answerFeedback.isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill",
                    tone: answerFeedback.isCorrect ? AppTheme.success : AppTheme.error
                )
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.white.opacity(0.54))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.white.opacity(0.72), lineWidth: 1)
        )
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
            AppBackground()

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

                AdBannerSlot(placement: .results)
                    .padding(.top, 2)
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

struct FavoritesView: View {
    let languageMode: LanguageMode

    @EnvironmentObject private var store: RiddleStore
    @EnvironmentObject private var progressStore: RiddleProgressStore

    private var copy: AppCopy {
        AppCopy(mode: languageMode)
    }

    private var favoriteRiddles: [Riddle] {
        store.riddles.filter { progressStore.favoriteIDs.contains($0.id) }
    }

    var body: some View {
        ZStack {
            AppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(copy.favoriteReview)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.ink)

                    if favoriteRiddles.isEmpty {
                        InfoStrip(title: copy.noFavorites, text: copy.noFavoritesMessage, systemImage: "heart", tone: AppTheme.primary)
                    } else {
                        ForEach(favoriteRiddles) { riddle in
                            FavoriteRiddleCard(riddle: riddle, languageMode: languageMode, copy: copy)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.visible)
        }
        .navigationTitle(copy.favorites)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FavoriteRiddleCard: View {
    let riddle: Riddle
    let languageMode: LanguageMode
    let copy: AppCopy

    @EnvironmentObject private var progressStore: RiddleProgressStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Text(riddle.category(for: languageMode))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())

                Text(riddle.difficulty(for: languageMode))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)

                Spacer()

                Button {
                    progressStore.toggleFavorite(riddle)
                } label: {
                    Image(systemName: "heart.fill")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primary)
                        .accessibilityLabel(copy.removeFavorite)
                }
                .buttonStyle(.plain)
            }

            Text(riddle.question(for: languageMode))
                .font(.headline.weight(.bold))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(4)

            HStack(alignment: .top, spacing: 10) {
                Label(copy.hint, systemImage: "lightbulb.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.warning)
                    .frame(width: 74, alignment: .leading)

                Text(riddle.hint(for: languageMode))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.muted)
            }

            HStack(alignment: .top, spacing: 10) {
                Label(copy.answer, systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.success)
                    .frame(width: 74, alignment: .leading)

                Text(riddle.answer(for: languageMode))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
            }
        }
        .padding(16)
        .background(AppTheme.surface.opacity(0.96))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border.opacity(0.85), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

private enum AdPlacement {
    case home
    case results

    var accessibilityLabel: String {
        switch self {
        case .home:
            return "Home banner advertisement"
        case .results:
            return "Results banner advertisement"
        }
    }
}

private enum AdConfiguration {
    static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2435281174"
    static let bannerAdUnitID = testBannerAdUnitID
    static let reservedBannerHeight: CGFloat = 58
    static let homeBottomContentPadding: CGFloat = 168
}

private struct AdBannerSlot: View {
    let placement: AdPlacement

    var body: some View {
        GeometryReader { proxy in
            bannerContent(width: max(proxy.size.width, 320))
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: AdConfiguration.reservedBannerHeight)
        .accessibilityLabel(placement.accessibilityLabel)
    }

    @ViewBuilder
    private func bannerContent(width: CGFloat) -> some View {
        #if canImport(GoogleMobileAds)
        let adSize = largeAnchoredAdaptiveBanner(width: width)
        AdaptiveBannerView(adUnitID: AdConfiguration.bannerAdUnitID, adSize: adSize)
            .frame(width: adSize.size.width, height: adSize.size.height)
        #else
        #if DEBUG
        developmentPlaceholder
        #endif
        #endif
    }

    private var developmentPlaceholder: some View {
        HStack(spacing: 8) {
            Image(systemName: "rectangle.inset.filled")
                .font(.caption.weight(.bold))
            Text("Ad preview")
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(AppTheme.muted)
        .frame(maxWidth: .infinity, minHeight: AdConfiguration.reservedBannerHeight)
        .background(AppTheme.surface.opacity(0.72))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(AppTheme.border.opacity(0.7), style: StrokeStyle(lineWidth: 1, dash: [5, 4]))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#if canImport(GoogleMobileAds)
private struct AdaptiveBannerView: UIViewRepresentable {
    let adUnitID: String
    let adSize: AdSize

    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: adSize)
        banner.adUnitID = adUnitID
        banner.delegate = context.coordinator
        banner.load(Request())
        return banner
    }

    func updateUIView(_ banner: BannerView, context: Context) {
        banner.adSize = adSize
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator: NSObject, BannerViewDelegate {
        func bannerView(_ bannerView: BannerView, didFailToReceiveAdWithError error: Error) {
            #if DEBUG
            print("Banner ad failed to load: \(error.localizedDescription)")
            #endif
        }
    }
}
#endif

struct StatTile: View {
    let value: String
    let label: String
    var systemImage: String?

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title.bold())
                    .foregroundStyle(AppTheme.ink)
                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            Spacer(minLength: 0)

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primary)
            }
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
    var tone: Color = AppTheme.primary

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(tone)
                .clipShape(Circle())
                .shadow(color: tone.opacity(0.25), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(tone)
                    .textCase(.uppercase)
                Text(text)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(AppTheme.ink)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(15)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(
                    LinearGradient(
                        colors: [
                            tone.opacity(0.13),
                            AppTheme.surface.opacity(0.92)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(tone.opacity(0.26), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: tone.opacity(0.10), radius: 14, x: 0, y: 8)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? .white : AppTheme.disabledInk)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(buttonBackground(isPressed: configuration.isPressed))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func buttonBackground(isPressed: Bool) -> Color {
        if !isEnabled {
            return AppTheme.disabledSurface
        }

        return AppTheme.primary.opacity(isPressed ? 0.78 : 1)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.disabledInk)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .background(isEnabled ? AppTheme.surface.opacity(configuration.isPressed ? 0.72 : 1) : AppTheme.disabledSurface)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 1.00, green: 0.93, blue: 0.72),
                AppTheme.background,
                Color(red: 0.90, green: 0.96, blue: 0.90)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay(alignment: .topTrailing) {
            Image(systemName: "sparkles")
                .font(.system(size: 86, weight: .light))
                .foregroundStyle(AppTheme.primary.opacity(0.09))
                .padding(.top, 54)
                .padding(.trailing, 28)
        }
        .overlay(alignment: .bottomLeading) {
            Image(systemName: "questionmark.bubble.fill")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(red: 0.20, green: 0.46, blue: 0.38).opacity(0.09))
                .padding(.leading, 24)
                .padding(.bottom, 84)
        }
        .overlay {
            VStack(spacing: 46) {
                ForEach(0..<8, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(AppTheme.primary.opacity(0.025))
                        .frame(height: 2)
                        .rotationEffect(.degrees(-8))
                }
            }
            .padding(.horizontal, -80)
            .allowsHitTesting(false)
        }
    }
}

enum AppTheme {
    static let background = Color(red: 0.98, green: 0.95, blue: 0.88)
    static let surface = Color.white
    static let ink = Color(red: 0.16, green: 0.13, blue: 0.10)
    static let muted = Color(red: 0.46, green: 0.39, blue: 0.32)
    static let primary = Color(red: 0.70, green: 0.18, blue: 0.16)
    static let warning = Color(red: 0.88, green: 0.52, blue: 0.10)
    static let success = Color(red: 0.15, green: 0.50, blue: 0.35)
    static let error = Color(red: 0.72, green: 0.18, blue: 0.18)
    static let border = Color(red: 0.88, green: 0.78, blue: 0.61)
    static let disabledSurface = Color(red: 0.84, green: 0.82, blue: 0.77)
    static let disabledInk = Color(red: 0.50, green: 0.48, blue: 0.43)

    static func levelColor(for level: RiddleLevel) -> Color {
        switch level {
        case .shuffle:
            return primary
        case .easy:
            return Color(red: 0.20, green: 0.55, blue: 0.35)
        case .medium:
            return Color(red: 0.82, green: 0.46, blue: 0.10)
        case .hard:
            return Color(red: 0.54, green: 0.20, blue: 0.62)
        }
    }
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
    var favoriteReview: String { english ? "Favorites Review" : "ఇష్టమైన పొడుపులు" }
    var noFavorites: String { english ? "No favorites yet" : "ఇంకా ఇష్టమైనవి లేవు" }
    var noFavoritesMessage: String { english ? "Tap the heart on any riddle during a game to save it here for later review." : "ఆటలో ఏ పొడుపుపైనా గుండె గుర్తును నొక్కితే, తర్వాత చూడటానికి ఇక్కడ సేవ్ అవుతుంది." }
    var language: String { english ? "Language" : "భాష" }
    var gameOptions: String { english ? "Game Options" : "ఆట ఎంపికలు" }
    var playMode: String { english ? "Play Mode" : "ఆట విధానం" }
    var level: String { english ? "Level" : "స్థాయి" }
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
    var correctAnswerMessage: String { english ? "Nice. You can reveal the answer now." : "బాగుంది. ఇప్పుడు జవాబు చూడొచ్చు." }
    var wrongAnswerMessage: String { english ? "Good try. You can reveal the answer now." : "మంచి ప్రయత్నం. ఇప్పుడు జవాబు చూడొచ్చు." }
    var answerRevealLocked: String { english ? "Try an answer or view a hint first." : "ముందు జవాబు ప్రయత్నించండి లేదా సూచన చూడండి." }
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

    func teamNamePlaceholder(_ number: Int) -> String {
        english ? "Example: Team \(number)" : "ఉదా: Team \(number)"
    }
}

#Preview {
    ContentView()
        .environmentObject(RiddleStore())
        .environmentObject(RiddleProgressStore())
}

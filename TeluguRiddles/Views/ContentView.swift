import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var store: RiddleStore
    @State private var selectedCategory = "అన్ని"
    @State private var gameLength: GameLength = .twenty
    @State private var teams: [GameTeam] = [
        GameTeam(name: "జట్టు 1"),
        GameTeam(name: "జట్టు 2")
    ]
    @State private var isPlaying = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header
                        quickStats
                        gameOptions
                        teamEditor
                        startButton
                    }
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $isPlaying) {
                GameView(
                    riddles: store.riddles(in: selectedCategory),
                    gameLength: gameLength,
                    teams: teams
                )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("తెలుగు పొడుపు కథలు")
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .minimumScaleFactor(0.8)

            Text("కుటుంబం కలిసి సాయంత్రం ఆడుకునే సరదా ప్రశ్నల ఆట.")
                .font(.title3)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 16)
    }

    private var quickStats: some View {
        HStack(spacing: 12) {
            StatTile(value: "\(store.riddles.count)", label: "పొడుపులు")
            StatTile(value: "\(max(store.categories.count - 1, 0))", label: "వర్గాలు")
            StatTile(value: "2+", label: "జట్లు")
        }
    }

    private var gameOptions: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("ఆట ఎంపికలు")

            Picker("వర్గం", selection: $selectedCategory) {
                ForEach(store.categories, id: \.self) { category in
                    Text(category).tag(category)
                }
            }
            .pickerStyle(.menu)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            Picker("రౌండ్లు", selection: $gameLength) {
                ForEach(GameLength.allCases) { length in
                    Text(length.title).tag(length)
                }
            }
            .pickerStyle(.segmented)
        }
    }

    private var teamEditor: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionTitle("జట్లు")

            ForEach($teams) { $team in
                TextField("జట్టు పేరు", text: $team.name)
                    .textInputAutocapitalization(.words)
                    .padding(14)
                    .background(AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            HStack {
                Button {
                    guard teams.count < 6 else { return }
                    teams.append(GameTeam(name: "జట్టు \(teams.count + 1)"))
                } label: {
                    Label("జట్టు జోడించు", systemImage: "plus")
                }
                .buttonStyle(SecondaryButtonStyle())
                .disabled(teams.count >= 6)

                Button {
                    guard teams.count > 1 else { return }
                    teams.removeLast()
                } label: {
                    Label("తీసివేయి", systemImage: "minus")
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
            Label("ఆట ప్రారంభించు", systemImage: "play.fill")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(PrimaryButtonStyle())
        .disabled(store.riddles.isEmpty)
        .padding(.top, 6)
    }
}

struct GameView: View {
    let riddles: [Riddle]
    let gameLength: GameLength

    @Environment(\.dismiss) private var dismiss
    @State private var teams: [GameTeam]
    @State private var currentIndex = 0
    @State private var activeTeamIndex = 0
    @State private var showHint = false
    @State private var showAnswer = false
    @State private var showResults = false
    @State private var completedRounds = 0

    init(riddles: [Riddle], gameLength: GameLength, teams: [GameTeam]) {
        self.riddles = riddles
        self.gameLength = gameLength
        _teams = State(initialValue: teams)
    }

    private var currentRiddle: Riddle? {
        riddles.indices.contains(currentIndex) ? riddles[currentIndex] : nil
    }

    private var isFinished: Bool {
        gameLength != .endless && completedRounds >= gameLength.rawValue
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            if let riddle = currentRiddle {
                VStack(spacing: 18) {
                    topBar
                    scoreBoard
                    riddleCard(riddle)
                    actionRow
                    Spacer(minLength: 0)
                }
                .padding(20)
            } else {
                EmptyDeckView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("ముగించు") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showResults) {
            ResultsView(teams: teams) {
                dismiss()
            }
            .interactiveDismissDisabled()
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("ఇప్పుడు: \(teams[safe: activeTeamIndex]?.name ?? "జట్టు")")
                .font(.title2.bold())
                .foregroundStyle(AppTheme.ink)

            Text(progressText)
                .font(.subheadline)
                .foregroundStyle(AppTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var progressText: String {
        if gameLength == .endless {
            return "రౌండ్ \(completedRounds + 1)"
        }
        return "రౌండ్ \(min(completedRounds + 1, gameLength.rawValue)) / \(gameLength.rawValue)"
    }

    private var scoreBoard: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(Array(teams.enumerated()), id: \.element.id) { index, team in
                    VStack(spacing: 4) {
                        Text(team.name)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                        Text("\(team.score)")
                            .font(.title3.bold())
                    }
                    .foregroundStyle(index == activeTeamIndex ? .white : AppTheme.ink)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(index == activeTeamIndex ? AppTheme.primary : AppTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
    }

    private func riddleCard(_ riddle: Riddle) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack {
                Text(riddle.category)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(AppTheme.primary.opacity(0.12))
                    .clipShape(Capsule())

                Spacer()

                Text(riddle.difficulty)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.muted)
            }

            Text(riddle.question)
                .font(.system(size: 31, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.ink)
                .lineSpacing(7)
                .minimumScaleFactor(0.74)
                .frame(maxWidth: .infinity, minHeight: 190, alignment: .center)
                .multilineTextAlignment(.center)

            if showHint {
                InfoStrip(title: "సూచన", text: riddle.hint, systemImage: "lightbulb")
            }

            if showAnswer {
                InfoStrip(title: "జవాబు", text: riddle.answer, systemImage: "checkmark.circle")
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
                    Label("సూచన", systemImage: "lightbulb")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    showAnswer.toggle()
                } label: {
                    Label(showAnswer ? "దాచు" : "జవాబు", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())
            }

            HStack(spacing: 12) {
                Button {
                    nextRound(scored: false)
                } label: {
                    Label("పాస్", systemImage: "forward")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    nextRound(scored: true)
                } label: {
                    Label("సరైంది", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func nextRound(scored: Bool) {
        if scored, teams.indices.contains(activeTeamIndex) {
            teams[activeTeamIndex].score += 1
        }

        completedRounds += 1
        showHint = false
        showAnswer = false

        if isFinished {
            showResults = true
            return
        }

        currentIndex = (currentIndex + 1) % max(riddles.count, 1)
        activeTeamIndex = (activeTeamIndex + 1) % max(teams.count, 1)
    }
}

struct ResultsView: View {
    let teams: [GameTeam]
    let done: () -> Void

    private var sortedTeams: [GameTeam] {
        teams.sorted { $0.score > $1.score }
    }

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 18) {
                Text("ఫలితాలు")
                    .font(.largeTitle.bold())
                    .foregroundStyle(AppTheme.ink)

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

                Button("మళ్లీ మొదలుకు") {
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
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "questionmark.app")
                .font(.system(size: 44))
                .foregroundStyle(AppTheme.primary)
            Text("పొడుపులు కనిపించలేదు")
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

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
        .environmentObject(RiddleStore())
}

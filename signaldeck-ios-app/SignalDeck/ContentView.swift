import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var store = QuizStore()
    @State private var selectedTab: AppTab = .play
    @State private var startupScreenVisible = true

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                NavigationStack {
                    ZStack {
                        AppBackground()
                        DeferredTabContent(isActive: selectedTab == .play, retainAfterLoad: false) {
                            PlaySurfaceView(store: store)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tag(AppTab.play)
                .tabItem {
                    Label("Play", systemImage: "bolt.fill")
                }

                NavigationStack {
                    ZStack {
                        AppBackground()
                        DeferredTabContent(isActive: selectedTab == .learn, retainAfterLoad: true) {
                            LearnCenterView(store: store)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tag(AppTab.learn)
                .tabItem {
                    Label("Learn", systemImage: "book.closed.fill")
                }

                NavigationStack {
                    ZStack {
                        AppBackground()
                        DeferredTabContent(isActive: selectedTab == .create, retainAfterLoad: false) {
                            CreateQuestionView(store: store)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tag(AppTab.create)
                .tabItem {
                    Label("Create", systemImage: "square.and.pencil")
                }

                NavigationStack {
                    ZStack {
                        AppBackground()
                        DeferredTabContent(isActive: selectedTab == .user, retainAfterLoad: false) {
                            UserCenterView(store: store)
                        }
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
                .tag(AppTab.user)
                .tabItem {
                    Label("User", systemImage: "person.crop.circle.fill")
                }
            }
            .tint(Color(red: 0.17, green: 0.79, blue: 0.92))
            .preferredColorScheme(.dark)
            .toolbarBackground(.visible, for: .tabBar)
            .toolbarBackground(Color(red: 0.05, green: 0.08, blue: 0.12), for: .tabBar)
            .toolbarColorScheme(.dark, for: .tabBar)
            .opacity(startupScreenVisible ? 0.001 : 1)
            .allowsHitTesting(!startupScreenVisible)
        }
        .overlay {
            if startupScreenVisible {
                StartupWarmupCoordinator(
                    store: store,
                    startupScreenVisible: $startupScreenVisible
                )
            }
        }
    }
}

private enum AppTab: Hashable {
    case play
    case learn
    case user
    case create
}

private struct DeferredTabContent<Content: View>: View {
    let isActive: Bool
    var retainAfterLoad = true
    @ViewBuilder let content: () -> Content
    @State private var hasLoaded = false

    var body: some View {
        Group {
            if isActive || (retainAfterLoad && hasLoaded) {
                content()
            } else {
                Color.clear
            }
        }
        .onAppear {
            if isActive {
                hasLoaded = true
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                hasLoaded = true
            }
        }
    }
}

private struct StartupWarmupCoordinator: View {
    @ObservedObject var store: QuizStore
    @Binding var startupScreenVisible: Bool

    var body: some View {
        StartupLoadingView(deckReady: store.startupDataReady)
        .task {
            maybeFinishWarmup()
        }
        .onChange(of: store.startupDataReady) { _, _ in
            maybeFinishWarmup()
        }
    }

    private func maybeFinishWarmup() {
        guard startupScreenVisible else { return }
        guard store.startupDataReady else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            startupScreenVisible = false
        }
    }
}

private struct PlaySurfaceView: View {
    @ObservedObject var store: QuizStore

    var body: some View {
        switch store.phase {
        case .setup:
            AnyView(SetupView(store: store))
        case .session:
            AnyView(SessionView(store: store))
        case .results:
            AnyView(ResultsView(store: store))
        }
    }
}

private struct StartupLoadingView: View {
    let deckReady: Bool

    var body: some View {
        ZStack {
            AppBackground()
            VStack(spacing: 18) {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(.cyan)
                    .scaleEffect(1.3)

                VStack(spacing: 8) {
                    Text("Loading Signal Deck")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Preparing the deck.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.72))
                        .multilineTextAlignment(.center)
                }
                StartupStatusRow(label: "Deck", ready: deckReady)
                    .padding(16)
                    .glassCard()
            }
            .padding(24)
        }
        .ignoresSafeArea()
    }
}

private struct StartupStatusRow: View {
    let label: String
    let ready: Bool

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.white)
            Spacer()
            Text(ready ? "Ready" : "Loading")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ready ? Color(red: 0.54, green: 0.89, blue: 0.57) : .cyan)
        }
    }
}

private struct AppBackground: View {
    var body: some View {
        LinearGradient(
            colors: [
                Color(red: 0.05, green: 0.08, blue: 0.12),
                Color(red: 0.02, green: 0.12, blue: 0.17),
                Color(red: 0.01, green: 0.05, blue: 0.09),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .overlay(
            RadialGradient(
                colors: [Color(red: 0.18, green: 0.55, blue: 0.78).opacity(0.22), .clear],
                center: .topTrailing,
                startRadius: 20,
                endRadius: 420
            )
        )
        .ignoresSafeArea()
    }
}

private struct SetupView: View {
    @ObservedObject var store: QuizStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                if !store.hasDeckData {
                    ProgressView("Loading deck...")
                        .tint(.cyan)
                        .padding(18)
                        .glassCard()
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(store.brandDisplayName)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                        .textCase(.uppercase)
                        .onTapGesture(count: 5) {
                            store.toggleLiveGenerationMode()
                        }
                    Text("Signal Deck")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Choose the topics, difficulty, question count, and whether hints stay on, then run a timed or untimed deck. The app will still accept approximate answers and keep a live tape of submitted cards.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.75))
                    if let secretStatusMessage = store.secretStatusMessage {
                        Text(secretStatusMessage)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.cyan.opacity(0.85))
                    }
                }
                .padding(20)
                .glassCard()

                Button(action: store.startSession) {
                    Label("Start Session", systemImage: "play.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .buttonStyle(PrimaryButtonStyle())

                if let error = store.setupError {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 16) {
                    ConfigStepperRow(
                        title: "Question count",
                        subtitle: "How many cards in this run",
                        valueText: "\(store.questionCount)",
                        decrementDisabled: store.questionCount <= 5,
                        incrementDisabled: store.questionCount >= 100,
                        decrement: { store.questionCount = max(5, store.questionCount - 5) },
                        increment: { store.questionCount = min(100, store.questionCount + 5) }
                    )

                    ConfigStepperRow(
                        title: "Timer",
                        subtitle: "0 means untimed",
                        valueText: store.timerMinutes == 0 ? "Untimed" : "\(store.timerMinutes)m",
                        decrementDisabled: store.timerMinutes <= 0,
                        incrementDisabled: store.timerMinutes >= 100,
                        decrement: { store.timerMinutes = max(0, store.timerMinutes - 5) },
                        increment: { store.timerMinutes = min(100, store.timerMinutes + 5) }
                    )

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Difficulty")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .padding(.vertical, 2)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.triggerFreddybeanUnlockTap()
                            }
                        Picker("Difficulty", selection: $store.difficulty) {
                            ForEach(store.availableDifficulties) { difficulty in
                                Text(difficulty.label).tag(difficulty)
                            }
                        }
                        .pickerStyle(.segmented)
                    }

                    QuietToggleRow(
                        title: "Show hints",
                        subtitle: "Off by default, available during play if enabled here.",
                        isOn: $store.showHints
                    )

                    QuietToggleRow(
                        title: "Use intense timer mode",
                        subtitle: "Split the session timer across the questions. If a card times out, it is marked wrong and the deck moves on automatically.",
                        isOn: $store.intenseTimer
                    )

                    QuietToggleRow(
                        title: "Draw only from personal deck",
                        subtitle: "Use only saved cards. Topic filters, difficulty, hints, and intense timing still apply.",
                        isOn: Binding(
                            get: { store.personalDeckOnly },
                            set: { store.setPersonalDeckOnly($0) }
                        )
                    )

                    Text("\(store.personalDeckCount) saved card\(store.personalDeckCount == 1 ? "" : "s") available for personal-deck mode.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))

                    QuietToggleRow(
                        title: "Use custom cards",
                        subtitle: "Include your saved custom templates in the quiz pool. Trophies stay off for these runs.",
                        isOn: Binding(
                            get: { store.customCardsOnly },
                            set: { store.setCustomCardsOnly($0) }
                        )
                    )

                    Text("\(store.customTemplateCount) saved custom card template\(store.customTemplateCount == 1 ? "" : "s") available to add into the quiz pool.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.65))
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Topics")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        Button("All") { store.selectAllTopics() }
                            .foregroundStyle(.cyan)
                        Button("Clear") { store.clearTopics() }
                            .foregroundStyle(.white.opacity(0.7))
                    }

                    Text(store.topicSelectionSummary)
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.7))

                    FlexibleTagGrid(items: store.topics, selected: store.selectedTopicIds) { topic in
                        store.toggleTopic(topic.id)
                    }
                }
                .padding(18)
                .glassCard()
                .onAppear {
                    store.ensureTopicSelection()
                }

                if let best = store.bestScore {
                    Text("Best saved score: \(best)")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.8))
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.immediately)
    }
}

private struct SessionView: View {
    @ObservedObject var store: QuizStore
    @State private var hintSheetOpen = false
    @State private var graphSheetOpen = false

    var body: some View {
        GeometryReader { proxy in
            let compact = proxy.size.height <= 700
            let bottomReserved = compact ? CGFloat(286) : CGFloat(344)
            ZStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: compact ? 10 : 16) {
                    HStack(spacing: compact ? 8 : 12) {
                        SessionMetric(title: "Progress", value: store.progressLabel, compact: compact)
                        SessionMetric(title: "Timer", value: store.timerLabel, compact: compact)
                        SessionMetric(title: "Score", value: "\(store.liveScore)", compact: compact)
                    }

                    HStack(spacing: compact ? 6 : 8) {
                        Button {
                            store.reviewSheetOpen = true
                        } label: {
                            ResultCapsule(status: store.lastResultStatus, compact: compact, showLabel: !store.showHints)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .layoutPriority(1)

                        if store.showHints, let hint = store.currentQuestion?.hint, !hint.isEmpty {
                            Button {
                                hintSheetOpen = true
                            } label: {
                                Label("Hint", systemImage: "lightbulb")
                                    .font(.system(size: compact ? 12 : 14, weight: .semibold))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.8)
                                    .frame(width: compact ? 72 : 78, height: compact ? 34 : 40)
                            }
                            .buttonStyle(QuizOutlineButtonStyle(compact: compact))
                        }

                        Button {
                            store.addCurrentQuestionToPersonalDeck()
                        } label: {
                            Label(store.currentQuestionSavedToPersonalDeck ? "Saved" : "Deck+", systemImage: store.currentQuestionSavedToPersonalDeck ? "checkmark.circle.fill" : "plus.circle")
                                .font(.system(size: compact ? 11.5 : 13.5, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.75)
                                .frame(width: compact ? 78 : 86, height: compact ? 34 : 40)
                        }
                        .buttonStyle(QuizOutlineButtonStyle(compact: compact))
                        .disabled(store.currentQuestionSavedToPersonalDeck)

                        Button {
                            store.endSessionEarly()
                        } label: {
                            Label("End", systemImage: "stop.circle")
                                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: compact ? 68 : 76, height: compact ? 34 : 40)
                        }
                        .buttonStyle(QuizOutlineButtonStyle(compact: compact))

                        Button(role: .destructive) {
                            store.exitSession()
                        } label: {
                            Label("Exit", systemImage: "xmark")
                                .font(.system(size: compact ? 12 : 14, weight: .semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .frame(width: compact ? 66 : 72, height: compact ? 34 : 40)
                        }
                        .buttonStyle(QuizOutlineButtonStyle(compact: compact))
                    }

                    VStack(alignment: .leading, spacing: compact ? 10 : 14) {
                        Text(store.currentQuestion?.category ?? "")
                            .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
                            .foregroundStyle(.cyan)
                            .textCase(.uppercase)

                        promptView(
                            prompt: store.currentQuestion?.prompt ?? "",
                            visual: store.currentQuestion?.visual,
                            compact: compact
                        )

                        if let visual = store.currentQuestion?.visual, visual.type != "pnlChart" {
                            QuestionVisualView(visual: visual, compact: compact)
                        }
                    }
                    .padding(compact ? 14 : 20)
                    .glassCard()

                    Spacer(minLength: 0)
                }
                .padding(compact ? 12 : 16)
                .padding(.bottom, bottomReserved)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

                sessionBottomPanel(compact: compact)
                    .padding(.horizontal, compact ? 12 : 16)
                    .padding(.bottom, compact ? 12 : 20)
            }
        }
        .sheet(isPresented: $store.reviewSheetOpen) {
            NavigationStack {
                ReviewSheetView(store: store)
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $hintSheetOpen) {
            NavigationStack {
                HintSheetView(hint: readableHint(for: store.currentQuestion))
            }
            .presentationDetents([.height(220), .medium])
        }
        .sheet(isPresented: $graphSheetOpen) {
            if let visual = store.currentQuestion?.visual {
                NavigationStack {
                    GraphSheetView(visual: visual)
                }
                .presentationDetents([.medium, .large])
            }
        }
    }

    private func sessionBottomPanel(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: compact ? 8 : 12) {
            HStack(alignment: .center, spacing: compact ? 10 : 12) {
                Text("Your answer")
                    .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
                    .foregroundStyle(.white.opacity(0.72))
                    .frame(width: compact ? 72 : 88, alignment: .leading)
                Text(store.answerText.isEmpty ? "Type an estimate" : store.answerText)
                    .font(.system(size: compact ? 17 : 21, weight: .semibold, design: .rounded))
                    .foregroundStyle(store.answerText.isEmpty ? .white.opacity(0.35) : .white)
                    .frame(maxWidth: .infinity, minHeight: compact ? 40 : 54, alignment: .leading)
                    .padding(.horizontal, compact ? 12 : 16)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous))
            }

            KeypadView(
                compact: compact,
                insert: { token in store.answerText.append(token) },
                backspace: {
                    guard !store.answerText.isEmpty else { return }
                    store.answerText.removeLast()
                },
                clear: {
                    store.answerText = ""
                }
            )

            if let error = store.inputError {
                Text(error)
                    .font(compact ? .caption.weight(.semibold) : .footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }

            HStack(spacing: compact ? 8 : 12) {
                Button {
                    store.submitCurrentAnswer()
                } label: {
                    Label("Submit", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity, minHeight: compact ? 42 : 50)
                }
                .buttonStyle(QuizActionButtonStyle(primary: true, compact: compact))

                Button {
                    store.skipCurrentQuestion()
                } label: {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: .infinity, minHeight: compact ? 42 : 50)
                }
                .buttonStyle(QuizActionButtonStyle(primary: false, compact: compact))
            }
        }
        .padding(compact ? 14 : 18)
        .glassCard()
    }

    private func promptView(prompt: String, visual: QuestionVisual?, compact: Bool) -> some View {
        let font = Font.system(size: questionFontSize(prompt: prompt, compact: compact), weight: .semibold, design: .rounded)
        if let visual, visual.type == "pnlChart", prompt.localizedCaseInsensitiveContains("graph") {
            return AnyView(
                Text(graphLinkedPrompt(from: prompt))
                    .font(font)
                    .foregroundStyle(.white)
                    .tint(.cyan)
                    .fixedSize(horizontal: false, vertical: true)
                    .environment(\.openURL, OpenURLAction { url in
                        if url.absoluteString == "signaldeck://graph" {
                            graphSheetOpen = true
                            return .handled
                        }
                        return .discarded
                    })
            )
        }

        return AnyView(
            Text(prompt)
                .font(font)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        )
    }

    private func graphLinkedPrompt(from prompt: String) -> AttributedString {
        var attributed = AttributedString(prompt)
        if let range = attributed.range(of: "graph", options: .caseInsensitive) {
            attributed[range].link = URL(string: "signaldeck://graph")
            attributed[range].foregroundColor = .cyan
            attributed[range].underlineStyle = .single
        }
        return attributed
    }
}

private func questionFontSize(prompt: String, compact: Bool) -> CGFloat {
    let estimatedLines = estimatedPromptLines(prompt: prompt, compact: compact)
    if compact {
        if estimatedLines >= 8 { return 14 }
        if estimatedLines >= 6 { return 15.5 }
        if estimatedLines >= 5 { return 17 }
        return 18
    }
    if estimatedLines >= 8 { return 18 }
    if estimatedLines >= 6 { return 20 }
    if estimatedLines >= 5 { return 21.5 }
    return 23
}

private func estimatedPromptLines(prompt: String, compact: Bool) -> Int {
    let explicitLineBreaks = prompt.reduce(into: 1) { count, character in
        if character == "\n" { count += 1 }
    }
    let charsPerLine = compact ? 32 : 40
    let wrappedLines = max(1, Int(ceil(Double(prompt.count) / Double(charsPerLine))))
    return max(explicitLineBreaks, wrappedLines)
}

private struct ResultsView: View {
    @ObservedObject var store: QuizStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Round Complete")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.cyan)
                        .textCase(.uppercase)
                    Text("Score \(store.liveScore)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    HStack(spacing: 12) {
                        MiniMetric(label: "Correct", value: "\(store.correctCount)")
                        MiniMetric(label: "Wrong", value: "\(store.wrongCount)")
                        MiniMetric(label: "Skipped", value: "\(store.skippedCount)")
                    }
                }
                .padding(20)
                .glassCard()

                Button {
                    store.redoLastQuiz()
                } label: {
                    Label("Redo Quiz", systemImage: "arrow.clockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(PrimaryButtonStyle())

                Button {
                    store.resetToSetup()
                } label: {
                    Label("Exit Quiz", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(SecondaryButtonStyle())

                VStack(alignment: .leading, spacing: 12) {
                    Text("Solved Cards")
                        .font(.headline)
                        .foregroundStyle(.white)
                    ForEach(store.orderedResults) { result in
                        ReviewCard(result: result)
                    }
                }
            }
            .padding(16)
            .padding(.bottom, 24)
        }
    }
}

private struct LearnCenterView: View {
    @ObservedObject var store: QuizStore

    var body: some View {
        LearningGuideWebView(store: store)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color(red: 0.05, green: 0.08, blue: 0.12), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
}

private final class UserCenterDraft {
    var displayName = ""
    var recoveryCodeInput = ""
}

private struct UserCenterView: View {
    let store: QuizStore
    @State private var showClearMemoryAlert = false
    @State private var recoveryCodeOutput = ""
    @State private var recoveryStatus = ""
    @State private var draft = UserCenterDraft()
    @State private var fieldRevision = 0

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Center")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Track previous runs and see which topics are dragging your score down.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }
                .padding(20)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Your name")
                        .font(.headline)
                        .foregroundStyle(.white)

                    BoundTextFieldView(
                        text: Binding(
                            get: { draft.displayName },
                            set: { draft.displayName = $0 }
                        ),
                        placeholder: "Enter your name",
                        autocapitalization: .words,
                        monospaced: false
                    ) {
                        commitDisplayName()
                    }
                    .id("user-name-\(fieldRevision)")
                    .padding(14)
                    .background(Color.white.opacity(0.08), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .foregroundStyle(.white)
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Topics That Need Work")
                        .font(.headline)
                        .foregroundStyle(.white)

                    if store.topicWorkSummaries.isEmpty {
                        Text("No completed quizzes yet. Finish a run and this section will rank weak topics for you.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    } else {
                        ForEach(Array(store.topicWorkSummaries.prefix(8))) { summary in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(summary.label)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("\(Int((summary.accuracy * 100).rounded()))%")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(summary.accuracy >= 0.7 ? .green : summary.accuracy >= 0.5 ? .yellow : .red)
                                }
                                Text("Sessions: \(summary.sessions) • Correct: \(summary.correct) • Wrong: \(summary.wrong) • Skipped: \(summary.skipped) • Score: \(summary.score)")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .padding(14)
                            .glassInset()
                        }
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Trophy Room")
                        .font(.headline)
                        .foregroundStyle(.white)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 12)], spacing: 12) {
                        ForEach(store.trophyStates) { trophy in
                            TrophyTile(trophy: trophy)
                        }
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Quiz History")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Button(role: .destructive) {
                        showClearMemoryAlert = true
                    } label: {
                        Label("Delete history", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(SecondaryButtonStyle())

                    if store.recentHistory.isEmpty {
                        Text("No saved quiz history yet.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    } else {
                        ForEach(store.recentHistory) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(entry.timestamp.formatted(date: .abbreviated, time: .shortened))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    Spacer()
                                    Text("Score \(entry.score)")
                                        .font(.headline.monospacedDigit())
                                        .foregroundStyle(entry.score >= 0 ? .green : .red)
                                }

                                Text("Difficulty: \(entry.difficulty.capitalized) • Questions: \(entry.questionCount) • Timer: \(entry.timerMinutes == 0 ? "Untimed" : "\(entry.timerMinutes)m\(entry.intenseTimer == true ? " intense" : "")") • Elapsed: \(formattedElapsed(entry.elapsedSeconds, timed: entry.timerMinutes > 0))")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.72))

                                Text("Correct: \(entry.correct) • Wrong: \(entry.wrong) • Skipped: \(entry.skipped)")
                                    .font(.footnote)
                                    .foregroundStyle(.white.opacity(0.72))
                            }
                            .padding(14)
                            .glassInset()
                        }
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Recovery")
                        .font(.headline)
                        .foregroundStyle(.white)

                    Text("\(store.personalDeckCount) saved card\(store.personalDeckCount == 1 ? "" : "s"). Generated codes contain your saved profile state and can be used on another device or browser.")
                        .font(.footnote)
                        .foregroundStyle(.white.opacity(0.72))

                    ViewThatFits(in: .horizontal) {
                        HStack(spacing: 10) {
                            Button {
                                do {
                                    recoveryCodeOutput = try store.generateRecoveryCode()
                                    recoveryStatus = "Portable recovery code generated. It can be used on another device or browser."
                                } catch {
                                    recoveryStatus = error.localizedDescription
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Generate\ncode")
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(1)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button {
                                do {
                                    try store.restoreFromRecoveryCode(draft.recoveryCodeInput)
                                    recoveryCodeOutput = ""
                                    recoveryStatus = "Recovery code loaded. Personal deck, custom cards, custom learning topics, history, and saved setup have been restored."
                                    syncDraftFromStore()
                                } catch {
                                    recoveryStatus = error.localizedDescription
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Recover")
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(1)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }

                        VStack(spacing: 10) {
                            Button {
                                do {
                                    recoveryCodeOutput = try store.generateRecoveryCode()
                                    recoveryStatus = "Portable recovery code generated. It can be used on another device or browser."
                                } catch {
                                    recoveryStatus = error.localizedDescription
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "qrcode")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Generate\ncode")
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(1)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(SecondaryButtonStyle())

                            Button {
                                do {
                                    try store.restoreFromRecoveryCode(draft.recoveryCodeInput)
                                    recoveryCodeOutput = ""
                                    recoveryStatus = "Recovery code loaded. Personal deck, custom cards, custom learning topics, history, and saved setup have been restored."
                                    syncDraftFromStore()
                                } catch {
                                    recoveryStatus = error.localizedDescription
                                }
                            } label: {
                                VStack(spacing: 2) {
                                    Image(systemName: "arrow.clockwise.circle")
                                        .font(.system(size: 13, weight: .semibold))
                                    Text("Recover")
                                        .font(.system(size: 12, weight: .semibold))
                                        .multilineTextAlignment(.center)
                                        .lineSpacing(1)
                                        .lineLimit(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity, minHeight: 56)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Generated code")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(recoveryCodeOutput.isEmpty ? "No code generated yet." : recoveryCodeOutput)
                            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
                            .padding(14)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(recoveryCodeOutput.isEmpty ? .white.opacity(0.45) : .white)
                            .font(.system(.footnote, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Paste code to recover")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        BoundTextFieldView(
                            text: Binding(
                                get: { draft.recoveryCodeInput },
                                set: { draft.recoveryCodeInput = $0 }
                            ),
                            placeholder: "Paste code to recover",
                            autocapitalization: .none,
                            monospaced: true
                        )
                        .id("user-recovery-\(fieldRevision)")
                            .padding(14)
                            .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .foregroundStyle(.white)
                            .font(.system(.footnote, design: .monospaced))
                    }

                    if !recoveryStatus.isEmpty {
                        Text(recoveryStatus)
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(18)
                .glassCard()
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            syncDraftFromStore()
        }
        .onDisappear {
            commitDisplayName()
        }
        .alert("Delete all saved memory?", isPresented: $showClearMemoryAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                store.clearAllMemory()
                recoveryCodeOutput = ""
                recoveryStatus = ""
                syncDraftFromStore()
            }
        } message: {
            Text("This clears quiz history, saved settings, and performance memory.")
        }
    }

    private func commitDisplayName() {
        let currentStoreName = store.displayName == QuizStore.defaultDisplayName ? "" : store.displayName
        if draft.displayName != currentStoreName {
            store.updateDisplayName(draft.displayName)
            recoveryStatus = ""
        }
    }

    private func syncDraftFromStore() {
        draft.displayName = store.displayName == QuizStore.defaultDisplayName ? "" : store.displayName
        draft.recoveryCodeInput = ""
        fieldRevision &+= 1
    }
}

private final class CreateQuestionDraft {
    var editingTemplateId: String?
    var editingCreatedAt = Date()
    var promptTemplate = ""
    var hintTemplate = ""
    var solutionTemplate = ""
    var lowerExpression = ""
    var upperExpression = ""
    var variableSpecText = ""
}

private struct CreateQuestionView: View {
    let store: QuizStore
    @State private var draft = CreateQuestionDraft()
    @State private var selectedTopicId = ""
    @State private var randomized = false
    @State private var difficulty = "easy"
    @State private var inputMode = "number"
    @State private var previewQuestion: Question?
    @State private var statusMessage = ""
    @State private var errorMessage = ""
    @State private var showSavedTemplates = false

    private let difficultyChoices = ["easy", "medium", "hard"]
    private let inputModes: [(value: String, label: String)] = [
        ("number", "Number"),
        ("probability", "Probability"),
        ("percent", "Percent"),
        ("dollars", "Dollars"),
        ("count", "Count"),
        ("variance", "Variance"),
        ("correlation", "Correlation"),
        ("steps", "Steps"),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Question Creation")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    Text("Build your own cards, save them as custom templates, and optionally randomize them with variable ranges. In quiz setup, turn on \"Use custom cards\" to add them into the quiz pool.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.74))
                }
                .padding(20)
                .glassCard()

                VStack(alignment: .leading, spacing: 14) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(draft.editingTemplateId == nil ? "New custom card" : "Editing custom card")
                                .font(.headline.weight(.semibold))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: true)
                                .foregroundStyle(.white)
                            Spacer(minLength: 0)
                        }

                        HStack(spacing: 8) {
                            Button {
                                loadExampleTemplate()
                            } label: {
                                Text("Load example")
                                    .frame(width: 112)
                            }
                            .buttonStyle(OutlineButtonStyle())

                            Button {
                                resetForm()
                            } label: {
                                Text("Clear form")
                                    .frame(width: 112)
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    }

                    Picker("Topic", selection: $selectedTopicId) {
                        ForEach(store.topics) { topic in
                            Text(topic.label).tag(topic.id)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Question text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Use `{{x}}` to insert a variable. LaTeX-style snippets like `\\sqrt{n}`, `\\frac{a}{b}`, `\\lambda`, and `\\sigma` are rendered in the saved preview and quiz prompt.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                        BoundTextView(
                            text: Binding(
                                get: { draft.promptTemplate },
                                set: { draft.promptTemplate = $0 }
                            )
                        )
                            .frame(minHeight: 140)
                            .modifier(SoftEditorStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Hint text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Optional. This is what appears when you press Hint during quiz. You can also use `{{x}}` variables here.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                        BoundTextView(
                            text: Binding(
                                get: { draft.hintTemplate },
                                set: { draft.hintTemplate = $0 }
                            )
                        )
                            .frame(minHeight: 96)
                            .modifier(SoftEditorStyle())
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Solution text")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Optional. This is what appears in review for the previous card. You can also use `{{x}}` variables here.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                        BoundTextView(
                            text: Binding(
                                get: { draft.solutionTemplate },
                                set: { draft.solutionTemplate = $0 }
                            )
                        )
                            .frame(minHeight: 120)
                            .modifier(SoftEditorStyle())
                    }

                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Difficulty")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Picker("Difficulty", selection: $difficulty) {
                                ForEach(difficultyChoices, id: \.self) { choice in
                                    Text(choice.capitalized).tag(choice)
                                }
                            }
                            .pickerStyle(.segmented)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Answer format")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)
                            Picker("Answer format", selection: $inputMode) {
                                ForEach(inputModes, id: \.value) { mode in
                                    Text(mode.label).tag(mode.value)
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Accepted interval")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("Both endpoints are inclusive. For a single exact answer, make the lower and upper formulas the same.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                        BoundTextFieldView(
                            text: Binding(
                                get: { draft.lowerExpression },
                                set: { draft.lowerExpression = $0 }
                            ),
                            placeholder: "Lower endpoint formula",
                            autocapitalization: .none,
                            monospaced: true
                        )
                            .modifier(SoftFieldStyle())
                            .font(.system(.footnote, design: .monospaced))
                        BoundTextFieldView(
                            text: Binding(
                                get: { draft.upperExpression },
                                set: { draft.upperExpression = $0 }
                            ),
                            placeholder: "Upper endpoint formula",
                            autocapitalization: .none,
                            monospaced: true
                        )
                            .modifier(SoftFieldStyle())
                            .font(.system(.footnote, design: .monospaced))
                    }

                    QuietToggleRow(
                        title: "Randomize variables",
                        subtitle: "If on, the card samples fresh variable values each time it appears.",
                        isOn: $randomized
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Variable values")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text("One variable per line. Examples: `n = 10..50 step 5`, `k = 2..20 step 2 skip 8, 12`, `p = 0.2, 0.25, 0.3`. Variables are referenced in formulas by name.")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.68))
                        BoundTextView(
                            text: Binding(
                                get: { draft.variableSpecText },
                                set: { draft.variableSpecText = $0 }
                            )
                        )
                            .frame(minHeight: 120)
                            .modifier(SoftEditorStyle())
                            .font(.system(.footnote, design: .monospaced))
                    }

                    HStack(spacing: 10) {
                        Button {
                            previewCurrentTemplate(randomizedPreview: randomized)
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                    .font(.system(size: 13, weight: .semibold))
                                Text("Update\nsample")
                                    .font(.system(size: 12, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(1)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 62)
                        }
                        .buttonStyle(SecondaryButtonStyle())

                        Button {
                            saveCurrentTemplate()
                        } label: {
                            VStack(spacing: 2) {
                                Image(systemName: draft.editingTemplateId == nil ? "square.and.arrow.down" : "square.and.arrow.down.on.square")
                                    .font(.system(size: 13, weight: .semibold))
                                Text(draft.editingTemplateId == nil ? "Save\ncard" : "Update\ncard")
                                    .font(.system(size: 12, weight: .semibold))
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(1)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(maxWidth: .infinity, minHeight: 62)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                    }

                    if !statusMessage.isEmpty {
                        Text(statusMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.green)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.red)
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Preview")
                        .font(.headline)
                        .foregroundStyle(.white)
                    if let previewQuestion {
                        VStack(alignment: .leading, spacing: 10) {
                            Text(store.topicLabel(for: previewQuestion.topicId))
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.cyan)
                                .textCase(.uppercase)
                            Text(previewQuestion.prompt)
                                .foregroundStyle(.white)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(previewQuestion.explanation)
                                .font(.footnote)
                                .foregroundStyle(.white.opacity(0.78))
                        }
                        .padding(14)
                        .glassInset()
                    } else {
                        Text("Preview a sample to see the rendered prompt and the computed accepted interval.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(18)
                .glassCard()

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Saved custom cards")
                            .font(.headline)
                            .foregroundStyle(.white)
                        Spacer()
                        if !store.customTemplates.isEmpty {
                            Button(showSavedTemplates ? "Hide" : "Show") {
                                showSavedTemplates.toggle()
                            }
                            .buttonStyle(OutlineButtonStyle())
                        }
                    }

                    if store.customTemplates.isEmpty {
                        Text("No custom cards saved yet.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    } else if showSavedTemplates {
                        LazyVStack(spacing: 12) {
                            ForEach(store.customTemplates) { template in
                                VStack(alignment: .leading, spacing: 10) {
                                    Text(templatePromptSummary(template))
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .lineLimit(3)
                                    Text("\(store.topicLabel(for: template.topicId)) • \(template.difficulty.capitalized) • \(template.randomized ? "Randomized" : "Fixed") • \(inputModeLabel(template.inputMode))")
                                        .font(.footnote)
                                        .foregroundStyle(.white.opacity(0.68))
                                    HStack(spacing: 10) {
                                        Button("Edit") {
                                            loadTemplate(template)
                                        }
                                        .buttonStyle(OutlineButtonStyle())

                                        Button(role: .destructive) {
                                            if draft.editingTemplateId == template.id {
                                                resetForm()
                                            }
                                            store.deleteCustomTemplate(template.id)
                                            statusMessage = "Custom card deleted."
                                            errorMessage = ""
                                        } label: {
                                            Text("Delete")
                                        }
                                        .buttonStyle(OutlineButtonStyle())
                                    }
                                }
                                .frame(maxWidth: .infinity, minHeight: 142, alignment: .topLeading)
                                .padding(14)
                                .glassInset()
                            }
                        }
                    } else {
                        Text("\(store.customTemplateCount) custom card template\(store.customTemplateCount == 1 ? "" : "s") saved.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.72))
                    }
                }
                .padding(18)
                .glassCard()
            }
            .padding(16)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .onAppear {
            if selectedTopicId.isEmpty {
                selectedTopicId = store.topics.first?.id ?? ""
            }
        }
        .onChange(of: store.topics.count) { _, count in
            if count > 0 && selectedTopicId.isEmpty {
                selectedTopicId = store.topics.first?.id ?? ""
            }
        }
    }

    private func buildTemplate() -> CustomQuestionTemplate {
        CustomQuestionTemplate(
            id: draft.editingTemplateId ?? UUID().uuidString,
            createdAt: draft.editingTemplateId == nil ? Date() : draft.editingCreatedAt,
            topicId: selectedTopicId.isEmpty ? (store.topics.first?.id ?? "") : selectedTopicId,
            promptTemplate: draft.promptTemplate,
            hintTemplate: draft.hintTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.hintTemplate,
            solutionTemplate: draft.solutionTemplate.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : draft.solutionTemplate,
            lowerExpression: draft.lowerExpression,
            upperExpression: draft.upperExpression,
            variableSpecText: draft.variableSpecText,
            randomized: randomized,
            difficulty: difficulty,
            inputMode: inputMode
        )
    }

    private func previewCurrentTemplate(randomizedPreview: Bool) {
        errorMessage = ""
        statusMessage = ""
        do {
            previewQuestion = try store.previewCustomTemplate(buildTemplate(), randomizedPreview: randomizedPreview)
        } catch {
            previewQuestion = nil
            errorMessage = error.localizedDescription
        }
    }

    private func saveCurrentTemplate() {
        errorMessage = ""
        statusMessage = ""
        do {
            let wasEditing = draft.editingTemplateId != nil
            let template = buildTemplate()
            try store.upsertCustomTemplate(template)
            draft.editingTemplateId = template.id
            draft.editingCreatedAt = template.createdAt
            previewQuestion = try store.previewCustomTemplate(template, randomizedPreview: template.randomized)
            statusMessage = wasEditing ? "Custom card updated." : "Custom card saved."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func loadTemplate(_ template: CustomQuestionTemplate) {
        draft.editingTemplateId = template.id
        draft.editingCreatedAt = template.createdAt
        selectedTopicId = template.topicId
        draft.promptTemplate = template.promptTemplate
        draft.hintTemplate = template.hintTemplate ?? ""
        draft.solutionTemplate = template.solutionTemplate ?? ""
        draft.lowerExpression = template.lowerExpression
        draft.upperExpression = template.upperExpression
        draft.variableSpecText = template.variableSpecText
        randomized = template.randomized
        difficulty = template.difficulty
        inputMode = template.inputMode
        errorMessage = ""
        statusMessage = ""
        previewQuestion = try? store.previewCustomTemplate(template, randomizedPreview: false)
    }

    private func resetForm() {
        draft.editingTemplateId = nil
        draft.editingCreatedAt = Date()
        selectedTopicId = store.topics.first?.id ?? ""
        draft.promptTemplate = ""
        draft.hintTemplate = ""
        draft.solutionTemplate = ""
        draft.lowerExpression = ""
        draft.upperExpression = ""
        draft.variableSpecText = ""
        randomized = false
        difficulty = "easy"
        inputMode = "number"
        previewQuestion = nil
        statusMessage = ""
        errorMessage = ""
    }

    private func loadExampleTemplate() {
        let fallbackTopicId = store.topics.first?.id ?? ""
        let exampleTopicId = store.topics.contains(where: { $0.id == "miscCustom" }) ? "miscCustom" : fallbackTopicId
        let example = CustomQuestionTemplate(
            id: UUID().uuidString,
            createdAt: Date(),
            topicId: exampleTopicId,
            promptTemplate: "What is {{n}}^2 + {{k}}?",
            hintTemplate: "Substitute the sampled values into n^2 + k. For example, if n = 15 and k = 7, compute 15^2 + 7.",
            solutionTemplate: "For this generated version, first square {{n}} to get {{n}}^2. Then add {{k}}. That gives the final answer.",
            lowerExpression: "n^2 + k",
            upperExpression: "n^2 + k",
            variableSpecText: "n = 10..20 step 5\nk = 1, 3, 7",
            randomized: true,
            difficulty: "easy",
            inputMode: "number"
        )
        loadTemplate(example)
        statusMessage = "Example template loaded."
    }

    private func templatePromptSummary(_ template: CustomQuestionTemplate) -> String {
        renderTemplateSummaryText(template.promptTemplate)
    }

    private func inputModeLabel(_ value: String) -> String {
        inputModes.first(where: { $0.value == value })?.label ?? value.capitalized
    }
}

private func renderTemplateSummaryText(_ text: String) -> String {
    var output = text
    if let regex = try? NSRegularExpression(pattern: #"\{\{\s*([A-Za-z][A-Za-z0-9_]*)\s*\}\}"#) {
        let range = NSRange(output.startIndex..., in: output)
        output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: "[$1]")
    }
    let replacements = [
        "\\lambda": "λ",
        "\\sigma": "σ",
        "\\mu": "μ",
        "\\theta": "θ",
        "\\alpha": "α",
        "\\beta": "β",
        "\\gamma": "γ",
        "\\rho": "ρ",
        "\\tau": "τ",
        "\\pi": "π",
        "\\cdot": "·",
        "\\times": "×",
    ]
    for (from, to) in replacements {
        output = output.replacingOccurrences(of: from, with: to)
    }
    output = output.replacingOccurrences(of: "$", with: "")
    output = output.replacingOccurrences(of: "\\left", with: "")
    output = output.replacingOccurrences(of: "\\right", with: "")
    output = output.replacingOccurrences(of: "{", with: "(")
    output = output.replacingOccurrences(of: "}", with: ")")
    return output
}

private struct SoftEditorStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.white)
    }
}

private struct BoundTextView: UIViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .white
        view.font = UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
        view.autocorrectionType = .no
        view.autocapitalizationType = .none
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.smartInsertDeleteType = .no
        view.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        view.textContainer.lineFragmentPadding = 0
        view.keyboardAppearance = .dark
        view.returnKeyType = .default
        view.keyboardDismissMode = .interactive
        view.isScrollEnabled = true
        view.showsVerticalScrollIndicator = true
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        ]
        view.inputAccessoryView = toolbar
        view.text = text
        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        @Binding var text: String

        init(text: Binding<String>) {
            _text = text
        }

        func textViewDidChange(_ textView: UITextView) {
            let updated = textView.text ?? ""
            if updated != text {
                text = updated
            }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            let updated = textView.text ?? ""
            if updated != text {
                text = updated
            }
        }

        @objc func dismissKeyboard() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

private struct BoundTextFieldView: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var autocapitalization: UITextAutocapitalizationType = .none
    var monospaced = false
    var onSubmit: (() -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text, onSubmit: onSubmit)
    }

    func makeUIView(context: Context) -> UITextField {
        let view = UITextField()
        view.delegate = context.coordinator
        view.borderStyle = .none
        view.backgroundColor = .clear
        view.textColor = .white
        view.tintColor = UIColor(red: 0.17, green: 0.79, blue: 0.92, alpha: 1)
        view.autocorrectionType = .no
        view.autocapitalizationType = autocapitalization
        view.smartQuotesType = .no
        view.smartDashesType = .no
        view.clearButtonMode = .never
        view.returnKeyType = .done
        view.enablesReturnKeyAutomatically = false
        view.keyboardAppearance = .dark
        view.adjustsFontSizeToFitWidth = false
        view.placeholder = placeholder
        view.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [.foregroundColor: UIColor.white.withAlphaComponent(0.42)]
        )
        view.font = monospaced
            ? UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)
            : UIFont.systemFont(ofSize: 17, weight: .regular)
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.items = [
            UIBarButtonItem.flexibleSpace(),
            UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.dismissKeyboard))
        ]
        view.inputAccessoryView = toolbar
        view.addTarget(context.coordinator, action: #selector(Coordinator.editingChanged(_:)), for: .editingChanged)
        view.text = text
        return view
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        if uiView.text != text {
            uiView.text = text
        }
    }

    final class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        let onSubmit: (() -> Void)?

        init(text: Binding<String>, onSubmit: (() -> Void)?) {
            _text = text
            self.onSubmit = onSubmit
        }

        @objc func editingChanged(_ sender: UITextField) {
            let updated = sender.text ?? ""
            if updated != text {
                text = updated
            }
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            let updated = textField.text ?? ""
            if updated != text {
                text = updated
            }
            onSubmit?()
            textField.resignFirstResponder()
            return true
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            let updated = textField.text ?? ""
            if updated != text {
                text = updated
            }
            onSubmit?()
        }

        @objc func dismissKeyboard() {
            onSubmit?()
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
}

private struct SoftFieldStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .foregroundStyle(.white)
    }
}

private struct QuietToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(.white.opacity(0.65))
            }
            Spacer(minLength: 12)
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                .fixedSize()
        }
    }
}

private struct TrophyTile: View {
    let trophy: TrophyState

    var body: some View {
        let badgeSize: CGFloat = 54
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .center, spacing: 6) {
                if trophy.hasStarRing && trophy.isUnlocked {
                    Text("✦ ✦ ✦")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color(red: 1.0, green: 0.92, blue: 0.62))
                        .tracking(1.2)
                        .frame(width: max(72, badgeSize + 18), alignment: .center)
                }
                ZStack {
                    Circle()
                        .fill(
                            trophy.isUnlocked
                            ? LinearGradient(colors: [Color(red: 1.0, green: 0.92, blue: 0.58), Color(red: 0.93, green: 0.70, blue: 0.24)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.14), Color.white.opacity(0.08)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: badgeSize, height: badgeSize)
                        .overlay(
                            Circle().stroke(trophy.isUnlocked ? Color(red: 0.95, green: 0.79, blue: 0.31) : Color.white.opacity(0.16), lineWidth: 1)
                        )
                    if trophy.icon.hasPrefix("sf:") {
                        Image(systemName: String(trophy.icon.dropFirst(3)))
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(trophy.isUnlocked ? Color(red: 0.44, green: 0.29, blue: 0.0) : Color.white.opacity(0.45))
                    } else {
                        Text(trophy.icon)
                            .font(.system(size: trophy.id == "imperial-crown" ? 34 : 28))
                            .foregroundStyle(trophy.isUnlocked ? Color(red: 0.44, green: 0.29, blue: 0.0) : Color.white.opacity(0.45))
                    }
                }
                .frame(width: badgeSize, height: badgeSize)
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .saturation(trophy.isUnlocked ? 1 : 0)
            .opacity(trophy.isUnlocked ? 1 : 0.65)

            Text(trophy.title)
                .font(.headline)
                .foregroundStyle(trophy.isUnlocked ? .white : .white.opacity(0.82))

            Text(trophy.detail)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))

            Text(trophy.isUnlocked ? "Unlocked" : "Locked")
                .font(.caption.weight(.semibold))
                .foregroundStyle(trophy.isUnlocked ? Color(red: 0.54, green: 0.89, blue: 0.57) : .white.opacity(0.5))
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 224, maxHeight: 224, alignment: .topLeading)
        .glassInset()
    }
}

private func formattedElapsed(_ seconds: Int, timed: Bool) -> String {
    guard timed else { return "n/a" }
    let minutes = seconds / 60
    let remainder = seconds % 60
    return String(format: "%02d:%02d", minutes, remainder)
}

private func niceTickStep(_ roughStep: Double) -> Double {
    let safe = max(roughStep, 0.1)
    let magnitude = pow(10.0, floor(log10(safe)))
    let normalized = safe / magnitude
    if normalized <= 1 { return magnitude }
    if normalized <= 2 { return 2 * magnitude }
    if normalized <= 5 { return 5 * magnitude }
    return 10 * magnitude
}

private func formatChartValue(_ value: Double, suffix: String?) -> String {
    let text = formatNumber(value, decimals: abs(value) < 10 ? 1 : 0)
    return "\(text)\(suffix ?? "")"
}

private struct KeypadView: View {
    let compact: Bool
    let insert: (String) -> Void
    let backspace: () -> Void
    let clear: () -> Void

    private let grid = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        [".", "0", "/"]
    ]

    var body: some View {
        VStack(spacing: compact ? 7 : 10) {
            ForEach(grid, id: \.self) { row in
                HStack(spacing: compact ? 7 : 10) {
                    ForEach(row, id: \.self) { token in
                        Button {
                            insert(token)
                        } label: {
                            Text(token)
                                .font(.system(size: compact ? 17 : 20, weight: .semibold, design: .rounded))
                                .frame(maxWidth: .infinity, minHeight: compact ? 34 : 46)
                        }
                        .buttonStyle(QuizOutlineButtonStyle(compact: compact))
                    }
                }
            }

            HStack(spacing: compact ? 7 : 10) {
                Button {
                    insert("-")
                } label: {
                    Text("-")
                        .font(.system(size: compact ? 17 : 20, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity, minHeight: compact ? 34 : 46)
                }
                .buttonStyle(QuizOutlineButtonStyle(compact: compact))

                Button(action: backspace) {
                    Image(systemName: "delete.left")
                        .font(.system(size: compact ? 16 : 18, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: compact ? 34 : 46)
                }
                .buttonStyle(QuizOutlineButtonStyle(compact: compact))

                Button(action: clear) {
                    Text("Clear")
                        .font(.system(size: compact ? 14 : 16, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: compact ? 34 : 46)
                }
                .buttonStyle(QuizOutlineButtonStyle(compact: compact))
            }
        }
    }
}

private struct QuestionVisualView: View {
    let visual: QuestionVisual
    let compact: Bool

    var body: some View {
        if visual.type == "pnlChart", let points = visual.points, points.count >= 2 {
            AnyView(
                VStack(alignment: .leading, spacing: compact ? 8 : 10) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(displayTitle)
                            .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                            .foregroundStyle(Color(red: 0.08, green: 0.12, blue: 0.2))
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 8)
                    }

                    if let note = visual.note, !note.isEmpty {
                        Text(note)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    PnLChartView(visual: visual, compact: compact)
                        .frame(height: compact ? 130 : 165)

                    HStack {
                        Text(visual.xLabel ?? "")
                        Spacer()
                        Text(visual.yLabel ?? "")
                    }
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.62))
                }
                .padding(compact ? 10 : 12)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: compact ? 14 : 18, style: .continuous)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
            )
        } else {
            AnyView(EmptyView())
        }
    }

    private var displayTitle: String {
        switch (visual.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "cumulative monthly pnl (% of capital)":
            return "Cumulative monthly PnL %"
        case "cumulative weekly pnl (% of capital)":
            return "Cumulative weekly PnL %"
        case "cumulative annual pnl (% of capital)":
            return "Cumulative annual PnL %"
        default:
            return visual.title ?? "Cumulative PnL"
        }
    }
}

private struct PnLChartView: View {
    let visual: QuestionVisual
    let compact: Bool

    var body: some View {
        GeometryReader { proxy in
            chartBody(size: proxy.size)
        }
    }

    private func chartBody(size: CGSize) -> some View {
        let values = visual.points ?? []
        let labels = visual.labels ?? values.indices.map(String.init)
        let showPointValues = visual.showPointValues ?? true
        let showMarkers = visual.showMarkers ?? true
        let showVerticalGrid = visual.showVerticalGrid ?? false
        let rawMin = min(values.min() ?? 0, 0)
        let rawMax = max(values.max() ?? 0, 0)
        let span = max(2.0, rawMax - rawMin)
        let pad = max(1.0, ceil(span * 0.18))
        let roughStep = (span + (2 * pad)) / 4
        let tickStep = niceTickStep(roughStep)
        let yMin = floor((rawMin - pad) / tickStep) * tickStep
        let yMax = ceil((rawMax + pad) / tickStep) * tickStep
        let height = size.height
        let width = size.width
        let left: CGFloat = compact ? 26 : 30
        let right: CGFloat = compact ? 10 : 12
        let top: CGFloat = compact ? 12 : 14
        let bottom: CGFloat = compact ? 26 : 30
        let plotWidth = max(1, width - left - right)
        let plotHeight = max(1, height - top - bottom)
        let xStep = plotWidth / CGFloat(max(values.count - 1, 1))
        let yScale = yMax > yMin ? (plotHeight / CGFloat(yMax - yMin)) : 0
        let neutralY = top + (plotHeight / 2)
        let ticks = stride(from: yMin, through: yMax + 0.0001, by: tickStep).map { $0 }

        func x(_ index: Int) -> CGFloat {
            left + (CGFloat(index) * xStep)
        }

        func y(_ value: Double) -> CGFloat {
            yMax > yMin ? top + CGFloat(yMax - value) * yScale : neutralY
        }

        return ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: compact ? 10 : 12, style: .continuous)
                .fill(Color.white.opacity(0.96))

            if showVerticalGrid {
                Path { path in
                    for index in values.indices {
                        let xPos = x(index)
                        path.move(to: CGPoint(x: xPos, y: top))
                        path.addLine(to: CGPoint(x: xPos, y: top + plotHeight))
                    }
                }
                .stroke(Color.black.opacity(0.08), lineWidth: 0.8)
            }

            Path { path in
                for tick in ticks {
                    let yPos = y(tick)
                    path.move(to: CGPoint(x: left, y: yPos))
                    path.addLine(to: CGPoint(x: left + plotWidth, y: yPos))
                }
            }
            .stroke(Color.black.opacity(0.12), lineWidth: 1)

            Path { path in
                path.move(to: CGPoint(x: left, y: top))
                path.addLine(to: CGPoint(x: left, y: top + plotHeight))
                path.addLine(to: CGPoint(x: left + plotWidth, y: top + plotHeight))
            }
            .stroke(Color.black, lineWidth: 1.2)

            Path { path in
                if let first = values.first {
                    path.move(to: CGPoint(x: x(0), y: y(first)))
                    for (index, value) in values.enumerated().dropFirst() {
                        path.addLine(to: CGPoint(x: x(index), y: y(value)))
                    }
                }
            }
            .stroke(Color(red: 0.06, green: 0.52, blue: 0.82), style: StrokeStyle(lineWidth: compact ? 2 : 2.6, lineCap: .round, lineJoin: .round))

            ForEach(Array(values.enumerated()), id: \.offset) { index, value in
                let xPos = x(index)
                let yPos = y(value)
                if showMarkers {
                    Circle()
                        .fill(Color(red: 0.78, green: 0.2, blue: 0.2))
                        .frame(width: compact ? 6 : 8, height: compact ? 6 : 8)
                        .overlay(Circle().stroke(.white, lineWidth: 1))
                        .position(x: xPos, y: yPos)
                }

                if showPointValues {
                    Text("\(formatChartValue(value, suffix: visual.unitSuffix))")
                        .font(.system(size: compact ? 8 : 9, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                        .position(x: xPos, y: yPos < top + 18 ? yPos + 12 : yPos - 10)
                }
            }

            ForEach(Array(labels.enumerated()), id: \.offset) { index, label in
                if !label.isEmpty {
                    Text(label)
                        .font(.system(size: compact ? 8 : 9))
                        .foregroundStyle(Color.black.opacity(0.65))
                        .position(x: x(index), y: top + plotHeight + (compact ? 12 : 14))
                }
            }

            ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
                Text(formatChartValue(tick, suffix: visual.unitSuffix))
                    .font(.system(size: compact ? 8 : 9))
                    .foregroundStyle(Color.black.opacity(0.65))
                    .position(x: compact ? 12 : 14, y: y(tick))
            }
        }
    }
}

private struct ReviewSheetView: View {
    @ObservedObject var store: QuizStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(store.reviewResultsNewestFirst) { result in
                    ReviewCard(result: result, allowSolution: !result.revisitPending)
                }
            }
            .padding(16)
        }
        .navigationTitle("Submitted Cards")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { store.reviewSheetOpen = false }
            }
        }
    }
}

private struct HintSheetView: View {
    let hint: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(hint)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
        }
        .background(Color(red: 0.05, green: 0.08, blue: 0.12).ignoresSafeArea())
        .navigationTitle("Hint")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }
}

private struct GraphSheetView: View {
    let visual: QuestionVisual
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                QuestionVisualView(visual: visual, compact: false)
            }
            .padding(16)
        }
        .background(Color(red: 0.05, green: 0.08, blue: 0.12).ignoresSafeArea())
        .navigationTitle(displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
            }
        }
    }

    private var displayTitle: String {
        switch (visual.title ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "cumulative monthly pnl (% of capital)":
            return "Cumulative monthly PnL %"
        case "cumulative weekly pnl (% of capital)":
            return "Cumulative weekly PnL %"
        case "cumulative annual pnl (% of capital)":
            return "Cumulative annual PnL %"
        default:
            return visual.title ?? "Graph"
        }
    }
}

private struct ReviewCard: View {
    let result: SessionResult
    var allowSolution = true
    @State private var expanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Card \(result.cardNumber)")
                    .font(.headline)
                    .foregroundStyle(.white)
                Spacer()
                Text(result.status.label)
                    .font(.caption.weight(.bold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(result.status.color.opacity(0.18), in: Capsule())
                    .foregroundStyle(result.status.color)
            }

            Text(result.question.category)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.cyan)
            Text(result.question.prompt)
                .foregroundStyle(.white.opacity(0.92))
            if let visual = result.question.visual {
                QuestionVisualView(visual: visual, compact: false)
            }
            Text("Your answer: \(result.userAnswerSummary)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
            if result.timedOut {
                Text("Session note: Time expired on this card, so it was marked wrong and the deck advanced automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.8))
            }
            Text("Accepted range: \(result.acceptedRange)")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))

            if allowSolution {
                Button(expanded ? "Hide worked solution" : "Expand worked solution") {
                    expanded.toggle()
                }
                .buttonStyle(OutlineButtonStyle())
            } else {
                Text("Worked solution stays hidden until this skipped card is resolved or the quiz is ended.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.78))
                    .padding(12)
                    .glassInset()
            }

            if expanded && allowSolution {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Exact answer: \(result.exactAnswer)")
                    if result.mentalAnswer != result.exactAnswer {
                        Text("Shortcut answer: \(result.mentalAnswer)")
                    }
                    ExplanationSectionView(title: "Worked solution", text: readableWorkedSolution(for: result.question))
                    if let methodExplanation = result.question.methodExplanation, !methodExplanation.isEmpty {
                        ExplanationSectionView(title: "Why the method works", text: methodExplanation)
                    }
                    if let source = result.question.source, !source.isEmpty {
                        Text("Source: \(source)")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.84))
                .padding(14)
                .glassInset()
            }
        }
        .padding(16)
        .glassCard()
    }
}

private struct ExplanationSectionView: View {
    let title: String
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
            Text(text)
                .foregroundStyle(.white.opacity(0.84))
        }
    }
}

private struct FlexibleTagGrid: View {
    let items: [Topic]
    let selected: Set<String>
    let tap: (Topic) -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)], spacing: 8) {
            ForEach(items) { topic in
                Button {
                    tap(topic)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(topic.label)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(2)
                            Spacer(minLength: 8)
                            Image(systemName: selected.contains(topic.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(selected.contains(topic.id) ? .cyan : .white.opacity(0.5))
                        }
                        Text(topic.meta)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(.white.opacity(0.62))
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(minHeight: 72, alignment: .topLeading)
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected.contains(topic.id) ? Color.cyan.opacity(0.16) : Color.white.opacity(0.05))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected.contains(topic.id) ? Color.cyan.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct ConfigStepperRow: View {
    let title: String
    let subtitle: String
    let valueText: String
    let decrementDisabled: Bool
    let incrementDisabled: Bool
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            Text(subtitle)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
            HStack {
                Button(action: decrement) {
                    Image(systemName: "minus")
                }
                .buttonStyle(OutlineButtonStyle())
                .disabled(decrementDisabled)

                Spacer()
                Text(valueText)
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(.white)
                Spacer()

                Button(action: increment) {
                    Image(systemName: "plus")
                }
                .buttonStyle(OutlineButtonStyle())
                .disabled(incrementDisabled)
            }
        }
    }
}

private struct SessionMetric: View {
    let title: String
    let value: String
    let compact: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font((compact ? Font.caption2 : Font.caption).weight(.semibold))
                .foregroundStyle(.white.opacity(0.62))
            Text(value)
                .font((compact ? Font.subheadline : Font.headline).monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(compact ? 10 : 14)
        .glassCard()
    }
}

private struct ResultCapsule: View {
    let status: ResultStatus?
    let compact: Bool
    let showLabel: Bool

    var body: some View {
        let display = status ?? .neutral
        HStack(spacing: 8) {
            Circle()
                .fill(display.color)
                .frame(width: compact ? 7 : 8, height: compact ? 7 : 8)
            if showLabel {
                Text(capsuleLabel(for: display))
                    .font((compact ? Font.caption : Font.subheadline).weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .truncationMode(.tail)
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, compact ? 10 : 12)
        .padding(.vertical, compact ? 8 : 10)
        .background(display.color.opacity(0.18), in: Capsule())
    }

    private func capsuleLabel(for status: ResultStatus) -> String {
        switch status {
        case .neutral:
            return "No answer"
        case .correct:
            return "Correct"
        case .wrong:
            return "Wrong"
        case .skipped:
            return "Skipped"
        }
    }
}

private struct MiniMetric: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.white)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .glassInset()
    }
}

private struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.12, green: 0.74, blue: 0.91),
                                Color(red: 0.09, green: 0.46, blue: 0.83),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08)))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .padding(.vertical, 10)
            .padding(.horizontal, 14)
            .foregroundStyle(.white)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06)))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

private struct QuizOutlineButtonStyle: ButtonStyle {
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.white)
            .background(
                RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
                    .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: compact ? 12 : 14, style: .continuous)
                    .stroke(Color.white.opacity(0.14), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private struct QuizActionButtonStyle: ButtonStyle {
    let primary: Bool
    let compact: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font((compact ? Font.subheadline : Font.headline).weight(.semibold))
            .foregroundStyle(.white)
            .background(
                AnyView(
                    Group {
                        if primary {
                            RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.12, green: 0.74, blue: 0.91),
                                            Color(red: 0.09, green: 0.46, blue: 0.83),
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        } else {
                            RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous)
                                .fill(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08))
                        }
                    }
                )
            )
            .overlay(
                AnyView(
                    Group {
                        if primary {
                            EmptyView()
                        } else {
                            RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        }
                    }
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: compact ? 16 : 18, style: .continuous))
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
    }
}

private extension View {
    func glassCard() -> some View {
        background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 26, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    func glassInset() -> some View {
        background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
    }
}

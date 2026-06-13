import Foundation
import SwiftUI
import WebKit

struct Topic: Codable, Identifiable, Hashable {
    let id: String
    let label: String
    let description: String
    let meta: String
}

struct QuestionVisual: Codable, Hashable {
    let type: String
    let title: String?
    let note: String?
    let xLabel: String?
    let yLabel: String?
    let labels: [String]?
    let points: [Double]?
    let unitSuffix: String?
    let showPointValues: Bool?
    let showMarkers: Bool?
    let showVerticalGrid: Bool?
}

struct Question: Codable, Hashable {
    let topicId: String
    let category: String
    let prompt: String
    let hint: String
    let inputMode: String
    let formatHint: String
    let answer: Double
    let mentalAnswer: Double
    let absTolerance: Double
    let relTolerance: Double
    let explanation: String
    let workedSolution: String?
    let methodExplanation: String?
    let difficulty: String
    let source: String?
    let visual: QuestionVisual?
    var problemKey: String? = nil
    var runtimeFamily: String? = nil
    var acceptedLower: Double? = nil
    var acceptedUpper: Double? = nil
    var customTemplateId: String? = nil
}

struct CustomQuestionTemplate: Codable, Identifiable, Hashable {
    let id: String
    let createdAt: Date
    let topicId: String
    let promptTemplate: String
    let hintTemplate: String?
    let solutionTemplate: String?
    let lowerExpression: String
    let upperExpression: String
    let variableSpecText: String
    let randomized: Bool
    let difficulty: String
    let inputMode: String
}

struct CustomLearningTopic: Codable, Identifiable, Hashable {
    let id: String
    let createdAt: Date
    let title: String
    let body: String
}

struct AppDataPayload: Codable {
    let topics: [Topic]
    let questionBank: [String: [Question]]
}

private struct RawQuestion: Codable {
    let topicId: String?
    let category: String?
    let prompt: String?
    let hint: String?
    let inputMode: String?
    let formatHint: String?
    let answer: Double?
    let mentalAnswer: Double?
    let absTolerance: Double?
    let relTolerance: Double?
    let explanation: String?
    let workedSolution: String?
    let methodExplanation: String?
    let difficulty: String?
    let source: String?
    let visual: QuestionVisual?

    func normalized() -> Question? {
        guard
            let topicId,
            let category,
            let prompt,
            let hint,
            let inputMode,
            let formatHint,
            let answer,
            let mentalAnswer,
            let absTolerance,
            let relTolerance,
            let explanation,
            let difficulty
        else {
            return nil
        }

        return Question(
            topicId: topicId,
            category: category,
            prompt: prompt,
            hint: hint,
            inputMode: inputMode,
            formatHint: formatHint,
            answer: answer,
            mentalAnswer: mentalAnswer,
            absTolerance: absTolerance,
            relTolerance: relTolerance,
            explanation: explanation,
            workedSolution: workedSolution,
            methodExplanation: methodExplanation,
            difficulty: difficulty,
            source: source,
            visual: visual
        )
    }
}

private struct RawAppDataPayload: Codable {
    let topics: [Topic]
    let questionBank: [String: [RawQuestion]]
}

enum DifficultyFilter: String, CaseIterable, Identifiable {
    case all
    case easy
    case medium
    case hard
    case freddybean

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All Mix"
        case .easy: return "Easy"
        case .medium: return "Medium"
        case .hard: return "Hard"
        case .freddybean: return "Freddybean"
        }
    }
}

enum QuizPhase {
    case setup
    case session
    case results
}

enum ResultStatus: String, Codable, Equatable {
    case correct
    case wrong
    case skipped
    case neutral

    var label: String {
        switch self {
        case .correct: return "Correct"
        case .wrong: return "Wrong"
        case .skipped: return "Skipped"
        case .neutral: return "Neutral"
        }
    }

    var color: Color {
        switch self {
        case .correct: return .green
        case .wrong: return .red
        case .skipped: return .gray
        case .neutral: return .cyan
        }
    }
}

struct DeckEntry: Identifiable {
    let id: String
    let originalCardNumber: Int
    let question: Question
    var revisitCount: Int
    var canScheduleRevisit: Bool
}

struct SessionResult: Identifiable {
    let id: String
    let cardNumber: Int
    let question: Question
    let rawInput: String
    let parsedAnswer: Double?
    let status: ResultStatus
    let score: Int
    let revisitPending: Bool
    let timedOut: Bool
    let attempts: Int
    let everSkipped: Bool
    let updatedSequence: Int

    var userAnswerSummary: String {
        if timedOut {
            if rawInput.isEmpty {
                return "Timed out"
            }
            return "Timed out (had: \(rawInput))"
        }
        guard let parsedAnswer else { return "Skipped" }
        if question.inputMode == "probability" {
            return "\(rawInput) -> \(formatNumber(parsedAnswer, decimals: 4))"
        }
        if question.inputMode == "percent" {
            return rawInput
        }
        return rawInput
    }

    var exactAnswer: String { formatSingleAnswer(question: question, value: question.answer) }
    var mentalAnswer: String { formatSingleAnswer(question: question, value: question.mentalAnswer) }
    var acceptedRange: String { acceptedRangeString(question: question) }
}

struct TopicSessionStat: Codable, Identifiable {
    let id: String
    let correct: Int
    let wrong: Int
    let skipped: Int
    let score: Int
}

struct QuizHistoryEntry: Codable, Identifiable {
    let id: String
    let timestamp: Date
    let selectedTopicIds: [String]
    let difficulty: String
    let questionCount: Int
    let timerMinutes: Int
    let intenseTimer: Bool?
    let showHints: Bool?
    let personalDeckOnly: Bool?
    let customCardsOnly: Bool?
    let elapsedSeconds: Int
    let score: Int
    let correct: Int
    let wrong: Int
    let skipped: Int
    let topicStats: [TopicSessionStat]
}

private struct RecoveryPreferencesPayload: Codable {
    let questionCount: Int
    let timerMinutes: Double
    let difficulty: String
    let showHints: Bool
    let intenseTimer: Bool
    let personalDeckOnly: Bool
    let customCardsOnly: Bool?
    let selectedTopics: [String]
    let bestScore: Int?
}

private struct RecoveryHistoryEntryPayload: Codable {
    let id: String
    let timestamp: String
    let selectedTopicIds: [String]
    let difficulty: String
    let questionCount: Int
    let timerMinutes: Double
    let intenseTimer: Bool?
    let showHints: Bool?
    let personalDeckOnly: Bool?
    let customCardsOnly: Bool?
    let elapsedSeconds: Int
    let score: Int
    let correct: Int
    let wrong: Int
    let skipped: Int
    let topicStats: [TopicSessionStat]
}

private struct RecoveryPayload: Codable {
    let version: Int
    let displayName: String?
    let preferences: RecoveryPreferencesPayload
    let history: [RecoveryHistoryEntryPayload]
    let personalDeck: [Question]
    let customTemplates: [CustomQuestionTemplate]?
    let customLearningTopics: [CustomLearningTopic]?
    let exportedAt: String
}

struct TopicWorkSummary: Identifiable {
    let id: String
    let label: String
    let sessions: Int
    let correct: Int
    let wrong: Int
    let skipped: Int
    let score: Int

    var attempted: Int { correct + wrong + skipped }
    var accuracy: Double {
        let denom = correct + wrong
        guard denom > 0 else { return 0 }
        return Double(correct) / Double(denom)
    }
}

struct TrophyState: Identifiable {
    let id: String
    let icon: String
    let title: String
    let detail: String
    let isUnlocked: Bool
    let hasStarRing: Bool
}

final class QuizStore: ObservableObject {
    static let defaultDisplayName = "Player"
    static let recoveryCodePrefix = "SD1."
    static let shortRecoveryCodePrefix = "SD"
    static let shortRecoveryCodeLength = 16
    static let shortRecoveryAlphabet = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
    private static var cachedTopics: [Topic]?
    private static var cachedQuestionBank: [String: [Question]]?
    private static var cachedQuestionLookupByProblemKey: [String: Question]?

    @Published var phase: QuizPhase = .setup
    @Published var topics: [Topic] = []
    @Published private(set) var dataReady = false
    @Published private(set) var historyReady = false
    @Published private(set) var localDataReady = false
    @Published var selectedTopicIds: Set<String> = []
    @Published var difficulty: DifficultyFilter = .all
    @Published var questionCount: Int = 20
    @Published var timerMinutes: Int = 0
    @Published var showHints = false
    @Published var intenseTimer = false
    @Published var personalDeckOnly = false
    @Published var customCardsOnly = false
    @Published var liveGenerationEnabled = true
    @Published var displayName = QuizStore.defaultDisplayName
    @Published var freddybeanUnlocked = false
    @Published var secretStatusMessage: String?
    @Published var setupError: String?
    @Published var inputError: String?
    @Published var answerText = ""
    @Published var reviewSheetOpen = false
    @Published var liveScore = 0
    @Published var timerLabel = "Untimed"
    @Published var progressLabel = "0 / 0"
    @Published var lastResultStatus: ResultStatus?
    @Published private(set) var history: [QuizHistoryEntry] = []
    @Published private(set) var personalDeck: [Question] = []
    @Published private(set) var customTemplates: [CustomQuestionTemplate] = []
    @Published private(set) var customLearningTopics: [CustomLearningTopic] = []

    private let preferencesKey = "SignalDeckNativePreferences"
    private let historyKey = "SignalDeckNativeHistory"
    private let recoverySnapshotsKey = "SignalDeckNativeRecoverySnapshots"
    private let personalDeckDataKey = "SignalDeckNativePersonalDeckData"
    private let customTemplatesDataKey = "SignalDeckNativeCustomTemplatesData"
    private let customLearningTopicsDataKey = "SignalDeckNativeCustomLearningTopicsData"
    private var timer: Timer?
    private var secretStatusWorkItem: DispatchWorkItem?
    private var difficultySecretWorkItem: DispatchWorkItem?
    private var difficultySecretTapCount = 0
    private var timerSeconds = 0
    private var remainingSeconds = 0
    private var elapsedSeconds = 0
    private var perQuestionBaseSeconds = 0
    private var perQuestionBonusQuestions = 0
    private var updateSequence = 0
    private var baseDeck: [DeckEntry] = []
    private var deck: [DeckEntry] = []
    private var currentIndex = 0
    private var questionBank: [String: [Question]] = [:]
    private var questionLookupByProblemKey: [String: Question] = [:]
    private var historyLoadVersion = 0
    private var localDataLoadVersion = 0
    private var deferredDataLoadStarted = false

    @Published private(set) var results: [SessionResult] = []
    private var lastCompletedSetup: (selectedTopicIds: Set<String>, difficulty: DifficultyFilter, questionCount: Int, timerMinutes: Int, showHints: Bool, intenseTimer: Bool, personalDeckOnly: Bool, customCardsOnly: Bool)?

    init() {
        loadPreferences()
        loadDataAsync()
        startDeferredDataLoadsIfNeeded()
    }

    deinit {
        timer?.invalidate()
    }

    var bestScore: Int? {
        UserDefaults.standard.dictionary(forKey: preferencesKey)?["bestScore"] as? Int
    }

    var brandDisplayName: String {
        formatPossessiveDisplayName(displayName)
    }

    var personalDeckCount: Int { personalDeck.count }
    var customTemplateCount: Int { customTemplates.count }
    var customLearningTopicCount: Int { customLearningTopics.count }
    var hasDeckData: Bool { dataReady && !topics.isEmpty && !questionBank.isEmpty }
    var startupDataReady: Bool { dataReady && historyReady && localDataReady }

    func startDeferredDataLoadsIfNeeded() {
        guard !deferredDataLoadStarted else { return }
        deferredDataLoadStarted = true
        loadHistoryAsync()
        loadLargeLocalDataAsync()
    }

    var currentQuestion: Question? {
        guard currentIndex < deck.count else { return nil }
        return deck[currentIndex].question
    }

    var currentQuestionSavedToPersonalDeck: Bool {
        guard let currentQuestion else { return false }
        return personalDeck.contains { questionFingerprint($0) == questionFingerprint(currentQuestion) }
    }

    var orderedResults: [SessionResult] {
        results.sorted { $0.cardNumber < $1.cardNumber }
    }

    var reviewResultsNewestFirst: [SessionResult] {
        results.sorted { $0.updatedSequence > $1.updatedSequence }
    }

    var correctCount: Int { results.filter { $0.status == .correct }.count }
    var wrongCount: Int { results.filter { $0.status == .wrong }.count }
    var skippedCount: Int { results.filter { $0.status == .skipped }.count }

    var topicSelectionSummary: String {
        let selected = selectedTopicIds.count
        let difficultyCopy = difficulty == .all ? "mixed difficulty" : difficulty == .freddybean ? "Freddybean difficulty" : difficulty.label.lowercased()
        let sourceCopy =
            personalDeckOnly
            ? (customCardsOnly ? "personal deck + custom cards" : "personal deck only")
            : (customCardsOnly ? "full deck + custom cards" : "full deck")
        return "\(selected) topic\(selected == 1 ? "" : "s") selected • \(questionCount) cards • \(difficultyCopy) • \(sourceCopy)"
    }

    var availableDifficulties: [DifficultyFilter] {
        freddybeanUnlocked || difficulty == .freddybean ? [.all, .freddybean, .medium, .hard] : [.all, .easy, .medium, .hard]
    }

    var recentHistory: [QuizHistoryEntry] {
        history.sorted { $0.timestamp > $1.timestamp }
    }

    var topicWorkSummaries: [TopicWorkSummary] {
        var aggregate: [String: TopicWorkSummary] = [:]
        for entry in history {
            for topicStat in entry.topicStats {
                let label = topics.first(where: { $0.id == topicStat.id })?.label ?? topicStat.id
                let previous = aggregate[topicStat.id] ?? TopicWorkSummary(id: topicStat.id, label: label, sessions: 0, correct: 0, wrong: 0, skipped: 0, score: 0)
                aggregate[topicStat.id] = TopicWorkSummary(
                    id: topicStat.id,
                    label: label,
                    sessions: previous.sessions + 1,
                    correct: previous.correct + topicStat.correct,
                    wrong: previous.wrong + topicStat.wrong,
                    skipped: previous.skipped + topicStat.skipped,
                    score: previous.score + topicStat.score
                )
            }
        }
        return aggregate.values.sorted {
            if abs($0.accuracy - $1.accuracy) > 0.0001 { return $0.accuracy < $1.accuracy }
            if $0.score != $1.score { return $0.score < $1.score }
            return $0.attempted > $1.attempted
        }
    }

    var trophyStates: [TrophyState] {
        [
            trophyState(
                id: "half-century",
                icon: "sf:trophy.fill",
                title: "Half-Century Finisher",
                detail: "Finish an all-topics quiz with at least 10 questions and at least 50% correct.",
                predicate: { entry in
                    entry.questionCount >= 10 && accuracy(entry) >= 0.5
                }
            ),
            trophyState(
                id: "half-century-hard",
                icon: "sf:trophy.fill",
                title: "Hard Half-Century",
                detail: "Finish an all-topics Hard-only quiz with at least 10 questions and at least 50% correct.",
                predicate: { entry in
                    entry.questionCount >= 10 && entry.difficulty == DifficultyFilter.hard.rawValue && accuracy(entry) >= 0.5
                }
            ),
            trophyState(
                id: "century-run",
                icon: "sf:trophy.fill",
                title: "Century Run",
                detail: "Finish an all-topics quiz with 100 questions and at least 35% correct.",
                predicate: { entry in
                    entry.questionCount == 100 && accuracy(entry) >= 0.35
                }
            ),
            trophyState(
                id: "pressure-crown",
                icon: "sf:crown.fill",
                title: "Pressure Crown",
                detail: "Finish an all-topics intense-mode quiz with at least 50% correct and at most 5 minutes per question.",
                predicate: { entry in
                    entry.intenseTimer == true && accuracy(entry) >= 0.5 && minutesPerQuestion(entry) <= 5
                }
            ),
            trophyState(
                id: "perfect-crown",
                icon: "sf:crown.fill",
                title: "Perfect Crown",
                detail: "Finish an all-topics intense-mode quiz with at least 20 questions, 100% correct, and at most 5 minutes per question.",
                predicate: { entry in
                    entry.intenseTimer == true && entry.questionCount >= 20 && accuracy(entry) >= 1 && minutesPerQuestion(entry) <= 5
                }
            ),
            trophyState(
                id: "imperial-crown",
                icon: "👑",
                title: "Signal Deck Crown",
                detail: "Finish an all-topics intense-mode quiz with at least 20 questions, 100% correct, and at most 2 minutes per question.",
                predicate: { entry in
                    entry.intenseTimer == true && entry.questionCount >= 20 && accuracy(entry) >= 1 && minutesPerQuestion(entry) <= 2
                }
            ),
        ]
    }

    private func trophyState(
        id: String,
        icon: String,
        title: String,
        detail: String,
        predicate: (QuizHistoryEntry) -> Bool
    ) -> TrophyState {
        let qualifying = history.filter { entry in
            isGlobalTrophyEligible(entry) && predicate(entry)
        }
        return TrophyState(
            id: id,
            icon: icon,
            title: title,
            detail: detail,
            isUnlocked: !qualifying.isEmpty,
            hasStarRing: qualifying.contains(where: { $0.showHints == false })
        )
    }

    private func isGlobalTrophyEligible(_ entry: QuizHistoryEntry) -> Bool {
        let allTopicIds = Set(topics.map(\.id))
        let selected = Set(entry.selectedTopicIds)
        return !allTopicIds.isEmpty && selected == allTopicIds && entry.personalDeckOnly != true && entry.customCardsOnly != true
    }

    private func accuracy(_ entry: QuizHistoryEntry) -> Double {
        Double(entry.correct) / Double(max(1, entry.questionCount))
    }

    private func minutesPerQuestion(_ entry: QuizHistoryEntry) -> Double {
        Double(entry.timerMinutes) / Double(max(1, entry.questionCount))
    }

    func topicLabel(for topicId: String) -> String {
        topics.first(where: { $0.id == topicId })?.label ?? topicId
    }

    func questionForBuiltInProblemKey(_ key: String) -> Question? {
        questionLookupByProblemKey[key]
    }

    func toggleTopic(_ topicId: String) {
        var updated = selectedTopicIds
        if updated.contains(topicId) {
            updated.remove(topicId)
        } else {
            updated.insert(topicId)
        }
        selectedTopicIds = updated
    }

    func selectAllTopics() {
        selectedTopicIds = Set(topics.map(\.id))
    }

    func clearTopics() {
        selectedTopicIds.removeAll()
    }

    func ensureTopicSelection() {
        if selectedTopicIds.isEmpty && !topics.isEmpty {
            selectedTopicIds = Set(topics.map(\.id))
        }
    }

    func updateDisplayName(_ rawName: String) {
        let trimmed = rawName
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        displayName = sanitizeDisplayName(trimmed)
        savePreferences()
    }

    func setPersonalDeckOnly(_ enabled: Bool) {
        personalDeckOnly = enabled
        savePreferences()
    }

    func setCustomCardsOnly(_ enabled: Bool) {
        customCardsOnly = enabled
        savePreferences()
    }

    func startSession() {
        setupError = nil
        inputError = nil
        guard hasDeckData else {
            setupError = "The deck is still loading. Give it a moment and try again."
            return
        }
        guard questionCount >= 5, questionCount <= 100 else {
            setupError = "Use a question count between 5 and 100."
            return
        }
        guard timerMinutes >= 0, timerMinutes <= 100 else {
            setupError = "Use a timer between 0 and 100 minutes."
            return
        }
        let totalTimerSeconds = timerMinutes * 60
        if intenseTimer && totalTimerSeconds <= 0 {
            setupError = "Intense mode needs a nonzero session timer."
            return
        }
        if intenseTimer && totalTimerSeconds < questionCount {
            setupError = "Intense mode needs at least 1 second per question. Increase the timer or lower the question count."
            return
        }
        let chosenTopics = Array(selectedTopicIds)
        guard !chosenTopics.isEmpty else {
            setupError = "Select at least one topic before starting."
            return
        }
        let questionDeck = buildSessionDeck(
            selectedTopicIds: chosenTopics,
            sessionLength: questionCount,
            difficulty: difficulty,
            personalDeckOnly: personalDeckOnly,
            customCardsOnly: customCardsOnly
        )
        guard !questionDeck.isEmpty else {
            setupError =
                personalDeckOnly
                ? (customCardsOnly
                    ? "No saved personal-deck or custom cards match that topic and difficulty combination."
                    : "No saved personal-deck cards match that topic and difficulty combination.")
                : (customCardsOnly
                    ? "No built-in or custom cards match that topic and difficulty combination."
                    : "No questions match that topic and difficulty combination.")
            return
        }
        lastCompletedSetup = (selectedTopicIds, difficulty, questionCount, timerMinutes, showHints, intenseTimer, personalDeckOnly, customCardsOnly)
        baseDeck = questionDeck.enumerated().map { idx, question in
            DeckEntry(id: "card-\(idx + 1)", originalCardNumber: idx + 1, question: question, revisitCount: 0, canScheduleRevisit: true)
        }
        deck = baseDeck
        currentIndex = 0
        results = []
        updateSequence = 0
        timerSeconds = totalTimerSeconds
        remainingSeconds = timerSeconds
        elapsedSeconds = 0
        perQuestionBaseSeconds = intenseTimer && questionCount > 0 ? timerSeconds / questionCount : 0
        perQuestionBonusQuestions = intenseTimer && questionCount > 0 ? timerSeconds % questionCount : 0
        lastResultStatus = nil
        liveScore = 0
        phase = .session
        reviewSheetOpen = false
        answerText = ""
        updateProgress()
        prepareCurrentQuestionTimer()
        startTimerIfNeeded()
        savePreferences()
    }

    func exitSession() {
        timer?.invalidate()
        timer = nil
        resetSessionState()
        phase = .setup
    }

    func endSessionEarly() {
        guard phase == .session else { return }
        finishSession()
    }

    func resetToSetup() {
        timer?.invalidate()
        timer = nil
        resetSessionState()
        phase = .setup
    }

    func redoLastQuiz() {
        guard let setup = lastCompletedSetup else {
            resetToSetup()
            return
        }
        selectedTopicIds = setup.selectedTopicIds
        difficulty = setup.difficulty
        questionCount = setup.questionCount
        timerMinutes = setup.timerMinutes
        showHints = setup.showHints
        intenseTimer = setup.intenseTimer
        personalDeckOnly = setup.personalDeckOnly
        customCardsOnly = setup.customCardsOnly
        startSession()
    }

    func addCurrentQuestionToPersonalDeck() {
        guard let currentQuestion else { return }
        let fingerprint = questionFingerprint(currentQuestion)
        guard !personalDeck.contains(where: { questionFingerprint($0) == fingerprint }) else { return }
        personalDeck.insert(currentQuestion, at: 0)
        if personalDeck.count > 1000 {
            personalDeck = Array(personalDeck.prefix(1000))
        }
        saveLargeLocalData()
    }

    func previewCustomTemplate(_ template: CustomQuestionTemplate, randomizedPreview: Bool = false) throws -> Question {
        var rng = SystemRandomNumberGenerator()
        return try instantiateCustomQuestion(from: template, useRandomValues: randomizedPreview && template.randomized, rng: &rng)
    }

    func upsertCustomTemplate(_ template: CustomQuestionTemplate) throws {
        _ = try previewCustomTemplate(template, randomizedPreview: template.randomized)
        if let idx = customTemplates.firstIndex(where: { $0.id == template.id }) {
            customTemplates[idx] = template
        } else {
            customTemplates.insert(template, at: 0)
        }
        customTemplates.sort { $0.createdAt > $1.createdAt }
        if customTemplates.count > 1000 {
            customTemplates = Array(customTemplates.prefix(1000))
        }
        saveLargeLocalData()
    }

    func deleteCustomTemplate(_ templateId: String) {
        customTemplates.removeAll { $0.id == templateId }
        saveLargeLocalData()
    }

    func replaceCustomLearningTopics(_ topics: [CustomLearningTopic]) {
        customLearningTopics = normalizeCustomLearningTopics(topics)
        saveLargeLocalData()
        LearningGuideHTMLProvider.invalidate()
    }

    private func buildRecoveryPayloadObject() -> [String: Any] {
        var payload: [String: Any] = ["v": 4]
        if displayName != Self.defaultDisplayName {
            payload["n"] = displayName
        }

        let defaultTopics = topics.map(\.id).sorted()
        let selectedTopics = Array(selectedTopicIds).sorted()
        var prefs: [String: Any] = [:]
        if questionCount != 20 { prefs["q"] = questionCount }
        if timerMinutes != 5 { prefs["t"] = Double(timerMinutes) }
        if difficulty != .all { prefs["d"] = difficulty.rawValue }
        if showHints { prefs["h"] = 1 }
        if intenseTimer { prefs["i"] = 1 }
        if personalDeckOnly { prefs["p"] = 1 }
        if customCardsOnly { prefs["u"] = 1 }
        if selectedTopics != defaultTopics { prefs["s"] = selectedTopics }
        if let bestScore { prefs["b"] = bestScore }
        if freddybeanUnlocked { prefs["f"] = 1 }
        if !prefs.isEmpty { payload["p"] = prefs }

        let encodedHistory = history.map(serializeHistoryEntryForRecovery)
        if !encodedHistory.isEmpty { payload["h"] = encodedHistory }

        let encodedDeck = personalDeck.map(serializePersonalDeckRefForRecovery)
        if !encodedDeck.isEmpty { payload["d"] = encodedDeck }
        let encodedCustomTemplates = customTemplates.map(serializeCustomTemplateForRecovery)
        if !encodedCustomTemplates.isEmpty { payload["c"] = encodedCustomTemplates }
        let encodedCustomLearningTopics = customLearningTopics.map(serializeCustomLearningTopicForRecovery)
        if !encodedCustomLearningTopics.isEmpty { payload["l"] = encodedCustomLearningTopics }

        return payload
    }

    func generateRecoveryCode() throws -> String {
        let payload = buildRecoveryPayloadObject()
        let data = try JSONSerialization.data(withJSONObject: payload, options: [])
        return Self.recoveryCodePrefix + base64URLEncode(data)
    }

    func restoreFromRecoveryCode(_ rawCode: String) throws {
        historyLoadVersion += 1
        localDataLoadVersion += 1
        let trimmed = rawCode.trimmingCharacters(in: .whitespacesAndNewlines)
        let data: Data
        if Self.looksLikeShortRecoveryCode(trimmed) {
            let snapshots = loadRecoverySnapshots()
            guard let json = snapshots[trimmed] else {
                throw NSError(domain: "SignalDeck", code: 1, userInfo: [NSLocalizedDescriptionKey: "That is a legacy local-only code. Recover it on the device that created it, then generate a new portable code."])
            }
            data = Data(json.utf8)
        } else {
            guard trimmed.hasPrefix(Self.recoveryCodePrefix) else {
                throw NSError(domain: "SignalDeck", code: 1, userInfo: [NSLocalizedDescriptionKey: "That recovery code is not a Signal Deck code."])
            }

            let body = String(trimmed.dropFirst(Self.recoveryCodePrefix.count))
            data = try base64URLDecode(body)
        }

        if let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], (object["v"] as? Int) == 4 {
            let prefs = object["p"] as? [String: Any] ?? [:]
            let restoredDifficultyRaw = (prefs["d"] as? String) ?? DifficultyFilter.all.rawValue
            let unlocked = ((prefs["f"] as? Int) == 1) || restoredDifficultyRaw == DifficultyFilter.freddybean.rawValue

            history = ((object["h"] as? [Any]) ?? [])
                .compactMap(deserializeHistoryEntryFromRecovery)
                .sorted { $0.timestamp > $1.timestamp }
            if history.count > 200 {
                history = Array(history.prefix(200))
            }

            personalDeck = Array((((object["d"] as? [Any]) ?? []).compactMap { deserializePersonalDeckRefFromRecovery($0, store: self) }).prefix(1000))
            customTemplates = Array((((object["c"] as? [Any]) ?? []).compactMap(deserializeCustomTemplateFromRecovery)).prefix(1000))
            customLearningTopics = normalizeCustomLearningTopics((((object["l"] as? [Any]) ?? []).compactMap(deserializeCustomLearningTopicFromRecovery)))
            displayName = sanitizeDisplayName(object["n"] as? String)
            questionCount = max(5, min(100, (prefs["q"] as? Int) ?? 20))
            timerMinutes = max(0, min(100, Int(((prefs["t"] as? Double) ?? 5).rounded())))
            difficulty = DifficultyFilter(rawValue: restoredDifficultyRaw) ?? .all
            showHints = ((prefs["h"] as? Int) ?? 0) == 1
            intenseTimer = ((prefs["i"] as? Int) ?? 0) == 1
            personalDeckOnly = ((prefs["p"] as? Int) ?? 0) == 1
            customCardsOnly = ((prefs["u"] as? Int) ?? 0) == 1
            selectedTopicIds = Set(sanitizeTopicSelection((prefs["s"] as? [String]) ?? topics.map(\.id)))
            freddybeanUnlocked = unlocked
            ensureTopicSelection()
            var existing = UserDefaults.standard.dictionary(forKey: preferencesKey) ?? [:]
            if let bestScore = prefs["b"] as? Int {
                existing["bestScore"] = bestScore
            } else {
                existing.removeValue(forKey: "bestScore")
            }
            UserDefaults.standard.set(existing, forKey: preferencesKey)
            resetSessionState()
            phase = .setup
            saveHistory()
            savePreferences()
            saveLargeLocalData()
            LearningGuideHTMLProvider.invalidate()
            return
        }

        if let object = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any], (object["v"] as? Int) == 2 {
            let prefs = object["p"] as? [Any] ?? []
            let restoredDifficultyRaw = (prefs.indices.contains(2) ? prefs[2] as? String : nil) ?? DifficultyFilter.all.rawValue
            let unlocked = (prefs.indices.contains(8) ? ((prefs[8] as? Int) == 1) : false) || restoredDifficultyRaw == DifficultyFilter.freddybean.rawValue

            history = ((object["h"] as? [Any]) ?? [])
                .compactMap(deserializeHistoryEntryFromRecovery)
                .sorted { $0.timestamp > $1.timestamp }
            if history.count > 200 {
                history = Array(history.prefix(200))
            }

            personalDeck = Array((((object["d"] as? [Any]) ?? []).compactMap(deserializeQuestionFromRecovery)).prefix(1000))
            customTemplates = []
            customLearningTopics = []
            displayName = sanitizeDisplayName(object["n"] as? String)
            questionCount = max(5, min(100, (prefs.indices.contains(0) ? prefs[0] as? Int : nil) ?? 20))
            timerMinutes = max(0, min(100, Int(((prefs.indices.contains(1) ? prefs[1] as? Double : nil) ?? 0).rounded())))
            difficulty = DifficultyFilter(rawValue: restoredDifficultyRaw) ?? .all
            showHints = ((prefs.indices.contains(3) ? prefs[3] as? Int : nil) ?? 0) == 1
            intenseTimer = ((prefs.indices.contains(4) ? prefs[4] as? Int : nil) ?? 0) == 1
            personalDeckOnly = ((prefs.indices.contains(5) ? prefs[5] as? Int : nil) ?? 0) == 1
            customCardsOnly = false
            selectedTopicIds = Set(sanitizeTopicSelection((prefs.indices.contains(6) ? prefs[6] as? [String] : nil) ?? []))
            freddybeanUnlocked = unlocked
            ensureTopicSelection()
            var existing = UserDefaults.standard.dictionary(forKey: preferencesKey) ?? [:]
            if let bestScore = prefs.indices.contains(7) ? prefs[7] as? Int : nil {
                existing["bestScore"] = bestScore
            } else {
                existing.removeValue(forKey: "bestScore")
            }
            UserDefaults.standard.set(existing, forKey: preferencesKey)
            resetSessionState()
            phase = .setup
            saveHistory()
            savePreferences()
            saveLargeLocalData()
            LearningGuideHTMLProvider.invalidate()
            return
        }

        let payload = try JSONDecoder().decode(RecoveryPayload.self, from: data)

        history = payload.history.compactMap { entry -> QuizHistoryEntry? in
            guard let timestamp = iso8601Date(from: entry.timestamp) else { return nil }
            return QuizHistoryEntry(
                id: entry.id,
                timestamp: timestamp,
                selectedTopicIds: sanitizeTopicSelection(entry.selectedTopicIds),
                difficulty: entry.difficulty,
                questionCount: max(5, min(100, entry.questionCount)),
                timerMinutes: max(0, min(100, Int(entry.timerMinutes.rounded()))),
                intenseTimer: entry.intenseTimer,
                showHints: entry.showHints,
                personalDeckOnly: entry.personalDeckOnly,
                customCardsOnly: entry.customCardsOnly,
                elapsedSeconds: entry.elapsedSeconds,
                score: entry.score,
                correct: entry.correct,
                wrong: entry.wrong,
                skipped: entry.skipped,
                topicStats: entry.topicStats
            )
        }.sorted { $0.timestamp > $1.timestamp }
        if history.count > 200 {
            history = Array(history.prefix(200))
        }

        personalDeck = Array(payload.personalDeck.prefix(1000))
        customTemplates = Array((payload.customTemplates ?? []).prefix(1000))
        customLearningTopics = normalizeCustomLearningTopics(payload.customLearningTopics ?? [])
        displayName = sanitizeDisplayName(payload.displayName)
        let prefs = payload.preferences
        questionCount = max(5, min(100, prefs.questionCount))
        timerMinutes = max(0, min(100, Int(prefs.timerMinutes.rounded())))
        difficulty = DifficultyFilter(rawValue: prefs.difficulty) ?? .all
        showHints = prefs.showHints
        intenseTimer = prefs.intenseTimer
        personalDeckOnly = prefs.personalDeckOnly
        customCardsOnly = prefs.customCardsOnly ?? false
        selectedTopicIds = Set(sanitizeTopicSelection(prefs.selectedTopics))
        freddybeanUnlocked = prefs.difficulty == DifficultyFilter.freddybean.rawValue
        ensureTopicSelection()
        var existing = UserDefaults.standard.dictionary(forKey: preferencesKey) ?? [:]
        if let bestScore = prefs.bestScore {
            existing["bestScore"] = bestScore
        } else {
            existing.removeValue(forKey: "bestScore")
        }
        UserDefaults.standard.set(existing, forKey: preferencesKey)
        resetSessionState()
        phase = .setup
        saveHistory()
        savePreferences()
        saveLargeLocalData()
        LearningGuideHTMLProvider.invalidate()
    }

    private func loadRecoverySnapshots() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: recoverySnapshotsKey) as? [String: String] ?? [:]
    }

    private func saveRecoverySnapshots(_ snapshots: [String: String]) {
        UserDefaults.standard.set(snapshots, forKey: recoverySnapshotsKey)
    }

    private func generateShortRecoveryCode() -> String {
        var code = Self.shortRecoveryCodePrefix
        for _ in 0..<(Self.shortRecoveryCodeLength - Self.shortRecoveryCodePrefix.count) {
            code.append(Self.shortRecoveryAlphabet.randomElement() ?? "A")
        }
        return code
    }

    private static func looksLikeShortRecoveryCode(_ text: String) -> Bool {
        guard text.count == shortRecoveryCodeLength, text.hasPrefix(shortRecoveryCodePrefix) else { return false }
        for scalar in text.dropFirst(shortRecoveryCodePrefix.count) {
            guard shortRecoveryAlphabet.contains(scalar) else { return false }
        }
        return true
    }

    func clearAllMemory() {
        timer?.invalidate()
        timer = nil
        secretStatusWorkItem?.cancel()
        historyLoadVersion += 1
        localDataLoadVersion += 1
        history = []
        personalDeck = []
        customTemplates = []
        customLearningTopics = []
        historyReady = true
        localDataReady = true
        UserDefaults.standard.removeObject(forKey: historyKey)
        UserDefaults.standard.removeObject(forKey: preferencesKey)
        UserDefaults.standard.removeObject(forKey: recoverySnapshotsKey)
        UserDefaults.standard.removeObject(forKey: personalDeckDataKey)
        UserDefaults.standard.removeObject(forKey: customTemplatesDataKey)
        UserDefaults.standard.removeObject(forKey: customLearningTopicsDataKey)
        difficulty = .all
        questionCount = 20
        timerMinutes = 0
        showHints = false
        intenseTimer = false
        personalDeckOnly = false
        customCardsOnly = false
        liveGenerationEnabled = true
        displayName = Self.defaultDisplayName
        freddybeanUnlocked = false
        difficultySecretTapCount = 0
        secretStatusMessage = nil
        selectedTopicIds = Set(topics.map(\.id))
        lastCompletedSetup = nil
        resetSessionState()
        phase = .setup
        LearningGuideHTMLProvider.invalidate()
    }

    func toggleLiveGenerationMode() {
        liveGenerationEnabled.toggle()
        savePreferences()
        secretStatusWorkItem?.cancel()
        secretStatusMessage = liveGenerationEnabled ? "Live generation enabled" : "Live generation disabled"
        let workItem = DispatchWorkItem { [weak self] in
            self?.secretStatusMessage = nil
        }
        secretStatusWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: workItem)
    }

    func triggerFreddybeanUnlockTap() {
        if freddybeanUnlocked {
            difficultySecretTapCount += 1
            difficultySecretWorkItem?.cancel()
            let workItem = DispatchWorkItem { [weak self] in
                self?.difficultySecretTapCount = 0
            }
            difficultySecretWorkItem = workItem

            if difficultySecretTapCount >= 5 {
                difficultySecretTapCount = 0
                freddybeanUnlocked = false
                if difficulty == .freddybean {
                    difficulty = .easy
                }
                secretStatusWorkItem?.cancel()
                secretStatusMessage = "Freddybean difficulty hidden"
                savePreferences()
                let clearMessage = DispatchWorkItem { [weak self] in
                    self?.secretStatusMessage = nil
                }
                secretStatusWorkItem = clearMessage
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: clearMessage)
                return
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
            return
        }

        difficultySecretTapCount += 1
        difficultySecretWorkItem?.cancel()
        let workItem = DispatchWorkItem { [weak self] in
            self?.difficultySecretTapCount = 0
        }
        difficultySecretWorkItem = workItem

        if difficultySecretTapCount >= 5 {
            difficultySecretTapCount = 0
            freddybeanUnlocked = true
            difficulty = .freddybean
            secretStatusWorkItem?.cancel()
            secretStatusMessage = "Freddybean difficulty unlocked"
            savePreferences()
            let clearMessage = DispatchWorkItem { [weak self] in
                self?.secretStatusMessage = nil
            }
            secretStatusWorkItem = clearMessage
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.2, execute: clearMessage)
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6, execute: workItem)
    }

    func submitCurrentAnswer() {
        inputError = nil
        guard let currentEntry = currentDeckEntry() else {
            finishSession()
            return
        }
        let raw = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else {
            inputError = "Type an estimate or skip the card."
            return
        }
        guard let parsed = parseAnswer(rawInput: raw, inputMode: currentEntry.question.inputMode) else {
            inputError = "Try a number, a fraction like 4/9, or a percent like 5%."
            return
        }
        let correct = isApproxCorrect(question: currentEntry.question, parsedAnswer: parsed, rawInput: raw)
        registerResolvedCard(
            SessionResult(
                id: currentEntry.id,
                cardNumber: currentEntry.originalCardNumber,
                question: currentEntry.question,
                rawInput: raw,
                parsedAnswer: parsed,
                status: correct ? .correct : .wrong,
                score: correct ? 1 : -1,
                revisitPending: false,
                timedOut: false,
                attempts: 1,
                everSkipped: false,
                updatedSequence: 0
            )
        )
    }

    func skipCurrentQuestion() {
        guard var currentEntry = currentDeckEntry() else {
            finishSession()
            return
        }
        currentEntry.canScheduleRevisit = false
        deck.append(
            DeckEntry(
                id: currentEntry.id,
                originalCardNumber: currentEntry.originalCardNumber,
                question: currentEntry.question,
                revisitCount: currentEntry.revisitCount + 1,
                canScheduleRevisit: false
            )
        )
        registerResolvedCard(
            SessionResult(
                id: currentEntry.id,
                cardNumber: currentEntry.originalCardNumber,
                question: currentEntry.question,
                rawInput: "",
                parsedAnswer: nil,
                status: .skipped,
                score: 0,
                revisitPending: true,
                timedOut: false,
                attempts: 1,
                everSkipped: true,
                updatedSequence: 0
            )
        )
    }

    private func handleTimedOutQuestion() {
        guard let currentEntry = currentDeckEntry() else {
            finishSession()
            return
        }
        let raw = answerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let parsed = raw.isEmpty ? nil : parseAnswer(rawInput: raw, inputMode: currentEntry.question.inputMode)
        registerResolvedCard(
            SessionResult(
                id: currentEntry.id,
                cardNumber: currentEntry.originalCardNumber,
                question: currentEntry.question,
                rawInput: raw,
                parsedAnswer: parsed,
                status: .wrong,
                score: -1,
                revisitPending: false,
                timedOut: true,
                attempts: 1,
                everSkipped: false,
                updatedSequence: 0
            )
        )
    }

    private func loadDataAsync() {
        if let cachedTopics = Self.cachedTopics,
           let cachedQuestionBank = Self.cachedQuestionBank,
           let cachedQuestionLookupByProblemKey = Self.cachedQuestionLookupByProblemKey {
            topics = cachedTopics
            questionBank = cachedQuestionBank
            questionLookupByProblemKey = cachedQuestionLookupByProblemKey
            dataReady = true
            if selectedTopicIds.isEmpty {
                selectedTopicIds = Set(topics.map(\.id))
            }
            ensureTopicSelection()
            return
        }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            guard let url = Bundle.main.url(forResource: "AppData", withExtension: "json"),
                  let data = try? Data(contentsOf: url) else {
                DispatchQueue.main.async {
                    self.topics = []
                    self.questionBank = [:]
                    self.questionLookupByProblemKey = [:]
                    self.dataReady = false
                }
                return
            }

            let decoded: ([Topic], [String: [Question]], [String: Question])?
            if let payload = try? JSONDecoder().decode(AppDataPayload.self, from: data) {
                let bank = payload.questionBank.mapValues { $0.map(annotatedBuiltInQuestion) }
                decoded = (payload.topics, bank, buildQuestionLookup(from: bank))
            } else if let rawPayload = try? JSONDecoder().decode(RawAppDataPayload.self, from: data) {
                let bank = rawPayload.questionBank.mapValues { $0.compactMap { $0.normalized() }.map(annotatedBuiltInQuestion) }
                decoded = (rawPayload.topics, bank, buildQuestionLookup(from: bank))
            } else {
                decoded = nil
            }

            DispatchQueue.main.async {
                guard let decoded else {
                    self.topics = []
                    self.questionBank = [:]
                    self.questionLookupByProblemKey = [:]
                    self.dataReady = false
                    return
                }
                Self.cachedTopics = decoded.0
                Self.cachedQuestionBank = decoded.1
                Self.cachedQuestionLookupByProblemKey = decoded.2
                self.topics = decoded.0
                self.questionBank = decoded.1
                self.questionLookupByProblemKey = decoded.2
                self.dataReady = true
                if self.selectedTopicIds.isEmpty {
                    self.selectedTopicIds = Set(self.topics.map(\.id))
                }
                self.ensureTopicSelection()
            }
        }
    }

    private func loadPreferences() {
        let defaults = UserDefaults.standard.dictionary(forKey: preferencesKey) ?? [:]
        if let count = defaults["questionCount"] as? Int { questionCount = count }
        if let minutes = defaults["timerMinutes"] as? Int { timerMinutes = minutes }
        if let show = defaults["showHints"] as? Bool { showHints = show }
        if let intense = defaults["intenseTimer"] as? Bool { intenseTimer = intense }
        if let personalOnly = defaults["personalDeckOnly"] as? Bool { personalDeckOnly = personalOnly }
        if let customOnly = defaults["customCardsOnly"] as? Bool { customCardsOnly = customOnly }
        liveGenerationEnabled = defaults["liveGenerationEnabled"] as? Bool ?? true
        if let unlocked = defaults["freddybeanUnlocked"] as? Bool { freddybeanUnlocked = unlocked }
        if let name = defaults["displayName"] as? String { displayName = sanitizeDisplayName(name) }
        if let difficultyRaw = defaults["difficulty"] as? String, let saved = DifficultyFilter(rawValue: difficultyRaw) { difficulty = saved }
        if difficulty == .freddybean {
            freddybeanUnlocked = true
        }
        if let topicsArray = defaults["selectedTopics"] as? [String], !topicsArray.isEmpty {
            selectedTopicIds = Set(sanitizeTopicSelection(topicsArray))
        } else {
            selectedTopicIds = Set(topics.map(\.id))
        }
        ensureTopicSelection()
    }

    private func loadLargeLocalDataAsync() {
        localDataLoadVersion += 1
        let version = localDataLoadVersion
        let defaults = UserDefaults.standard
        let modernPersonalDeckData = defaults.data(forKey: personalDeckDataKey)
        let legacyDefaults = defaults.dictionary(forKey: preferencesKey) ?? [:]
        let legacyPersonalDeckData = legacyDefaults["personalDeck"] as? Data
        let modernCustomTemplateData = defaults.data(forKey: customTemplatesDataKey)
        let legacyCustomTemplateData = legacyDefaults["customTemplates"] as? Data
        let modernCustomLearningTopicsData = defaults.data(forKey: customLearningTopicsDataKey)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            let decodedPersonalDeck =
                (modernPersonalDeckData.flatMap { try? JSONDecoder().decode([Question].self, from: $0) })
                ?? (legacyPersonalDeckData.flatMap { try? JSONDecoder().decode([Question].self, from: $0) })
                ?? []
            let decodedCustomTemplates =
                (modernCustomTemplateData.flatMap { try? JSONDecoder().decode([CustomQuestionTemplate].self, from: $0) })
                ?? (legacyCustomTemplateData.flatMap { try? JSONDecoder().decode([CustomQuestionTemplate].self, from: $0) })
                ?? []
            let decodedCustomLearningTopics =
                (modernCustomLearningTopicsData.flatMap { try? JSONDecoder().decode([CustomLearningTopic].self, from: $0) })
                ?? []
            DispatchQueue.main.async {
                guard let self, self.localDataLoadVersion == version else { return }
                self.personalDeck = decodedPersonalDeck
                self.customTemplates = decodedCustomTemplates
                self.customLearningTopics = normalizeCustomLearningTopics(decodedCustomLearningTopics)
                LearningGuideHTMLProvider.invalidate()
                LearningGuideHTMLProvider.fetch(customTopics: self.customLearningTopics) { [weak self] _ in
                    self?.localDataReady = true
                }
            }
        }
    }

    private func loadHistoryAsync() {
        historyLoadVersion += 1
        let version = historyLoadVersion
        let data = UserDefaults.standard.data(forKey: historyKey)
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let decoded = data.flatMap { try? JSONDecoder().decode([QuizHistoryEntry].self, from: $0) } ?? []
            DispatchQueue.main.async {
                guard let self, self.historyLoadVersion == version else { return }
                self.history = decoded
                self.historyReady = true
            }
        }
    }

    private func savePreferences() {
        var existing = UserDefaults.standard.dictionary(forKey: preferencesKey) ?? [:]
        existing["questionCount"] = questionCount
        existing["timerMinutes"] = timerMinutes
        existing["showHints"] = showHints
        existing["intenseTimer"] = intenseTimer
        existing["personalDeckOnly"] = personalDeckOnly
        existing["customCardsOnly"] = customCardsOnly
        existing["liveGenerationEnabled"] = liveGenerationEnabled
        existing["freddybeanUnlocked"] = freddybeanUnlocked
        existing["displayName"] = displayName
        existing["difficulty"] = difficulty.rawValue
        existing["selectedTopics"] = Array(selectedTopicIds)
        if let currentBest = existing["bestScore"] as? Int, liveScore <= currentBest {
        } else if phase == .results {
            existing["bestScore"] = liveScore
        }
        UserDefaults.standard.set(existing, forKey: preferencesKey)
    }

    private func saveLargeLocalData() {
        let personalDeckSnapshot = personalDeck
        let customTemplatesSnapshot = customTemplates
        let customLearningTopicsSnapshot = customLearningTopics
        let personalDeckDataKey = self.personalDeckDataKey
        let customTemplatesDataKey = self.customTemplatesDataKey
        let customLearningTopicsDataKey = self.customLearningTopicsDataKey
        DispatchQueue.global(qos: .utility).async {
            let defaults = UserDefaults.standard
            defaults.set(try? JSONEncoder().encode(personalDeckSnapshot), forKey: personalDeckDataKey)
            defaults.set(try? JSONEncoder().encode(customTemplatesSnapshot), forKey: customTemplatesDataKey)
            defaults.set(try? JSONEncoder().encode(customLearningTopicsSnapshot), forKey: customLearningTopicsDataKey)
        }
    }

    private func saveHistory() {
        let historySnapshot = history
        let historyKey = self.historyKey
        DispatchQueue.global(qos: .utility).async {
            guard let data = try? JSONEncoder().encode(historySnapshot) else { return }
            UserDefaults.standard.set(data, forKey: historyKey)
        }
    }

    private func startTimerIfNeeded() {
        timer?.invalidate()
        timer = nil
        guard timerSeconds > 0 else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tickTimer()
        }
    }

    private func tickTimer() {
        guard remainingSeconds > 0 else {
            if intenseTimer {
                handleTimedOutQuestion()
            } else {
                finishSession()
            }
            return
        }
        remainingSeconds -= 1
        elapsedSeconds += 1
        updateTimerLabel()
        if remainingSeconds <= 0 {
            if intenseTimer {
                handleTimedOutQuestion()
            } else {
                finishSession()
            }
        }
    }

    private func updateTimerLabel() {
        guard timerSeconds > 0 else {
            timerLabel = "Untimed"
            return
        }
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        timerLabel = String(format: "%02d:%02d", minutes, seconds)
    }

    private func updateProgress() {
        progressLabel = "\(min(results.count + (phase == .session ? 1 : 0), questionCount)) / \(questionCount)"
        liveScore = results.reduce(0) { $0 + $1.score }
    }

    private func currentQuestionTimeBudgetSeconds() -> Int {
        guard intenseTimer, timerSeconds > 0 else { return timerSeconds }
        let resolvedCount = results.count
        return perQuestionBaseSeconds + (resolvedCount < perQuestionBonusQuestions ? 1 : 0)
    }

    private func prepareCurrentQuestionTimer() {
        guard timerSeconds > 0 else {
            updateTimerLabel()
            return
        }
        if intenseTimer {
            remainingSeconds = currentQuestionTimeBudgetSeconds()
        }
        updateTimerLabel()
    }

    private func buildSessionDeck(selectedTopicIds: [String], sessionLength: Int, difficulty: DifficultyFilter, personalDeckOnly: Bool, customCardsOnly: Bool) -> [Question] {
        let customQuestionPools = customCardsOnly
            ? buildCustomTemplateQuestionPools(selectedTopicIds: selectedTopicIds, sessionLength: sessionLength, difficulty: difficulty)
            : [:]

        if personalDeckOnly {
            let pool = personalDeck.filter { question in
                guard selectedTopicIds.contains(question.topicId) else { return false }
                if difficulty == .freddybean {
                    return isFreddybeanQuestion(question)
                }
                guard difficulty == .all || question.difficulty == difficulty.rawValue else { return false }
                return true
            }
            let customQuestions = customQuestionPools.values.flatMap { $0 }
            let combinedPool = pool + customQuestions
            guard !combinedPool.isEmpty else { return [] }
            var localRng = SystemRandomNumberGenerator()
            var deckOut: [Question] = []
            while deckOut.count < sessionLength {
                if let question = combinedPool.randomElement(using: &localRng) {
                    deckOut.append(question)
                }
            }
            return deckOut.shuffled(using: &localRng)
        }

        let runtimePools = liveGenerationEnabled ? buildRuntimeGeneratedQuestionPools(selectedTopicIds: selectedTopicIds, sessionLength: sessionLength, difficulty: difficulty) : [:]
        var eligible: [String: (base: [Question], generated: [Question])] = [:]
        for topicId in selectedTopicIds {
            let base = questionBank[topicId] ?? []
            let filtered = difficulty == .all ? base : difficulty == .freddybean ? base.filter(isFreddybeanQuestion) : base.filter { $0.difficulty == difficulty.rawValue }
            let generated = (runtimePools[topicId] ?? []) + (customQuestionPools[topicId] ?? [])
            if !filtered.isEmpty || !generated.isEmpty {
                eligible[topicId] = (filtered, generated)
            }
        }
        let availableTopicIds = Array(eligible.keys)
        guard !availableTopicIds.isEmpty else { return [] }
        var localRng = SystemRandomNumberGenerator()
        var deckOut: [Question] = []
        while deckOut.count < sessionLength {
            for topicId in availableTopicIds.shuffled(using: &localRng) {
                guard let pools = eligible[topicId] else { continue }
                let useGenerated = !pools.generated.isEmpty && (pools.base.isEmpty || randomBool(probability: 0.6, using: &localRng))
                let pool = useGenerated ? pools.generated : pools.base
                guard let question = pool.randomElement(using: &localRng) else { continue }
                deckOut.append(question)
                if deckOut.count >= sessionLength { break }
            }
        }
        return deckOut.shuffled(using: &localRng)
    }

    private func buildCustomTemplateQuestionPools(selectedTopicIds: [String], sessionLength: Int, difficulty: DifficultyFilter) -> [String: [Question]] {
        let matchingTemplates = customTemplates.filter { template in
            guard selectedTopicIds.contains(template.topicId) else { return false }
            if difficulty == .all { return true }
            if difficulty == .freddybean { return template.difficulty == "easy" }
            return template.difficulty == difficulty.rawValue
        }
        guard !matchingTemplates.isEmpty else { return [:] }

        var rng = SystemRandomNumberGenerator()
        let perTopicCount = max(6, Int(ceil(Double(sessionLength) / Double(max(1, selectedTopicIds.count)))))
        var out: [String: [Question]] = [:]

        for topicId in selectedTopicIds {
            let topicTemplates = matchingTemplates.filter { $0.topicId == topicId }
            guard !topicTemplates.isEmpty else { continue }
            var validTemplates: [CustomQuestionTemplate] = []
            for template in topicTemplates {
                if (try? instantiateCustomQuestion(from: template, useRandomValues: false, rng: &rng)) != nil {
                    validTemplates.append(template)
                }
            }
            guard !validTemplates.isEmpty else { continue }

            var topicQuestions: [Question] = []
            while topicQuestions.count < perTopicCount {
                guard let template = validTemplates.randomElement(using: &rng) else { break }
                if let question = try? instantiateCustomQuestion(from: template, useRandomValues: template.randomized, rng: &rng) {
                    topicQuestions.append(question)
                }
            }
            if !topicQuestions.isEmpty {
                out[topicId] = topicQuestions
            }
        }

        return out
    }

    private func buildRuntimeGeneratedQuestionPools(selectedTopicIds: [String], sessionLength: Int, difficulty: DifficultyFilter) -> [String: [Question]] {
        var rng = SystemRandomNumberGenerator()
        let perTopicCount = max(10, Int(ceil((Double(sessionLength) * 2.0) / Double(max(1, selectedTopicIds.count)))))
        var out: [String: [Question]] = [:]

        for topicId in selectedTopicIds {
            var questions: [Question] = []
            switch topicId {
            case "ito":
                questions = tagRuntimeFamily(buildRuntimeItoQuestions(count: perTopicCount, rng: &rng), family: "ito")
            case "ev":
                questions = tagRuntimeFamily(buildRuntimeKellyQuestions(count: perTopicCount, rng: &rng), family: "kelly")
            case "sharpeGraph":
                questions = tagRuntimeFamily(buildRuntimeSharpeQuestions(count: perTopicCount, rng: &rng), family: "sharpe")
            case "classicPuzzles":
                questions = tagRuntimeFamily(buildRuntimeCouponQuestions(count: perTopicCount, rng: &rng), family: "coupon")
            case "randomWalks":
                questions = tagRuntimeFamily(buildRuntimeAsymmetricRuinQuestions(count: perTopicCount, rng: &rng), family: "asymmetricRuin")
            case "fixedIncome":
                questions = tagRuntimeFamily(buildRuntimeFixedIncomeQuestions(count: perTopicCount, rng: &rng), family: "fixedIncome")
            default:
                questions = []
            }
            if difficulty != .all {
                questions = difficulty == .freddybean ? questions.filter(isFreddybeanQuestion) : questions.filter { $0.difficulty == difficulty.rawValue }
            }
            if !questions.isEmpty {
                out[topicId] = questions
            }
        }

        return out
    }

    func buildRuntimeQuestionsForFamily(_ family: String, count: Int, difficulty: DifficultyFilter) -> [Question] {
        var rng = SystemRandomNumberGenerator()
        var questions: [Question] = []
        switch family {
        case "ito":
            questions = tagRuntimeFamily(buildRuntimeItoQuestions(count: count, rng: &rng), family: "ito")
        case "kelly":
            questions = tagRuntimeFamily(buildRuntimeKellyQuestions(count: count, rng: &rng), family: "kelly")
        case "sharpe":
            questions = tagRuntimeFamily(buildRuntimeSharpeQuestions(count: count, rng: &rng), family: "sharpe")
        case "coupon":
            questions = tagRuntimeFamily(buildRuntimeCouponQuestions(count: count, rng: &rng), family: "coupon")
        case "asymmetricRuin":
            questions = tagRuntimeFamily(buildRuntimeAsymmetricRuinQuestions(count: count, rng: &rng), family: "asymmetricRuin")
        case "fixedIncome":
            questions = tagRuntimeFamily(buildRuntimeFixedIncomeQuestions(count: count, rng: &rng), family: "fixedIncome")
        default:
            questions = []
        }

        if difficulty != .all {
            questions = difficulty == .freddybean ? questions.filter(isFreddybeanQuestion) : questions.filter { $0.difficulty == difficulty.rawValue }
        }

        return questions
    }

    private func renderedCustomTemplateText(_ templateText: String?, values: [String: Double]) -> String? {
        guard let templateText else { return nil }
        let trimmed = templateText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        return renderMathText(replacePromptVariables(in: trimmed, values: values))
    }

    private func instantiateCustomQuestion<R: RandomNumberGenerator>(from template: CustomQuestionTemplate, useRandomValues: Bool, rng: inout R) throws -> Question {
        let promptVariables = extractCustomTemplateVariableNames(from: template.promptTemplate)
        let extraTextVariables = extractCustomTemplateVariableNames(from: template.hintTemplate ?? "") + extractCustomTemplateVariableNames(from: template.solutionTemplate ?? "")
        let formulaVariables = extractFormulaVariableNames(from: [template.lowerExpression, template.upperExpression])
        let requiredVariables = Array(Set(promptVariables + formulaVariables + extraTextVariables)).sorted()
        let variableDomains = try parseVariableDomains(variableSpecText: template.variableSpecText, requiredVariableNames: requiredVariables)
        var chosenValues: [String: Double] = [:]
        for name in requiredVariables {
            guard let domain = variableDomains[name], !domain.isEmpty else {
                throw CustomTemplateFailure(message: "Variable \(name) has no usable values.")
            }
            chosenValues[name] = useRandomValues ? domain.randomElement(using: &rng)! : domain[0]
        }

        let normalizedLower = normalizeMathExpressionForEvaluation(template.lowerExpression)
        let normalizedUpper = normalizeMathExpressionForEvaluation(template.upperExpression)
        guard var lowerParser = ExpressionParser(normalizedLower, variables: chosenValues),
              let lowerValue = lowerParser.parse(),
              lowerValue.isFinite
        else {
            throw CustomTemplateFailure(message: "The lower endpoint formula could not be evaluated.")
        }
        guard var upperParser = ExpressionParser(normalizedUpper, variables: chosenValues),
              let upperValue = upperParser.parse(),
              upperValue.isFinite
        else {
            throw CustomTemplateFailure(message: "The upper endpoint formula could not be evaluated.")
        }

        let acceptedLower = min(lowerValue, upperValue)
        let acceptedUpper = max(lowerValue, upperValue)
        let renderedPrompt = renderMathText(replacePromptVariables(in: template.promptTemplate, values: chosenValues))
        let renderedCustomHint = renderedCustomTemplateText(template.hintTemplate, values: chosenValues)
        let renderedCustomSolution = renderedCustomTemplateText(template.solutionTemplate, values: chosenValues)
        let variableSummary = chosenValues.isEmpty
            ? "This custom card does not use random variables."
            : chosenValues.sorted(by: { $0.key < $1.key }).map { "\($0.key) = \(formatTemplateValue($0.value))" }.joined(separator: ", ")
        let midpoint = (acceptedLower + acceptedUpper) / 2.0
        let explanation = chosenValues.isEmpty
            ? "Evaluate the lower and upper endpoint formulas directly. Any answer between \(formatSingleCustomAnswer(value: acceptedLower, inputMode: template.inputMode)) and \(formatSingleCustomAnswer(value: acceptedUpper, inputMode: template.inputMode)), inclusive, is accepted."
            : "For this sample, \(variableSummary). Evaluating the two endpoint formulas gives an accepted interval from \(formatSingleCustomAnswer(value: acceptedLower, inputMode: template.inputMode)) to \(formatSingleCustomAnswer(value: acceptedUpper, inputMode: template.inputMode)), inclusive."

        return Question(
            topicId: template.topicId,
            category: "Custom card",
            prompt: renderedPrompt,
            hint: renderedCustomHint ?? "no hint provided for this custom card",
            inputMode: template.inputMode,
            formatHint: customFormatHint(for: template.inputMode),
            answer: midpoint,
            mentalAnswer: midpoint,
            absTolerance: 0,
            relTolerance: 0,
            explanation: explanation,
            workedSolution: renderedCustomSolution ?? "no solution text provided for this custom card",
            methodExplanation: "Custom-card grading evaluates the lower and upper endpoint formulas after substituting the sampled variable values. Any response between those two computed endpoints, inclusive, is counted as correct.",
            difficulty: template.difficulty,
            source: "custom-template",
            visual: nil,
            problemKey: "custom:\(template.id):\(hashString(renderedPrompt + "||" + formatNumber(acceptedLower, decimals: 8) + "||" + formatNumber(acceptedUpper, decimals: 8)))",
            runtimeFamily: nil,
            acceptedLower: acceptedLower,
            acceptedUpper: acceptedUpper,
            customTemplateId: template.id
        )
    }

    private func buildRuntimeItoQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        let powers: [(label: String, k: Double, difficulty: String)] = [
            ("S^2", 2, "easy"),
            ("S^3", 3, "medium"),
            ("sqrt(S)", 0.5, "medium"),
            ("1/S", -1, "medium"),
            ("1/sqrt(S)", -0.5, "hard"),
            ("S^4", 4, "hard"),
        ]
        var questions: [Question] = []

        for _ in 0..<count {
            let mu = randomChoice([4.0, 5, 6, 7, 8, 9, 10, 12], using: &rng)
            let sigma = randomChoice([15.0, 18, 20, 24, 25, 30, 35, 40], using: &rng)
            let askVol = randomBool(probability: 0.5, using: &rng)

            if randomBool(probability: 0.24, using: &rng) {
                let drift = mu - ((sigma * sigma) / 200.0)
                let answer = askVol ? sigma : drift
                questions.append(makeGeneratedQuestion(
                    topicId: "ito",
                    category: askVol ? "Ito volatility" : "Ito drift",
                    prompt: "Suppose S follows GBM with dS / S = \(formatNumber(mu, decimals: 0))% dt + \(formatNumber(sigma, decimals: 0))% dW. If X = ln(S), estimate the \(askVol ? "volatility" : "drift") of X.",
                    hint: "For X = ln S, Ito gives dX = (mu - sigma^2 / 2) dt + sigma dW.",
                    inputMode: "percent",
                    formatHint: askVol ? "volatility" : "drift",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.2,
                    explanation: askVol
                        ? "For X = ln S, Ito gives dX = (mu - sigma^2/2)dt + sigma dW, so the volatility is just sigma = \(formatNumber(sigma, decimals: 3))%."
                        : "For X = ln S, Ito gives dX = (mu - sigma^2/2)dt + sigma dW. So the drift is \(formatNumber(mu, decimals: 3))% - 0.5 × \(formatNumber(sigma, decimals: 3))%^2 = \(formatNumber(drift, decimals: 3))%.",
                    difficulty: "easy",
                    workedSolution: askVol
                        ? "Start from Ito for X = ln S: dX = (mu - sigma^2/2)dt + sigma dW. The diffusion coefficient is therefore sigma itself. Plugging in sigma = \(formatNumber(sigma, decimals: 3))% gives volatility \(formatNumber(sigma, decimals: 3))%."
                        : "Start from Ito for X = ln S: dX = (mu - sigma^2/2)dt + sigma dW. So the drift is mu - sigma^2/2. Here mu = \(formatNumber(mu, decimals: 3))% and sigma = \(formatNumber(sigma, decimals: 3))%, so the drift is \(formatNumber(mu, decimals: 3))% - 0.5 × \(formatNumber(sigma, decimals: 3))%^2 = \(formatNumber(drift, decimals: 3))%.",
                    methodExplanation: "For geometric Brownian motion, log prices are special because the second derivative of ln(S) exactly contributes the familiar -sigma^2/2 correction in the drift, while the diffusion term stays sigma."
                ))
                continue
            }

            let spec = randomChoice(powers, using: &rng)
            let drift = (spec.k * mu) + (0.5 * spec.k * (spec.k - 1) * ((sigma * sigma) / 100.0))
            let vol = abs(spec.k) * sigma
            let answer = askVol ? vol : drift
            questions.append(makeGeneratedQuestion(
                topicId: "ito",
                category: askVol ? "Ito volatility" : "Ito drift",
                prompt: "Suppose S follows GBM with dS / S = \(formatNumber(mu, decimals: 0))% dt + \(formatNumber(sigma, decimals: 0))% dW. If X = \(spec.label), estimate the proportional \(askVol ? "volatility" : "drift") of X, meaning the \(askVol ? "diffusion coefficient" : "drift") in dX / X.",
                hint: "Write X = S^k with k = \(formatNumber(spec.k, decimals: 3)). Then dX / X = (k mu + 0.5 k(k-1) sigma^2) dt + k sigma dW.",
                inputMode: "percent",
                formatHint: askVol ? "volatility" : "drift",
                answer: answer,
                mentalAnswer: answer,
                absTolerance: 0.25,
                explanation: askVol
                    ? "Here k = \(formatNumber(spec.k, decimals: 3)), so the proportional volatility is |k|sigma = \(formatNumber(abs(spec.k), decimals: 3)) × \(formatNumber(sigma, decimals: 3))% = \(formatNumber(vol, decimals: 3))%."
                    : "Use dX / X = (k mu + 0.5k(k-1)sigma^2)dt + k sigma dW. With k = \(formatNumber(spec.k, decimals: 3)), mu = \(formatNumber(mu, decimals: 3))%, and sigma = \(formatNumber(sigma, decimals: 3))%, the drift is \(formatNumber(drift, decimals: 3))%.",
                difficulty: spec.difficulty,
                workedSolution: askVol
                    ? "Let X = S^k with k = \(formatNumber(spec.k, decimals: 3)). Ito gives dX / X = (k mu + 0.5k(k-1)sigma^2)dt + k sigma dW. The proportional volatility is the magnitude of the diffusion coefficient, |k|sigma. So the answer is |\(formatNumber(spec.k, decimals: 3))| × \(formatNumber(sigma, decimals: 3))% = \(formatNumber(vol, decimals: 3))%."
                    : "Let X = S^k with k = \(formatNumber(spec.k, decimals: 3)). Ito gives dX / X = (k mu + 0.5k(k-1)sigma^2)dt + k sigma dW. Substituting mu = \(formatNumber(mu, decimals: 3))% and sigma = \(formatNumber(sigma, decimals: 3))% gives drift \(formatNumber(spec.k, decimals: 3)) × \(formatNumber(mu, decimals: 3))% + 0.5 × \(formatNumber(spec.k, decimals: 3)) × \(formatNumber(spec.k - 1, decimals: 3)) × \(formatNumber(sigma, decimals: 3))%^2 = \(formatNumber(drift, decimals: 3))%.",
                methodExplanation: "For X = S^k, Ito keeps the process in proportional form. The diffusion coefficient scales linearly with k, while the drift gains the extra quadratic correction 0.5k(k-1)sigma^2 from the second derivative."
            ))
        }

        return questions
    }

    private func buildRuntimeKellyQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        var questions: [Question] = []
        for _ in 0..<count {
            if randomBool(probability: 0.5, using: &rng) {
                let win = randomChoice([2.0, 3, 4, 5, 6, 8], using: &rng)
                let p = randomChoice([0.28, 0.30, 0.32, 0.35, 0.38, 0.40, 0.42, 0.45], using: &rng)
                let answer = ((win * p) - (1 - p)) / win
                questions.append(makeGeneratedQuestion(
                    topicId: "ev",
                    category: "Kelly criterion",
                    prompt: "A repeated bet wins \(formatNumber(win, decimals: 0)) dollars with probability \(formatPercent(p)) and loses 1 dollar otherwise. Estimate the Kelly fraction of wealth to bet.",
                    hint: "For a +b / -1 bet, Kelly gives f* = (bp - q) / b.",
                    inputMode: "number",
                    formatHint: "fraction",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.025,
                    explanation: "Use f* = (bp - q)/b with b = \(formatNumber(win, decimals: 0)), p = \(formatNumber(p, decimals: 2)), and q = \(formatNumber(1 - p, decimals: 2)). That gives \(formatNumber(answer, decimals: 4)).",
                    difficulty: answer >= 0.18 ? "medium" : "hard",
                    workedSolution: "The Kelly objective is expected log-growth. For a +b / -1 bet, differentiating p ln(1 + bf) + q ln(1 - f) gives f* = (bp - q)/b. Here b = \(formatNumber(win, decimals: 0)), p = \(formatNumber(p, decimals: 2)), and q = \(formatNumber(1 - p, decimals: 2)), so f* = (\(formatNumber(win, decimals: 0)) × \(formatNumber(p, decimals: 2)) - \(formatNumber(1 - p, decimals: 2))) / \(formatNumber(win, decimals: 0)) = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Kelly problems maximize expected log wealth, not expected dollars. Once the upside and downside are identified, the entire problem collapses to differentiating a one-variable concave function."
                ))
            } else {
                let up = randomChoice([20.0, 25, 30, 35, 40, 50, 60], using: &rng)
                let down = randomChoice([10.0, 15, 20, 25, 30], using: &rng)
                let p = randomChoice([0.32, 0.35, 0.38, 0.40, 0.42, 0.45, 0.48], using: &rng)
                let answer = generalizedKellyFractionNative(winProbability: p, upReturn: up / 100.0, downReturn: down / 100.0)
                questions.append(makeGeneratedQuestion(
                    topicId: "ev",
                    category: "Kelly criterion",
                    prompt: "Each round you either gain \(formatNumber(up, decimals: 0))% with probability \(formatPercent(p)) or lose \(formatNumber(down, decimals: 0))% otherwise. Estimate the Kelly fraction of wealth to bet.",
                    hint: "For +u / -d returns, Kelly gives f* = (pu - qd) / (ud).",
                    inputMode: "number",
                    formatHint: "fraction",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.03,
                    explanation: "Use f* = (pu - qd)/(ud). Plugging in u = \(formatNumber(up / 100.0, decimals: 2)), d = \(formatNumber(down / 100.0, decimals: 2)), p = \(formatNumber(p, decimals: 2)) gives \(formatNumber(answer, decimals: 4)).",
                    difficulty: "hard",
                    workedSolution: "Here the payoff is +u or -d in percentage terms, so the Kelly first-order condition becomes f* = (pu - qd)/(ud). Substituting u = \(formatNumber(up / 100.0, decimals: 2)), d = \(formatNumber(down / 100.0, decimals: 2)), p = \(formatNumber(p, decimals: 2)), q = \(formatNumber(1 - p, decimals: 2)) gives f* = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "The percentage-return version is the same Kelly calculus as the +b / -1 case, just with different upside and downside magnitudes. The formula is the cleanest way to carry it mentally."
                ))
            }
        }
        return questions
    }

    private func buildRuntimeSharpeQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        var questions: [Question] = []
        for _ in 0..<count {
            if randomBool(probability: 0.5, using: &rng) {
                let cadence = randomChoice(["daily", "weekly", "monthly"], using: &rng)
                let sharpe = randomChoice([0.2, 0.25, 0.35, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0], using: &rng)
                let answer = 1.0 / (1.0 + (sharpe * sharpe))
                questions.append(makeGeneratedQuestion(
                    topicId: "sharpeGraph",
                    category: "Sharpe probability bound",
                    prompt: "A portfolio has \(cadence) Sharpe \(formatNumber(sharpe, decimals: 3)). Without assuming any return distribution, give a Cantelli upper bound on the probability of a negative \(cadence) return.",
                    hint: "For target 0, Cantelli becomes 1 / (1 + Sharpe^2).",
                    inputMode: "probability",
                    formatHint: "bound",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.03,
                    explanation: "If mu/sigma = \(formatNumber(sharpe, decimals: 3)), then Cantelli gives P(R <= 0) <= 1 / (1 + Sharpe^2) = \(formatNumber(answer, decimals: 4)).",
                    difficulty: sharpe <= 0.5 ? "easy" : sharpe <= 1.5 ? "medium" : "hard",
                    workedSolution: "Cantelli says P(X - mu <= -a) <= sigma^2 / (sigma^2 + a^2). For a negative return threshold of 0, the distance from the mean is a = mu. Since Sharpe = mu/sigma, this becomes 1 / (1 + (mu/sigma)^2) = 1 / (1 + Sharpe^2). Plugging in Sharpe = \(formatNumber(sharpe, decimals: 3)) gives \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "These distribution-free Sharpe cards are really one-step inequality cards. Recover mean from Sharpe times volatility, then apply Cantelli to a one-sided event."
                ))
            } else {
                let cadence = randomChoice(["daily", "weekly", "monthly"], using: &rng)
                let periodsPerYear = cadence == "daily" ? 252 : cadence == "weekly" ? 52 : 12
                let annualized = randomBool(probability: 0.5, using: &rng)
                let returns = runtimeSharpeReturnSeries(cadence: cadence, rng: &rng)
                let cumulative = cumulativeSeries(from: returns)
                let meanReturn = averageNative(returns)
                let sdReturn = populationStandardDeviationNative(returns)
                let perPeriodSharpe = meanReturn / max(sdReturn, 1e-9)
                let answer = annualized ? perPeriodSharpe * sqrt(Double(periodsPerYear)) : perPeriodSharpe
                let titlePrefix = annualized ? "Annualized" : "Per-period"
                let visual = QuestionVisual(
                    type: "pnlChart",
                    title: "Cumulative \(cadence) PnL %",
                    note: "Estimate period-by-period changes from the graph, then divide mean by standard deviation.",
                    xLabel: cadence.capitalized,
                    yLabel: "Cumulative PnL",
                    labels: cumulative.enumerated().map { "\($0.offset)" },
                    points: cumulative,
                    unitSuffix: "%",
                    showPointValues: false,
                    showMarkers: true,
                    showVerticalGrid: true
                )
                questions.append(makeGeneratedQuestion(
                    topicId: "sharpeGraph",
                    category: "Sharpe from graph",
                    prompt: "The graph shows a cumulative \(cadence) PnL path. Estimate the \(annualized ? "annualized " : "")Sharpe ratio for the period returns.",
                    hint: "Difference adjacent cumulative points to recover returns, then divide mean by standard deviation.",
                    inputMode: "number",
                    formatHint: "Sharpe",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.25,
                    explanation: "\(titlePrefix) Sharpe is mean return divided by standard deviation, with an extra sqrt(time) factor if annualized.",
                    difficulty: "easy",
                    workedSolution: "Read the cumulative graph as a running sum. Difference adjacent points to recover the underlying \(cadence) returns. Then compute mean return and standard deviation of those period returns. Their ratio is the per-period Sharpe. If the prompt asks for annualized Sharpe, multiply by sqrt(\(periodsPerYear)). For this graph, that gives \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Recover period returns by differencing adjacent cumulative PnL values, then divide their mean by their standard deviation. Annualize by multiplying by the square root of the number of periods per year.",
                    visual: visual
                ))
            }
        }
        return questions
    }

    private func buildRuntimeCouponQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        var questions: [Question] = []
        for _ in 0..<count {
            let n = randomChoice([4, 5, 6, 8, 10, 12, 15, 20, 30, 50, 100], using: &rng)
            let mode = randomChoice(["mean", "variance", "interval"], using: &rng)

            if mode == "mean" {
                let answer = couponCollectorExpectedNative(n)
                questions.append(makeGeneratedQuestion(
                    topicId: "classicPuzzles",
                    category: "Classic puzzle: coupons",
                    prompt: "Each draw lands uniformly on one of \(n) coupon types. Estimate the expected number of draws needed to collect all \(n) types.",
                    hint: "Break the process into stages and add n / i over the unseen counts i.",
                    inputMode: "number",
                    formatHint: "draws",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: 0.09,
                    explanation: "Use E[T_n] = nH_n.",
                    difficulty: n <= 6 ? "medium" : "hard",
                    workedSolution: "After you have already seen n-i coupon types, the chance the next draw is new is i/n. So that stage has geometric mean n/i. Summing over i = 1, ..., n gives E[T_n] = n(1 + 1/2 + ... + 1/n) = nH_n = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Coupon-collector expectation cards are stage-decomposition cards. The whole trick is to recognize the waiting time as a sum of geometric stages with changing success probabilities."
                ))
                continue
            }

            if mode == "variance" {
                let answer = couponCollectorVarianceNative(n)
                let mental = n <= 12 ? answer : couponCollectorVarianceApproximationNative(n)
                questions.append(makeGeneratedQuestion(
                    topicId: "classicPuzzles",
                    category: "Classic puzzle: coupon variance",
                    prompt: "Each draw lands uniformly on one of \(n) coupon types. Estimate the variance of the draw count needed to collect all \(n) types.",
                    hint: "Write T_n as a sum of geometric stage times and add the variances.",
                    inputMode: "number",
                    formatHint: "variance",
                    answer: answer,
                    mentalAnswer: mental,
                    absTolerance: max(0.15, answer * 0.08),
                    relTolerance: 0.08,
                    explanation: "Use Var(T_n) = n^2 sum(1/i^2) - nH_n.",
                    difficulty: n <= 8 ? "medium" : "hard",
                    workedSolution: "Let X_i be the waiting time to go from n-i seen types to n-i+1 seen types. Then X_i is geometric with success probability i/n, so Var(X_i) = (1-p_i)/p_i^2 = n^2/i^2 - n/i. Adding those independent stage variances gives Var(T_n) = n^2 sum(1/i^2) - nH_n = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "The variance formula comes from the same stage decomposition as the mean, but now each geometric stage contributes (1-p)/p^2 instead of 1/p."
                ))
                continue
            }

            let z = randomBool(probability: 0.5, using: &rng) ? 1.0 : 1.96
            let side = randomBool(probability: 0.5, using: &rng) ? "lower" : "upper"
            let answer = couponCollectorIntervalValueNative(n: n, z: z, side: side, approximateVariance: false)
            let mental = couponCollectorIntervalValueNative(n: n, z: z, side: side, approximateVariance: true)
            questions.append(makeGeneratedQuestion(
                topicId: "classicPuzzles",
                category: "Classic puzzle: coupon interval",
                prompt: "Each draw lands uniformly on one of \(n) coupon types. Using the coupon-collector mean and variance, estimate the \(side) end of a rough \(z == 1 ? "one-sigma" : "95%") interval for the draw count needed to collect all \(n) types.",
                hint: "Use mean nH_n and sd = sqrt(Var(T_n)), then take mean ± z sd.",
                inputMode: "number",
                formatHint: "draws",
                answer: answer,
                mentalAnswer: mental,
                absTolerance: max(0.25, abs(answer) * 0.06),
                relTolerance: 0.06,
                explanation: "Use the coupon-collector mean and variance, then move \(formatNumber(z, decimals: 2)) standard deviations from the mean.",
                difficulty: z == 1 ? "medium" : "hard",
                workedSolution: "First compute the mean E[T_n] = nH_n and the variance Var(T_n) = n^2 sum(1/i^2) - nH_n. Then sd = sqrt(Var(T_n)). The requested endpoint is mean \(side == "lower" ? "-" : "+") z × sd with z = \(formatNumber(z, decimals: 2)). For this card that gives \(formatNumber(answer, decimals: 4)).",
                methodExplanation: "These interval cards use the coupon-collector mean and variance as a rough Gaussian summary. It is a heuristic interval, not an exact theorem, but it is a useful mental estimate."
            ))
        }
        return questions
    }

    private func buildRuntimeAsymmetricRuinQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        var questions: [Question] = []
        for _ in 0..<count {
            let upper = randomChoice([5, 6, 7, 8, 9, 10, 12, 15], using: &rng)
            let start = Int.random(in: 1..<(upper), using: &rng)
            let p = randomChoice([0.35, 0.40, 0.45, 0.55, 0.60, 0.65], using: &rng)
            let q = 1 - p
            let answer = asymmetricGamblerRuinProbabilityNative(start: start, upperBarrier: upper, rightProbability: p)
            questions.append(makeGeneratedQuestion(
                topicId: "randomWalks",
                category: "Asymmetric ruin probability",
                prompt: "A biased random walk on {0,1,...,\(upper)} starts at \(start). Each step moves right with probability \(formatPercent(p)) and left with probability \(formatPercent(q)). Estimate the probability it hits \(upper) before 0.",
                hint: "For p != q, use [1 - (q/p)^i] / [1 - (q/p)^N].",
                inputMode: "probability",
                formatHint: "probability",
                answer: answer,
                mentalAnswer: answer,
                absTolerance: 0.03,
                explanation: "Here q/p = \(formatNumber(q / p, decimals: 4)), so the asymmetric ruin formula gives \(formatNumber(answer, decimals: 4)).",
                difficulty: abs(p - 0.5) >= 0.1 ? "medium" : "hard",
                workedSolution: "For a biased walk, the hit probability h(i) solves h(i) = p h(i+1) + q h(i-1) with h(0) = 0 and h(N) = 1. The solution is h(i) = [1 - (q/p)^i] / [1 - (q/p)^N]. Here that means [1 - (\(formatNumber(q / p, decimals: 4)))^\(start)] / [1 - (\(formatNumber(q / p, decimals: 4)))^\(upper)] = \(formatNumber(answer, decimals: 4)).",
                methodExplanation: "Asymmetric gambler's ruin is a second-order difference-equation problem. Once p differs from q, the linear i/N formula is replaced by a geometric-ratio formula involving q/p."
            ))
        }
        return questions
    }

    private func buildRuntimeFixedIncomeQuestions<R: RandomNumberGenerator>(count: Int, rng: inout R) -> [Question] {
        var questions: [Question] = []
        for _ in 0..<count {
            let mode = randomChoice(["zero", "annuity", "perpetuity", "mixed"], using: &rng)
            if mode == "zero" {
                let face = randomChoice([100.0, 250, 500, 1000], using: &rng)
                let years = randomChoice([1.0, 2, 3, 5, 7, 10], using: &rng)
                let rate = randomChoice([0.02, 0.03, 0.04, 0.05, 0.06, 0.08], using: &rng)
                let continuous = randomBool(probability: 0.5, using: &rng)
                let answer = continuous ? face * exp(-rate * years) : face / pow(1 + rate, years)
                questions.append(makeGeneratedQuestion(
                    topicId: "fixedIncome",
                    category: "Zero-coupon bond",
                    prompt: continuous
                        ? "A zero-coupon bond pays \(formatNumber(face, decimals: 0)) dollars in \(formatNumber(years, decimals: 0)) years. The continuously compounded yield is \(formatPercent(rate)) per year. Estimate the bond price today."
                        : "A zero-coupon bond pays \(formatNumber(face, decimals: 0)) dollars in \(formatNumber(years, decimals: 0)) years. The annual yield is \(formatPercent(rate)) with annual compounding. Estimate the bond price today.",
                    hint: continuous ? "Use PV = Ke^(-rT)." : "Discount the face value back n periods.",
                    inputMode: "number",
                    formatHint: "price",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: max(0.25, answer * 0.03),
                    explanation: continuous
                        ? "Use PV = Ke^(-rT) = \(formatNumber(answer, decimals: 4))."
                        : "Use PV = K/(1+y)^n = \(formatNumber(answer, decimals: 4)).",
                    difficulty: years <= 3 ? "easy" : "medium",
                    workedSolution: continuous
                        ? "Discount the face value continuously: PV = Ke^(-rT) = \(formatNumber(face, decimals: 0)) × e^(-\(formatNumber(rate, decimals: 3)) × \(formatNumber(years, decimals: 0))) = \(formatNumber(answer, decimals: 4))."
                        : "Discount the face value with annual compounding: PV = K/(1+y)^n = \(formatNumber(face, decimals: 0)) / (1 + \(formatNumber(rate, decimals: 3)))^\(formatNumber(years, decimals: 0)) = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Zero-coupon bonds are single-cash-flow discounting problems. The only question is whether the compounding convention is annual or continuous."
                ))
                continue
            }

            if mode == "annuity" {
                let payment = randomChoice([5.0, 10, 20, 25, 40], using: &rng)
                let years = randomChoice([3.0, 5, 7, 10, 12], using: &rng)
                let yieldRate = randomChoice([0.03, 0.04, 0.05, 0.06, 0.08], using: &rng)
                let answer = payment * (1 - pow(1 + yieldRate, -years)) / yieldRate
                questions.append(makeGeneratedQuestion(
                    topicId: "fixedIncome",
                    category: "Annuity",
                    prompt: "A level annuity pays \(formatNumber(payment, decimals: 0)) dollars each year for \(formatNumber(years, decimals: 0)) years. If the annual yield is \(formatPercent(yieldRate)), estimate the present value.",
                    hint: "Use A(1 - (1+y)^(-n)) / y.",
                    inputMode: "number",
                    formatHint: "present value",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: max(0.25, answer * 0.03),
                    explanation: "This is a level annuity, so PV = A(1 - (1+y)^(-n)) / y = \(formatNumber(answer, decimals: 4)).",
                    difficulty: years <= 5 ? "medium" : "hard",
                    workedSolution: "A level annuity is a finite geometric series of discount factors. So PV = A(1 - (1+y)^(-n))/y = \(formatNumber(payment, decimals: 0))(1 - (1 + \(formatNumber(yieldRate, decimals: 3)))^(-\(formatNumber(years, decimals: 0))))/\(formatNumber(yieldRate, decimals: 3)) = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Annuity questions are recognition questions: once you identify equal payments at equal spacing, the finite geometric-sum formula does the rest."
                ))
                continue
            }

            if mode == "perpetuity" {
                let payment = randomChoice([4.0, 6, 8, 12, 20], using: &rng)
                let yieldRate = randomChoice([0.02, 0.03, 0.04, 0.05, 0.06], using: &rng)
                let answer = payment / yieldRate
                questions.append(makeGeneratedQuestion(
                    topicId: "fixedIncome",
                    category: "Perpetuity",
                    prompt: "A perpetuity pays \(formatNumber(payment, decimals: 0)) dollars per year forever. If the annual discount rate is \(formatPercent(yieldRate)), estimate the present value.",
                    hint: "A perpetuity is payment divided by yield.",
                    inputMode: "number",
                    formatHint: "present value",
                    answer: answer,
                    mentalAnswer: answer,
                    absTolerance: max(0.25, answer * 0.02),
                    explanation: "Use PV = C / y = \(formatNumber(answer, decimals: 4)).",
                    difficulty: "easy",
                    workedSolution: "A perpetuity is the infinite-horizon limit of an annuity. Its present value is payment divided by yield: \(formatNumber(payment, decimals: 0)) / \(formatNumber(yieldRate, decimals: 3)) = \(formatNumber(answer, decimals: 4)).",
                    methodExplanation: "Perpetuity cards are pure template-recognition cards. Constant forever cash flow means divide by the per-period discount rate."
                ))
                continue
            }

            let cash1 = randomChoice([20.0, 30, 40, 50], using: &rng)
            let cash2 = randomChoice([30.0, 40, 50, 60], using: &rng)
            let cash3 = randomChoice([40.0, 50, 75, 100], using: &rng)
            let rate = randomChoice([0.03, 0.04, 0.05, 0.06], using: &rng)
            let answer = (cash1 / (1 + rate)) + (cash2 / pow(1 + rate, 2)) + (cash3 / pow(1 + rate, 3))
            questions.append(makeGeneratedQuestion(
                topicId: "fixedIncome",
                category: "Present value",
                prompt: "Cash flows of \(formatNumber(cash1, decimals: 0)), \(formatNumber(cash2, decimals: 0)), and \(formatNumber(cash3, decimals: 0)) dollars arrive in 1, 2, and 3 years. If the annual discount rate is \(formatPercent(rate)), estimate the present value.",
                hint: "Discount each payment separately and add them up.",
                inputMode: "number",
                formatHint: "present value",
                answer: answer,
                mentalAnswer: answer,
                absTolerance: max(0.25, answer * 0.03),
                explanation: "Present value is the sum of discounted cash flows = \(formatNumber(answer, decimals: 4)).",
                difficulty: "medium",
                workedSolution: "Discount each payment to time 0 and add them: \(formatNumber(cash1, decimals: 0))/(1+\(formatNumber(rate, decimals: 3))) + \(formatNumber(cash2, decimals: 0))/(1+\(formatNumber(rate, decimals: 3)))^2 + \(formatNumber(cash3, decimals: 0))/(1+\(formatNumber(rate, decimals: 3)))^3 = \(formatNumber(answer, decimals: 4)).",
                methodExplanation: "Mixed present-value cards are cash-flow decomposition cards. There is no new formula beyond “discount each flow at its maturity, then sum.”"
            ))
        }
        return questions
    }

    private func currentDeckEntry() -> DeckEntry? {
        guard currentIndex < deck.count else { return nil }
        return deck[currentIndex]
    }

    private func registerResolvedCard(_ baseResult: SessionResult) {
        updateSequence += 1
        let merged = mergeResult(baseResult, sequence: updateSequence)
        if let idx = results.firstIndex(where: { $0.id == merged.id }) {
            results[idx] = merged
        } else {
            results.append(merged)
        }
        lastResultStatus = merged.status
        currentIndex += 1
        answerText = ""
        liveScore = results.reduce(0) { $0 + $1.score }
        if currentIndex >= deck.count {
            finishSession()
        } else {
            prepareCurrentQuestionTimer()
            updateProgress()
        }
    }

    private func mergeResult(_ incoming: SessionResult, sequence: Int) -> SessionResult {
        if let previous = results.first(where: { $0.id == incoming.id }) {
            return SessionResult(
                id: previous.id,
                cardNumber: previous.cardNumber,
                question: incoming.question,
                rawInput: incoming.rawInput,
                parsedAnswer: incoming.parsedAnswer,
                status: incoming.status,
                score: incoming.score,
                revisitPending: incoming.revisitPending,
                timedOut: incoming.timedOut,
                attempts: previous.attempts + 1,
                everSkipped: incoming.status == .skipped || previous.everSkipped,
                updatedSequence: sequence
            )
        }
        return SessionResult(
            id: incoming.id,
            cardNumber: incoming.cardNumber,
            question: incoming.question,
            rawInput: incoming.rawInput,
            parsedAnswer: incoming.parsedAnswer,
            status: incoming.status,
            score: incoming.score,
            revisitPending: incoming.revisitPending,
            timedOut: incoming.timedOut,
            attempts: 1,
            everSkipped: incoming.status == .skipped,
            updatedSequence: sequence
        )
    }

    private func finishSession() {
        timer?.invalidate()
        timer = nil
        finalizeOutstandingResults()
        phase = .results
        liveScore = results.reduce(0) { $0 + $1.score }
        updateProgress()
        appendHistoryEntry()
        savePreferences()
    }

    private func appendHistoryEntry() {
        let elapsed = elapsedSeconds
        var perTopic: [String: (correct: Int, wrong: Int, skipped: Int, score: Int)] = [:]
        for result in orderedResults {
            let key = result.question.topicId
            var current = perTopic[key] ?? (0, 0, 0, 0)
            switch result.status {
            case .correct: current.correct += 1
            case .wrong: current.wrong += 1
            case .skipped: current.skipped += 1
            case .neutral: break
            }
            current.score += result.score
            perTopic[key] = current
        }

        let entry = QuizHistoryEntry(
            id: UUID().uuidString,
            timestamp: Date(),
            selectedTopicIds: Array(selectedTopicIds).sorted(),
            difficulty: difficulty.rawValue,
            questionCount: questionCount,
            timerMinutes: timerMinutes,
            intenseTimer: intenseTimer,
            showHints: showHints,
            personalDeckOnly: personalDeckOnly,
            customCardsOnly: customCardsOnly,
            elapsedSeconds: elapsed,
            score: liveScore,
            correct: correctCount,
            wrong: wrongCount,
            skipped: skippedCount,
            topicStats: perTopic.map { key, value in
                TopicSessionStat(id: key, correct: value.correct, wrong: value.wrong, skipped: value.skipped, score: value.score)
            }.sorted { $0.id < $1.id }
        )

        history.insert(entry, at: 0)
        if history.count > 200 {
            history = Array(history.prefix(200))
        }
        saveHistory()
    }

    private func finalizeOutstandingResults() {
        for base in baseDeck {
            if results.contains(where: { $0.id == base.id }) { continue }
            updateSequence += 1
            results.append(
                SessionResult(
                    id: base.id,
                    cardNumber: base.originalCardNumber,
                    question: base.question,
                    rawInput: "",
                    parsedAnswer: nil,
                    status: .skipped,
                    score: 0,
                    revisitPending: false,
                    timedOut: false,
                    attempts: 0,
                    everSkipped: false,
                    updatedSequence: updateSequence
                )
            )
        }
    }

    private func resetSessionState() {
        baseDeck = []
        deck = []
        currentIndex = 0
        results = []
        answerText = ""
        inputError = nil
        setupError = nil
        reviewSheetOpen = false
        lastResultStatus = nil
        liveScore = 0
        timerSeconds = 0
        remainingSeconds = 0
        elapsedSeconds = 0
        perQuestionBaseSeconds = 0
        perQuestionBonusQuestions = 0
        progressLabel = "0 / 0"
        timerLabel = timerMinutes == 0 ? "Untimed" : "\(timerMinutes)m"
    }
}

private func sanitizeDisplayName(_ rawName: String?) -> String {
    let trimmed = (rawName ?? "")
        .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "'s$", with: "", options: .regularExpression)
        .replacingOccurrences(of: "'$", with: "", options: .regularExpression)
    return trimmed.isEmpty ? QuizStore.defaultDisplayName : trimmed
}

private func formatPossessiveDisplayName(_ rawName: String?) -> String {
    let cleaned = sanitizeDisplayName(rawName)
    return cleaned.hasSuffix("'s") ? cleaned : "\(cleaned)'s"
}

private func sanitizeTopicSelection(_ topicIds: [String]) -> [String] {
    let valid = Set([
        "mentalMath", "normal", "maxNormals", "discreteExtremes", "cardsSampling", "conditionalProb",
        "momentsMgf", "basicReview", "regression", "orderStats", "estimation", "fisherInfo",
        "options", "fixedIncome", "greeks", "ito", "stopping", "vol", "sharpeGraph", "ev",
        "randomWalks", "polygons", "eigenvalues", "classicPuzzles"
    ])
    return Array(Set(topicIds.filter { valid.contains($0) })).sorted()
}

private func questionFingerprint(_ question: Question) -> String {
    let visualKey: String
    if let visual = question.visual {
        let encoded = (try? JSONEncoder().encode(visual)).flatMap { String(data: $0, encoding: .utf8) }
        visualKey = encoded ?? ""
    } else {
        visualKey = ""
    }
    return [
        question.topicId,
        question.category,
        question.prompt,
        question.inputMode,
        String(format: "%.12f", question.answer),
        String(format: "%.12f", question.mentalAnswer),
        question.acceptedLower.map { String(format: "%.12f", $0) } ?? "",
        question.acceptedUpper.map { String(format: "%.12f", $0) } ?? "",
        question.customTemplateId ?? "",
        visualKey,
    ].joined(separator: "||")
}

private func annotatedBuiltInQuestion(_ question: Question) -> Question {
    var copy = question
    copy.problemKey = deriveProblemKey(copy)
    copy.runtimeFamily = nil
    return copy
}

private func buildQuestionLookup(from questionBank: [String: [Question]]) -> [String: Question] {
    questionBank.values.reduce(into: [String: Question]()) { lookup, questions in
        for question in questions {
            lookup[question.problemKey ?? deriveProblemKey(question)] = question
        }
    }
}

private func tagRuntimeFamily(_ questions: [Question], family: String) -> [Question] {
    questions.map { question in
        var copy = question
        copy.problemKey = nil
        copy.runtimeFamily = family
        return copy
    }
}

private func deriveProblemKey(_ question: Question) -> String {
    let basis = [
        question.topicId,
        question.category,
        question.prompt,
        question.inputMode,
        String(format: "%.8f", question.answer),
        String(format: "%.8f", question.mentalAnswer),
        question.acceptedLower.map { String(format: "%.8f", $0) } ?? "",
        question.acceptedUpper.map { String(format: "%.8f", $0) } ?? "",
        question.customTemplateId ?? "",
    ].joined(separator: "||")
    return "\(question.topicId):\(hashString(basis))"
}

private func hashString(_ text: String) -> String {
    var hash: UInt32 = 2166136261
    for scalar in text.unicodeScalars {
        hash ^= UInt32(scalar.value)
        hash = hash &* 16777619
    }
    return String(hash, radix: 36)
}

private func serializeVisualForRecovery(_ visual: QuestionVisual?) -> Any {
    guard let visual else { return NSNull() }
    return [
        visual.type,
        visual.title ?? "",
        visual.note ?? "",
        visual.xLabel ?? "",
        visual.yLabel ?? "",
        visual.labels ?? [],
        visual.points ?? [],
        visual.unitSuffix ?? "",
        visual.showPointValues == true ? 1 : 0,
        visual.showMarkers == true ? 1 : 0,
        visual.showVerticalGrid == true ? 1 : 0,
    ]
}

private func deserializeVisualFromRecovery(_ payload: Any) -> QuestionVisual? {
    guard let record = payload as? [Any], !record.isEmpty else { return nil }
    return QuestionVisual(
        type: record[safe: 0] as? String ?? "",
        title: (record[safe: 1] as? String).flatMap { $0.isEmpty ? nil : $0 },
        note: (record[safe: 2] as? String).flatMap { $0.isEmpty ? nil : $0 },
        xLabel: (record[safe: 3] as? String).flatMap { $0.isEmpty ? nil : $0 },
        yLabel: (record[safe: 4] as? String).flatMap { $0.isEmpty ? nil : $0 },
        labels: record[safe: 5] as? [String],
        points: record[safe: 6] as? [Double],
        unitSuffix: (record[safe: 7] as? String).flatMap { $0.isEmpty ? nil : $0 },
        showPointValues: ((record[safe: 8] as? Int) == 1),
        showMarkers: ((record[safe: 9] as? Int) == 1),
        showVerticalGrid: ((record[safe: 10] as? Int) == 1)
    )
}

private func serializeQuestionForRecovery(_ question: Question) -> [Any] {
    [
        question.topicId,
        question.category,
        question.prompt,
        question.hint,
        question.inputMode,
        question.formatHint,
        question.answer,
        question.mentalAnswer,
        question.absTolerance,
        question.relTolerance,
        question.explanation,
        question.workedSolution ?? "",
        question.methodExplanation ?? "",
        question.difficulty,
        question.source ?? "",
        serializeVisualForRecovery(question.visual),
        question.acceptedLower.map { $0 as Any } ?? NSNull(),
        question.acceptedUpper.map { $0 as Any } ?? NSNull(),
        question.customTemplateId ?? "",
    ]
}

private func deserializeQuestionFromRecovery(_ payload: Any) -> Question? {
    guard let record = payload as? [Any], let prompt = record[safe: 2] as? String, !prompt.isEmpty else { return nil }
    return Question(
        topicId: record[safe: 0] as? String ?? "",
        category: record[safe: 1] as? String ?? "",
        prompt: prompt,
        hint: record[safe: 3] as? String ?? "",
        inputMode: record[safe: 4] as? String ?? "number",
        formatHint: record[safe: 5] as? String ?? "",
        answer: record[safe: 6] as? Double ?? 0,
        mentalAnswer: record[safe: 7] as? Double ?? 0,
        absTolerance: record[safe: 8] as? Double ?? 0,
        relTolerance: record[safe: 9] as? Double ?? 0,
        explanation: record[safe: 10] as? String ?? "",
        workedSolution: (record[safe: 11] as? String).flatMap { $0.isEmpty ? nil : $0 },
        methodExplanation: (record[safe: 12] as? String).flatMap { $0.isEmpty ? nil : $0 },
        difficulty: record[safe: 13] as? String ?? "easy",
        source: (record[safe: 14] as? String).flatMap { $0.isEmpty ? nil : $0 },
        visual: deserializeVisualFromRecovery(record[safe: 15] ?? NSNull()),
        acceptedLower: record[safe: 16] as? Double,
        acceptedUpper: record[safe: 17] as? Double,
        customTemplateId: (record[safe: 18] as? String).flatMap { $0.isEmpty ? nil : $0 }
    )
}

private func serializeCustomTemplateForRecovery(_ template: CustomQuestionTemplate) -> [Any] {
    [
        template.id,
        template.createdAt.timeIntervalSince1970 * 1000,
        template.topicId,
        template.promptTemplate,
        template.hintTemplate ?? "",
        template.solutionTemplate ?? "",
        template.lowerExpression,
        template.upperExpression,
        template.variableSpecText,
        template.randomized ? 1 : 0,
        template.difficulty,
        template.inputMode,
    ]
}

private func deserializeCustomTemplateFromRecovery(_ payload: Any) -> CustomQuestionTemplate? {
    guard let record = payload as? [Any], let id = record[safe: 0] as? String else { return nil }
    let timestampMillis = record[safe: 1] as? Double ?? Date().timeIntervalSince1970 * 1000
    let extended = record.count >= 12
    return CustomQuestionTemplate(
        id: id,
        createdAt: Date(timeIntervalSince1970: timestampMillis / 1000),
        topicId: record[safe: 2] as? String ?? "",
        promptTemplate: record[safe: 3] as? String ?? "",
        hintTemplate: extended ? (record[safe: 4] as? String).flatMap { $0.isEmpty ? nil : $0 } : nil,
        solutionTemplate: extended ? (record[safe: 5] as? String).flatMap { $0.isEmpty ? nil : $0 } : nil,
        lowerExpression: record[safe: extended ? 6 : 4] as? String ?? "",
        upperExpression: record[safe: extended ? 7 : 5] as? String ?? "",
        variableSpecText: record[safe: extended ? 8 : 6] as? String ?? "",
        randomized: ((record[safe: extended ? 9 : 7] as? Int) == 1),
        difficulty: record[safe: extended ? 10 : 8] as? String ?? "easy",
        inputMode: record[safe: extended ? 11 : 9] as? String ?? "number"
    )
}

private func serializeCustomLearningTopicForRecovery(_ topic: CustomLearningTopic) -> [Any] {
    [
        topic.id,
        topic.createdAt.timeIntervalSince1970 * 1000,
        topic.title,
        topic.body,
    ]
}

private func deserializeCustomLearningTopicFromRecovery(_ payload: Any) -> CustomLearningTopic? {
    guard let record = payload as? [Any], let id = record[safe: 0] as? String else { return nil }
    let timestampMillis = record[safe: 1] as? Double ?? Date().timeIntervalSince1970 * 1000
    let title = sanitizeCustomLearningTopicTitle(record[safe: 2] as? String)
    let body = sanitizeCustomLearningTopicBody(record[safe: 3] as? String)
    guard !title.isEmpty, !body.isEmpty else { return nil }
    return CustomLearningTopic(
        id: id,
        createdAt: Date(timeIntervalSince1970: timestampMillis / 1000),
        title: title,
        body: body
    )
}

private func serializePersonalDeckRefForRecovery(_ question: Question) -> [Any] {
    if question.source == "custom-template" {
        return ["q", serializeQuestionForRecovery(question)]
    }
    if let runtimeFamily = question.runtimeFamily {
        return ["g", runtimeFamily, question.topicId, question.category, question.difficulty]
    }
    return ["b", question.problemKey ?? deriveProblemKey(question)]
}

private func deserializePersonalDeckRefFromRecovery(_ payload: Any, store: QuizStore) -> Question? {
    guard let record = payload as? [Any], let type = record[safe: 0] as? String else { return nil }
    if type == "q" {
        return deserializeQuestionFromRecovery(record[safe: 1] ?? NSNull())
    }
    if type == "b", let key = record[safe: 1] as? String {
        return store.questionForBuiltInProblemKey(key)
    }
    if type == "g", let family = record[safe: 1] as? String {
        let topicId = record[safe: 2] as? String ?? ""
        let category = record[safe: 3] as? String ?? ""
        let difficultyRaw = record[safe: 4] as? String ?? DifficultyFilter.all.rawValue
        let generated = store.buildRuntimeQuestionsForFamily(family, count: 8, difficulty: .all)
        let filtered = generated.filter { question in
            if !topicId.isEmpty && question.topicId != topicId { return false }
            if !category.isEmpty && question.category != category { return false }
            if difficultyRaw == "freddybean" { return isFreddybeanQuestion(question) }
            if difficultyRaw != DifficultyFilter.all.rawValue && question.difficulty != difficultyRaw { return false }
            return true
        }
        return (filtered.isEmpty ? generated : filtered).first
    }
    return nil
}

private func serializeTopicStatForRecovery(_ stat: TopicSessionStat) -> [Any] {
    [stat.id, stat.correct, stat.wrong, stat.skipped, stat.score]
}

private func deserializeTopicStatFromRecovery(_ payload: Any) -> TopicSessionStat? {
    guard let record = payload as? [Any] else { return nil }
    return TopicSessionStat(
        id: record[safe: 0] as? String ?? "",
        correct: record[safe: 1] as? Int ?? 0,
        wrong: record[safe: 2] as? Int ?? 0,
        skipped: record[safe: 3] as? Int ?? 0,
        score: record[safe: 4] as? Int ?? 0
    )
}

private func serializeHistoryEntryForRecovery(_ entry: QuizHistoryEntry) -> [Any] {
    [
        entry.id,
        entry.timestamp.timeIntervalSince1970 * 1000,
        entry.selectedTopicIds,
        entry.difficulty,
        entry.questionCount,
        Double(entry.timerMinutes),
        entry.intenseTimer == true ? 1 : 0,
        entry.elapsedSeconds,
        entry.score,
        entry.correct,
        entry.wrong,
        entry.skipped,
        entry.topicStats.map(serializeTopicStatForRecovery),
        entry.showHints == true ? 1 : 0,
        entry.personalDeckOnly == true ? 1 : 0,
        entry.customCardsOnly == true ? 1 : 0,
    ]
}

private func deserializeHistoryEntryFromRecovery(_ payload: Any) -> QuizHistoryEntry? {
    guard let record = payload as? [Any] else { return nil }
    let timestampMillis = record[safe: 1] as? Double ?? 0
    return QuizHistoryEntry(
        id: record[safe: 0] as? String ?? UUID().uuidString,
        timestamp: Date(timeIntervalSince1970: timestampMillis / 1000),
        selectedTopicIds: sanitizeTopicSelection(record[safe: 2] as? [String] ?? []),
        difficulty: record[safe: 3] as? String ?? DifficultyFilter.all.rawValue,
        questionCount: max(5, min(100, record[safe: 4] as? Int ?? 20)),
        timerMinutes: max(0, min(100, Int((record[safe: 5] as? Double ?? 0).rounded()))),
        intenseTimer: ((record[safe: 6] as? Int) == 1),
        showHints: record.indices.contains(13) ? (((record[safe: 13] as? Int) == 1)) : nil,
        personalDeckOnly: record.indices.contains(14) ? (((record[safe: 14] as? Int) == 1)) : nil,
        customCardsOnly: record.indices.contains(15) ? (((record[safe: 15] as? Int) == 1)) : nil,
        elapsedSeconds: record[safe: 7] as? Int ?? 0,
        score: record[safe: 8] as? Int ?? 0,
        correct: record[safe: 9] as? Int ?? 0,
        wrong: record[safe: 10] as? Int ?? 0,
        skipped: record[safe: 11] as? Int ?? 0,
        topicStats: (record[safe: 12] as? [Any] ?? []).compactMap(deserializeTopicStatFromRecovery)
    )
}

private func isFreddybeanQuestion(_ question: Question) -> Bool {
    let easyTopics: Set<String> = [
        "mentalMath",
        "normal",
        "cardsSampling",
        "conditionalProb",
        "basicReview",
        "fixedIncome",
        "ev",
        "vol",
        "sharpeGraph",
    ]
    return question.difficulty == "easy" && easyTopics.contains(question.topicId)
}

private func sanitizeCustomLearningTopicTitle(_ raw: String?) -> String {
    String(raw ?? "")
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .replacingOccurrences(of: "\n", with: " ")
        .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func sanitizeCustomLearningTopicBody(_ raw: String?) -> String {
    String(raw ?? "")
        .replacingOccurrences(of: "\r\n", with: "\n")
        .replacingOccurrences(of: "\r", with: "\n")
        .trimmingCharacters(in: .whitespacesAndNewlines)
}

private func normalizeCustomLearningTopics(_ topics: [CustomLearningTopic]) -> [CustomLearningTopic] {
    var seen = Set<String>()
    return topics.compactMap { topic in
        let title = sanitizeCustomLearningTopicTitle(topic.title)
        let body = sanitizeCustomLearningTopicBody(topic.body)
        guard !title.isEmpty, !body.isEmpty else { return nil }
        let id = topic.id.isEmpty ? UUID().uuidString : topic.id
        guard seen.insert(id).inserted else { return nil }
        return CustomLearningTopic(id: id, createdAt: topic.createdAt, title: title, body: body)
    }
    .sorted { $0.createdAt > $1.createdAt }
    .prefix(200)
    .map { $0 }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

private func iso8601String(from date: Date) -> String {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.string(from: date)
}

private func iso8601Date(from text: String) -> Date? {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    if let precise = formatter.date(from: text) {
        return precise
    }
    formatter.formatOptions = [.withInternetDateTime]
    return formatter.date(from: text)
}

private func base64URLEncode(_ data: Data) -> String {
    data.base64EncodedString()
        .replacingOccurrences(of: "+", with: "-")
        .replacingOccurrences(of: "/", with: "_")
        .replacingOccurrences(of: "=", with: "")
}

private func base64URLDecode(_ text: String) throws -> Data {
    let base64 = text
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let pad = (4 - (base64.count % 4 == 0 ? 4 : base64.count % 4)) % 4
    let padded = base64 + String(repeating: "=", count: pad)
    guard let data = Data(base64Encoded: padded) else {
        throw NSError(domain: "SignalDeck", code: 2, userInfo: [NSLocalizedDescriptionKey: "That recovery code could not be decoded."])
    }
    return data
}

private enum TokenType: Equatable {
    case number(Double)
    case identifier(String)
    case plus
    case minus
    case star
    case slash
    case caret
    case leftParen
    case rightParen
}

private struct ExpressionParser {
    private let tokens: [TokenType]
    private let variables: [String: Double]
    private var position = 0

    init?(_ text: String, variables: [String: Double] = [:]) {
        let normalized = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "")
            .lowercased()
        guard !normalized.isEmpty else { return nil }
        var out: [TokenType] = []
        var idx = normalized.startIndex
        while idx < normalized.endIndex {
            let ch = normalized[idx]
            if ch.isNumber || ch == "." {
                var end = normalized.index(after: idx)
                while end < normalized.endIndex && (normalized[end].isNumber || normalized[end] == ".") {
                    end = normalized.index(after: end)
                }
                guard let v = Double(normalized[idx..<end]) else { return nil }
                out.append(.number(v))
                idx = end
                continue
            }
            if ch.isLetter {
                var end = normalized.index(after: idx)
                while end < normalized.endIndex && (normalized[end].isLetter || normalized[end].isNumber) {
                    end = normalized.index(after: end)
                }
                let name = String(normalized[idx..<end])
                out.append(.identifier(name))
                idx = end
                continue
            }
            switch ch {
            case "+": out.append(.plus)
            case "-": out.append(.minus)
            case "*": out.append(.star)
            case "/": out.append(.slash)
            case "^": out.append(.caret)
            case "(": out.append(.leftParen)
            case ")": out.append(.rightParen)
            default: return nil
            }
            idx = normalized.index(after: idx)
        }
        tokens = out
        self.variables = variables
    }

    mutating func parse() -> Double? {
        guard let value = parseExpression(), position == tokens.count, value.isFinite else { return nil }
        return value
    }

    private func peek() -> TokenType? { position < tokens.count ? tokens[position] : nil }

    private mutating func consume(_ token: TokenType) -> Bool {
        guard peek() == token else { return false }
        position += 1
        return true
    }

    private mutating func parseExpression() -> Double? {
        guard var value = parseTerm() else { return nil }
        while true {
            if consume(.plus) {
                guard let rhs = parseTerm() else { return nil }
                value += rhs
            } else if consume(.minus) {
                guard let rhs = parseTerm() else { return nil }
                value -= rhs
            } else {
                return value
            }
        }
    }

    private mutating func parseTerm() -> Double? {
        guard var value = parsePower() else { return nil }
        while true {
            if consume(.star) {
                guard let rhs = parsePower() else { return nil }
                value *= rhs
            } else if consume(.slash) {
                guard let rhs = parsePower(), rhs != 0 else { return nil }
                value /= rhs
            } else {
                return value
            }
        }
    }

    private mutating func parsePower() -> Double? {
        guard var value = parseUnary() else { return nil }
        if consume(.caret) {
            guard let exponent = parsePower() else { return nil }
            value = pow(value, exponent)
        }
        return value
    }

    private mutating func parseUnary() -> Double? {
        if consume(.plus) { return parseUnary() }
        if consume(.minus) { return parseUnary().map(-) }
        if let token = peek() {
            switch token {
            case .identifier(let name):
                position += 1
                if name == "pi" { return Double.pi }
                if name == "e" { return M_E }
                if name == "sqrt" {
                    let hadParen = consume(.leftParen)
                    guard let inner = parseExpression(), inner >= 0 else { return nil }
                    if hadParen, !consume(.rightParen) { return nil }
                    return sqrt(inner)
                }
                if let value = variables[name] {
                    return value
                }
            case .number(let value):
                position += 1
                return value
            case .leftParen:
                position += 1
                guard let inner = parseExpression(), consume(.rightParen) else { return nil }
                return inner
            default:
                break
            }
        }
        return nil
    }
}

private func parseAnswer(rawInput: String, inputMode: String) -> Double? {
    let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
    guard !trimmed.isEmpty else { return nil }
    let hasPercent = trimmed.hasSuffix("%")
    let numericText = hasPercent ? String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines) : trimmed
    guard var parser = ExpressionParser(numericText), let value = parser.parse(), value.isFinite else { return nil }
    if inputMode == "probability" {
        return (hasPercent || abs(value) > 1) ? value / 100 : value
    }
    if inputMode == "percent" {
        return hasPercent ? value : (abs(value) < 1 ? value * 100 : value)
    }
    return value
}

private func parseAnswerCandidates(rawInput: String, inputMode: String) -> [Double] {
    let trimmed = rawInput.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "")
    guard !trimmed.isEmpty else { return [] }
    let hasPercent = trimmed.hasSuffix("%")
    let numericText = hasPercent ? String(trimmed.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines) : trimmed
    guard var parser = ExpressionParser(numericText), let value = parser.parse(), value.isFinite else { return [] }
    if inputMode == "probability" {
        return [(hasPercent || abs(value) > 1) ? value / 100 : value]
    }
    if inputMode == "percent" {
        var values: [Double] = []
        if hasPercent {
            values.append(value)
        } else {
            values.append(abs(value) < 1 ? value * 100 : value)
            if abs(value) <= 2 {
                values.append(value * 100)
            }
        }
        var unique: [Double] = []
        for candidate in values where !unique.contains(where: { abs($0 - candidate) < 1e-9 }) {
            unique.append(candidate)
        }
        return unique
    }
    return [value]
}

private func computeTolerance(question: Question) -> Double {
    max(question.absTolerance, abs(question.answer) * question.relTolerance)
}

private func referenceAnswers(question: Question) -> [Double] {
    Array(Set([question.answer, question.mentalAnswer].filter(\.isFinite))).sorted()
}

private func acceptedBounds(question: Question) -> (Double, Double) {
    if let explicitLower = question.acceptedLower, let explicitUpper = question.acceptedUpper, explicitLower.isFinite, explicitUpper.isFinite {
        let lower = min(explicitLower, explicitUpper)
        let upper = max(explicitLower, explicitUpper)
        if question.inputMode == "probability" {
            return (max(0, lower), min(1, upper))
        }
        return (lower, upper)
    }
    let tolerance = computeTolerance(question: question)
    let refs = referenceAnswers(question: question)
    let lowerRaw = (refs.min() ?? question.answer) - tolerance
    let upperRaw = (refs.max() ?? question.answer) + tolerance
    if question.inputMode == "probability" {
        return (max(0, lowerRaw), min(1, upperRaw))
    }
    return (lowerRaw, upperRaw)
}

private func isApproxCorrect(question: Question, parsedAnswer: Double, rawInput: String = "") -> Bool {
    let (lower, upper) = acceptedBounds(question: question)
    let candidates = rawInput.isEmpty ? [parsedAnswer] : parseAnswerCandidates(rawInput: rawInput, inputMode: question.inputMode)
    return candidates.contains { candidate in
        candidate.isFinite && candidate >= lower && candidate <= upper
    }
}

private func acceptedRangeString(question: Question) -> String {
    let (lower, upper) = acceptedBounds(question: question)
    if question.inputMode == "probability" {
        return "\(formatNumber(lower, decimals: 4)) to \(formatNumber(upper, decimals: 4)) (\(formatPercent(lower)) to \(formatPercent(upper)))"
    }
    if question.inputMode == "percent" {
        return "\(formatNumber(lower, decimals: 3))% to \(formatNumber(upper, decimals: 3))%"
    }
    return "\(formatNumber(lower, decimals: 4)) to \(formatNumber(upper, decimals: 4))"
}

private func formatSingleAnswer(question: Question, value: Double) -> String {
    if question.inputMode == "probability" {
        return "\(formatNumber(value, decimals: 4)) (\(formatPercent(value)))"
    }
    if question.inputMode == "percent" {
        return "\(formatNumber(value, decimals: 3))%"
    }
    return formatNumber(value, decimals: 4)
}

private func customFormatHint(for inputMode: String) -> String {
    switch inputMode {
    case "probability": return "probability"
    case "percent": return "percent"
    case "count": return "count"
    case "variance": return "variance"
    case "correlation": return "correlation"
    case "dollars": return "dollar value"
    default: return "estimate"
    }
}

private func formatSingleCustomAnswer(value: Double, inputMode: String) -> String {
    if inputMode == "probability" {
        return "\(formatNumber(value, decimals: 4)) (\(formatPercent(value)))"
    }
    if inputMode == "percent" {
        return "\(formatNumber(value, decimals: 3))%"
    }
    return formatNumber(value, decimals: 4)
}

private func formatPercent(_ value: Double) -> String {
    "\(formatNumber(value * 100, decimals: 1))%"
}

private func ensureSentence(_ text: String) -> String {
    let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !clean.isEmpty else { return "" }
    if let last = clean.last, ".!?".contains(last) {
        return clean
    }
    return clean + "."
}

private struct VariableDefinition {
    let name: String
    let description: String
}

private func extractVariableDefinitions(from prompt: String) -> [VariableDefinition] {
    if let regex = try? NSRegularExpression(pattern: #"Let ([A-Za-z][A-Za-z0-9_]*) be (.+?) and ([A-Za-z][A-Za-z0-9_]*) be (.+?)(?:\.| Estimate|$)"#),
       let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)),
       let r1 = Range(match.range(at: 1), in: prompt),
       let r2 = Range(match.range(at: 2), in: prompt),
       let r3 = Range(match.range(at: 3), in: prompt),
       let r4 = Range(match.range(at: 4), in: prompt) {
        return [
            VariableDefinition(name: String(prompt[r1]), description: String(prompt[r2]).trimmingCharacters(in: .whitespacesAndNewlines)),
            VariableDefinition(name: String(prompt[r3]), description: String(prompt[r4]).trimmingCharacters(in: .whitespacesAndNewlines)),
        ]
    }
    if let regex = try? NSRegularExpression(pattern: #"Let ([A-Za-z][A-Za-z0-9_]*) be (.+?)(?:\.| Estimate|$)"#),
       let match = regex.firstMatch(in: prompt, range: NSRange(prompt.startIndex..., in: prompt)),
       let r1 = Range(match.range(at: 1), in: prompt),
       let r2 = Range(match.range(at: 2), in: prompt) {
        return [
            VariableDefinition(name: String(prompt[r1]), description: String(prompt[r2]).trimmingCharacters(in: .whitespacesAndNewlines))
        ]
    }
    return []
}

private func describeCardTarget(_ question: Question) -> String {
    let named = extractVariableDefinitions(from: question.prompt)
    let category = question.category.lowercased()
    if category.contains("correlation") {
        if named.count >= 2 { return "the correlation between \(named[0].name) and \(named[1].name)" }
        return "the requested correlation"
    }
    if category.contains("covariance") {
        if named.count >= 2 { return "the covariance between \(named[0].name) and \(named[1].name)" }
        return "the requested covariance"
    }
    if category.contains("variance") {
        if let first = named.first { return "the variance of \(first.name)" }
        return "the requested variance"
    }
    switch question.inputMode {
    case "probability": return "the requested probability"
    case "percent": return "the requested percentage"
    case "correlation": return "the requested correlation"
    case "variance": return "the requested variance"
    case "count": return "the requested count"
    case "steps": return "the requested expected waiting time or step count"
    case "dollars": return "the requested dollar value"
    default:
        if !question.formatHint.isEmpty { return "the \(question.formatHint)" }
        return "the final numeric answer"
    }
}

func readableHint(for question: Question?) -> String {
    guard let question else { return "" }
    if question.source == "custom-template" {
        return question.hint
    }
    switch question.topicId {
    case "maxNormals":
        return readableMaxNormalsHint(for: question)
    case "discreteExtremes":
        return readableDiscreteExtremesHint(for: question)
    case "momentsMgf":
        return readableMomentsHint(for: question)
    case "basicReview":
        return "Write down the closed-form formula for the requested mean, variance, or raw moment, check that the moment exists, and then substitute the parameter values from the prompt."
    case "fisherInfo":
        return "First decide which quantity the card wants: one-observation information, total information for n iid observations, the Cramer-Rao lower bound 1 / I_n, or the large-sample MLE standard-error scale 1 / sqrt(I_n). Then plug in the standard formula for the family in the prompt."
    case "ito":
        if question.prompt.contains("ln") {
            return "Set X = ln S. Ito's lemma gives dX = (mu - sigma^2 / 2) dt + sigma dW, so the drift is mu - sigma^2 / 2 and the diffusion coefficient is sigma."
        }
        return "Rewrite the transformed process as X = f(S). If the transform is a power, write X = S^k. Then apply Ito's lemma; for X = S^k, the quick rule is dX/X = (k mu + 0.5 k(k-1) sigma^2) dt + k sigma dW. If the card asks for volatility magnitude, report |k| sigma rather than the signed diffusion coefficient."
    case "orderStats":
        return readableOrderStatsHint(for: question)
    case "options":
        return readableOptionsHint(for: question)
    case "classicPuzzles":
        return readableClassicPuzzleHint(for: question)
    default:
        let base = ensureSentence(question.hint)
        if base.isEmpty {
            return "Start from the standard identity for this family, substitute the numbers from the prompt, and simplify all the way to the final numerical answer."
        }
        return base
    }
}

private func readableMomentsHint(for question: Question) -> String {
    let named = extractVariableDefinitions(from: question.prompt)
    switch question.category {
    case "Covariance":
        if named.count >= 2 {
            return "Let \(named[0].name) be \(named[0].description), and let \(named[1].name) be \(named[1].description). Work one trial at a time with indicator variables or one-die contributions, compute the covariance on a single trial, and then add over independent trials."
        }
        return "Define the two random variables clearly, compute their covariance on one trial, and then add over independent trials."
    case "Correlation":
        if named.count >= 2 {
            return "Let \(named[0].name) be \(named[0].description), and let \(named[1].name) be \(named[1].description). First compute Cov(\(named[0].name), \(named[1].name)), then divide by sqrt(Var(\(named[0].name)) Var(\(named[1].name)))."
        }
        return "Compute the covariance first, then divide by the product of the two standard deviations."
    case "Variance":
        if let first = named.first {
            return "Let \(first.name) be \(first.description). Identify the one-trial contribution, compute its variance, and then add variances across independent trials; for a binomial count this becomes np(1-p)."
        }
        return "Treat the variable as a sum of independent one-trial pieces and add the variances."
    default:
        return ensureSentence(question.hint)
    }
}

private func readableMaxNormalsHint(for question: Question) -> String {
    "Write M_n = max(Z_1, ..., Z_n). Then P(M_n <= x) = Phi(x)^n. A good first anchor is the level x where one exceedance is expected among the n draws, meaning n P(Z > x) is about 1, or equivalently P(Z > x) is about 1/n. That x is only the location anchor; the mean sits a bit above it because values above the cutoff still contribute to the average."
}

private func readableDiscreteExtremesHint(for question: Question) -> String {
    switch question.category {
    case "Geometric max":
        return "For one geometric variable, P(G >= k) = (1-p)^(k-1). For the maximum of n iid copies, look for the cutoff k where n P(G >= k) is about 1. That identifies the level where the maximum typically starts to appear."
    case "Geometric min":
        return "Let H = min(G_1, ..., G_n). Then P(H >= k) = P(G >= k)^n = ((1-p)^(k-1))^n, so H is itself geometric with success probability 1 - (1-p)^n. Once you identify that effective success probability, the mean is 1 divided by it."
    default:
        return ensureSentence(question.hint)
    }
}

private func readableOrderStatsHint(for question: Question) -> String {
    if question.prompt.contains("independent Exponential(rate") {
        return "Sort the sample as X_(1) < ... < X_(n). For exponential samples, X_(1) has mean 1/(n lambda), the next gap has mean 1/((n-1) lambda), and so on down to 1/lambda. Add the expected gaps needed to reach the requested order statistic."
    }
    return ensureSentence(question.hint)
}

private func readableOptionsHint(for question: Question) -> String {
    if question.category == "ATM option estimate" {
        return "For an at-the-money European call with short or moderate maturity, use C ≈ S sigma sqrt(T) / sqrt(2 pi) ≈ 0.4 S sigma sqrt(T). If the prompt is about an at-the-money straddle, double the call estimate and use about 0.8 S sigma sqrt(T)."
    }
    return ensureSentence(question.hint)
}

private func readableClassicPuzzleHint(for question: Question) -> String {
    if question.category == "Classic puzzle: derangements" {
        return "Use inclusion-exclusion: P(no fixed points) = sum_{k=0}^n (-1)^k / k!. For moderate n, this alternating sum is already very close to 1/e, but the exact finite-n answer is the truncated sum through k = n."
    }
    return ensureSentence(question.hint)
}

func readableWorkedSolution(for question: Question) -> String {
    if question.source == "custom-template", let worked = question.workedSolution, !worked.isEmpty {
        return worked
    }
    switch question.topicId {
    case "momentsMgf":
        return readableMomentsWorkedSolution(for: question)
    case "orderStats" where question.prompt.contains("independent Exponential(rate"):
        return readableExponentialOrderStatsWorkedSolution(for: question)
    case "basicReview":
        return [
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).",
            question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")
    case "fisherInfo":
        return [
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).",
            question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")
    case "ito":
        return readableItoWorkedSolution(for: question)
    case "options" where question.category == "ATM option estimate":
        return readableATMOptionWorkedSolution(for: question)
    case "classicPuzzles" where question.category == "Classic puzzle: derangements":
        return readableDerangementWorkedSolution(for: question)
    default:
        let methodLead = (question.methodExplanation ?? "").components(separatedBy: "\n\n").first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return [
            !question.explanation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? ensureSentence(question.explanation) : ensureSentence(methodLead),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).",
            question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}

private func readableMomentsWorkedSolution(for question: Question) -> String {
    let named = extractVariableDefinitions(from: question.prompt)
    switch question.category {
    case "Covariance":
        let setup: String
        if named.count >= 2 {
            setup = "Let \(named[0].name) be \(named[0].description), and let \(named[1].name) be \(named[1].description). Write the full variables as sums of one-trial contributions, so only same-trial pairs can contribute to the covariance."
        } else {
            setup = "Write each random variable as a sum of one-trial contributions. Because different trials are independent, only same-trial pairs contribute to the covariance."
        }
        return [setup, ensureSentence(question.explanation), "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).", question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""].filter { !$0.isEmpty }.joined(separator: "\n\n")
    case "Correlation":
        let setup: String
        if named.count >= 2 {
            setup = "Let \(named[0].name) be \(named[0].description), and let \(named[1].name) be \(named[1].description). Correlation is covariance divided by sqrt(Var(\(named[0].name)) Var(\(named[1].name))), so first compute or recall the covariance and both variances."
        } else {
            setup = "Correlation is covariance divided by the product of the two standard deviations. So first compute the covariance, then compute the two variances, and only then normalize."
        }
        return [setup, ensureSentence(question.explanation), "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).", question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""].filter { !$0.isEmpty }.joined(separator: "\n\n")
    case "Variance":
        let setup: String
        if let first = named.first {
            setup = "Let \(first.name) be \(first.description). View \(first.name) as a sum of one-trial random variables. Independent trials make variances add, and for a binomial count the variance is np(1-p)."
        } else {
            setup = "View the target variable as a sum of one-trial random variables. Independent trials make variances add, so the whole problem reduces to the one-trial variance."
        }
        return [setup, ensureSentence(question.explanation), "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).", question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""].filter { !$0.isEmpty }.joined(separator: "\n\n")
    default:
        return [ensureSentence(question.explanation), "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).", question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }
}

private func readableExponentialOrderStatsWorkedSolution(for question: Question) -> String {
    guard
        let regex = try? NSRegularExpression(pattern: #"You draw (\d+) independent Exponential\(rate ([0-9.]+)\) variables\. Estimate the expected ([a-z-]+) draw\."#, options: [.caseInsensitive]),
        let match = regex.firstMatch(in: question.prompt, range: NSRange(question.prompt.startIndex..., in: question.prompt)),
        let drawsRange = Range(match.range(at: 1), in: question.prompt),
        let rateRange = Range(match.range(at: 2), in: question.prompt),
        let rankRange = Range(match.range(at: 3), in: question.prompt),
        let draws = Int(question.prompt[drawsRange]),
        let rate = Double(question.prompt[rateRange])
    else {
        return [
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer))."
        ].joined(separator: "\n\n")
    }

    let rankText = String(question.prompt[rankRange]).lowercased()
    let rankMap = ["largest": 1, "second-largest": 2, "third-largest": 3, "fourth-largest": 4]
    guard let rankFromTop = rankMap[rankText] else {
        return ensureSentence(question.explanation)
    }

    let terms = (rankFromTop...draws).map { "1/\($0)" }.joined(separator: " + ")
    let harmonicValue = (rankFromTop...draws).reduce(0.0) { $0 + 1.0 / Double($1) }
    let orderIndex = draws - rankFromTop + 1
    let shortcut = question.mentalAnswer != question.answer ? "For fast mental math, replace H_\(draws) by ln(\(draws)) + γ when you only need a rough anchor. On this card, the intended shortcut answer is \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""

    return [
        "Write the sorted sample as X_(1) < X_(2) < ... < X_(\(draws)). For exponential samples with rate \(formatNumber(rate, decimals: 4)), the gaps are independent: X_(1) has mean 1/(\(draws) × \(formatNumber(rate, decimals: 4))), X_(2)-X_(1) has mean 1/((\(draws - 1)) × \(formatNumber(rate, decimals: 4))), and in general X_(j)-X_(j-1) has mean 1/((\(draws) - j + 1) × \(formatNumber(rate, decimals: 4))).",
        "The \(rankText) draw is X_(\(orderIndex)), so its expectation is the sum of the first \(orderIndex) gap means. The bracketed harmonic piece is \(terms) = \(formatNumber(harmonicValue, decimals: 6)).",
        "Now divide by the rate: E[X_(\(orderIndex))] = (1/\(formatNumber(rate, decimals: 4))) × \(formatNumber(harmonicValue, decimals: 6)) = \(formatSingleAnswer(question: question, value: question.answer)).",
        shortcut
    ].filter { !$0.isEmpty }.joined(separator: "\n\n")
}

private func readableItoWorkedSolution(for question: Question) -> String {
    let mu = Double(question.prompt.matchingGroup(#"dS / S = ([0-9.]+)% dt"#) ?? "") ?? .nan
    let sigma = Double(question.prompt.matchingGroup(#"\+ ([0-9.]+)% dW"#) ?? "") ?? .nan
    let transform = question.prompt.matchingGroup(#"If X = (.+?), estimate"#) ?? ""
    let asksVol = question.category == "Ito volatility" || question.prompt.localizedCaseInsensitiveContains("volatility")

    guard mu.isFinite, sigma.isFinite else {
        return [
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).",
            question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    if transform.range(of: #"ln\(S\)|ln S"#, options: .regularExpression) != nil {
        let drift = mu - 0.5 * ((sigma * sigma) / 100.0)
        return [
            "Set X = ln(S). Ito's lemma gives dX = (mu - sigma^2/2) dt + sigma dW.",
            asksVol
                ? "Here sigma = \(formatNumber(sigma, decimals: 3))%, so the diffusion coefficient in dX is \(formatNumber(sigma, decimals: 3))%. That is exactly the volatility of X."
                : "Here mu = \(formatNumber(mu, decimals: 3))% and sigma = \(formatNumber(sigma, decimals: 3))%, so the drift is mu - sigma^2/2 = \(formatNumber(mu, decimals: 3))% - 0.5 × \(formatNumber(sigma, decimals: 3))%^2 = \(formatNumber(drift, decimals: 4))%.",
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer))."
        ].joined(separator: "\n\n")
    }

    let k: Double = {
        if let match = transform.matchingGroup(#"S\^(-?[0-9.]+)"#), let parsed = Double(match) { return parsed }
        if transform.caseInsensitiveCompare("1 / S") == .orderedSame { return -1 }
        if transform.caseInsensitiveCompare("sqrt(S)") == .orderedSame { return 0.5 }
        if transform.caseInsensitiveCompare("1 / sqrt(S)") == .orderedSame { return -0.5 }
        return .nan
    }()

    guard k.isFinite else {
        return [
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer)).",
            question.mentalAnswer != question.answer ? "If you use the intended shortcut, you get \(formatSingleAnswer(question: question, value: question.mentalAnswer))." : ""
        ].filter { !$0.isEmpty }.joined(separator: "\n\n")
    }

    let drift = (k * mu) + (0.5 * k * (k - 1) * ((sigma * sigma) / 100.0))
    let signedDiffusion = k * sigma
    let volatilityMagnitude = abs(signedDiffusion)
    return [
        "Write the transform as X = S^k with k = \(formatNumber(k, decimals: 4)). Ito's lemma then gives dX/X = (k mu + 0.5 k(k-1) sigma^2) dt + k sigma dW.",
        asksVol
            ? "Substitute k = \(formatNumber(k, decimals: 4)) and sigma = \(formatNumber(sigma, decimals: 3))%. The signed diffusion coefficient is k sigma = \(formatNumber(k, decimals: 4)) × \(formatNumber(sigma, decimals: 3))% = \(formatNumber(signedDiffusion, decimals: 4))%. Because the prompt asks for volatility magnitude, report |k sigma| = \(formatNumber(volatilityMagnitude, decimals: 4))%."
            : "Substitute k = \(formatNumber(k, decimals: 4)), mu = \(formatNumber(mu, decimals: 3))%, and sigma = \(formatNumber(sigma, decimals: 3))%. The drift becomes \(formatNumber(k, decimals: 4)) × \(formatNumber(mu, decimals: 3))% + 0.5 × \(formatNumber(k, decimals: 4)) × (\(formatNumber(k, decimals: 4)) - 1) × \(formatNumber(sigma, decimals: 3))%^2 = \(formatNumber(drift, decimals: 4))%.",
        "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer))."
    ].joined(separator: "\n\n")
}

private func readableATMOptionWorkedSolution(for question: Question) -> String {
    let spot = Double(question.prompt.matchingGroup(#"stock is at ([0-9.]+)"#) ?? "") ?? .nan
    let vol = (Double(question.prompt.matchingGroup(#"annual volatility is ([0-9.]+)%"#) ?? "") ?? .nan) / 100
    let expiry = question.prompt.matchingGroup(#"expiry is (1 trading day|1 month|3 months|6 months|1 year)"#) ?? ""
    let yearMap: [String: Double] = [
        "1 trading day": 1.0 / 252.0,
        "1 month": 1.0 / 12.0,
        "3 months": 0.25,
        "6 months": 0.5,
        "1 year": 1.0,
    ]
    let years = yearMap[expiry] ?? .nan
    let multiplier = question.prompt.contains("straddle") ? 0.8 : 0.4

    guard spot.isFinite, vol.isFinite, years.isFinite else {
        return [
            "Use the at-the-money Black-Scholes mental scale.",
            ensureSentence(question.explanation),
            "For this card, the final answer is \(formatSingleAnswer(question: question, value: question.answer))."
        ].joined(separator: "\n\n")
    }

    let sqrtT = sqrt(years)
    return [
        "This is an at-the-money heuristic card, so use \(formatNumber(multiplier, decimals: 4)) × S × sigma × sqrt(T). Here S = \(formatNumber(spot, decimals: 4)), sigma = \(formatNumber(vol, decimals: 4)), and T = \(formatNumber(years, decimals: 6)).",
        "Compute sqrt(T) first: sqrt(\(formatNumber(years, decimals: 6))) = \(formatNumber(sqrtT, decimals: 6)). Then the estimate is \(formatNumber(multiplier, decimals: 4)) × \(formatNumber(spot, decimals: 4)) × \(formatNumber(vol, decimals: 4)) × \(formatNumber(sqrtT, decimals: 6)) = \(formatSingleAnswer(question: question, value: question.answer)).",
        question.prompt.contains("straddle")
            ? "The 0.8 constant is just twice the at-the-money call constant 0.4, because a straddle is one call plus one put at the same strike."
            : "The 0.4 constant comes from the Black-Scholes at-the-money call scale 1/sqrt(2pi) ≈ 0.399."
    ].joined(separator: "\n\n")
}

private func readableDerangementWorkedSolution(for question: Question) -> String {
    guard let n = Int(question.prompt.matchingGroup(#"permutation of (\d+)"#) ?? "") else {
        return ensureSentence(question.explanation)
    }

    var terms: [String] = []
    for k in 0...n {
        if k == 0 {
            terms.append("1")
        } else if k == 1 {
            terms.append("-1")
        } else {
            let sign = k % 2 == 0 ? "+" : "-"
            terms.append("\(sign) 1/\(k)!")
        }
    }

    return [
        "Use inclusion-exclusion. Let A_i be the event that position i is fixed. Then the derangement probability is P(no fixed points) = 1 - sum P(A_i) + sum P(A_i ∩ A_j) - ... + (-1)^\(n) P(A_1 ∩ ... ∩ A_\(n)).",
        "For a random permutation, the probability that k specified positions are all fixed is 1/k!. So the exact probability becomes \(terms.joined(separator: " ")) = \(formatSingleAnswer(question: question, value: question.answer)).",
        "As n grows, this alternating sum converges to e^(-1) = 1/e ≈ \(formatNumber(1 / Double(M_E), decimals: 4)). That is why 1/e is the right mental anchor, but the exact finite-n answer on this card is \(formatSingleAnswer(question: question, value: question.answer))."
    ].joined(separator: "\n\n")
}

private extension String {
    func matchingGroup(_ pattern: String) -> String? {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              match.numberOfRanges > 1,
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }
}

private struct CustomTemplateFailure: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}

private let customTemplateReservedNames: Set<String> = ["sqrt", "pi", "e"]

private func extractCustomTemplateVariableNames(from promptTemplate: String) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: #"\{\{\s*([A-Za-z][A-Za-z0-9_]*)\s*\}\}"#) else { return [] }
    let nsRange = NSRange(promptTemplate.startIndex..., in: promptTemplate)
    var names: [String] = []
    for match in regex.matches(in: promptTemplate, range: nsRange) {
        guard let range = Range(match.range(at: 1), in: promptTemplate) else { continue }
        let name = String(promptTemplate[range]).lowercased()
        if !names.contains(name) {
            names.append(name)
        }
    }
    return names
}

private func extractFormulaVariableNames(from expressions: [String]) -> [String] {
    guard let regex = try? NSRegularExpression(pattern: #"[A-Za-z][A-Za-z0-9_]*"#) else { return [] }
    var names: [String] = []
    for expression in expressions {
        let normalized = normalizeMathExpressionForEvaluation(expression)
        let nsRange = NSRange(normalized.startIndex..., in: normalized)
        for match in regex.matches(in: normalized, range: nsRange) {
            guard let range = Range(match.range, in: normalized) else { continue }
            let name = String(normalized[range]).lowercased()
            if customTemplateReservedNames.contains(name) { continue }
            if !names.contains(name) {
                names.append(name)
            }
        }
    }
    return names
}

private func normalizeMathExpressionForEvaluation(_ text: String) -> String {
    var out = text
    out = out.replacingOccurrences(of: "$", with: "")
    out = out.replacingOccurrences(of: "\\left", with: "")
    out = out.replacingOccurrences(of: "\\right", with: "")
    out = out.replacingOccurrences(of: "\\cdot", with: "*")
    out = out.replacingOccurrences(of: "\\times", with: "*")
    out = out.replacingOccurrences(of: "×", with: "*")
    out = out.replacingOccurrences(of: "−", with: "-")
    out = out.replacingOccurrences(of: "–", with: "-")
    let evalMap = [
        "\\pi": "pi",
        "\\mu": "mu",
        "\\sigma": "sigma",
        "\\lambda": "lambda",
        "\\theta": "theta",
        "\\alpha": "alpha",
        "\\beta": "beta",
        "\\gamma": "gamma",
        "\\rho": "rho",
        "\\tau": "tau",
    ]
    for (from, to) in evalMap {
        out = out.replacingOccurrences(of: from, with: to)
    }
    out = rewriteLatexFractions(in: out, numeratorPrefix: "(", separator: ")/(", denominatorSuffix: ")")
    out = rewriteLatexSqrts(in: out, prefix: "sqrt(", suffix: ")")
    out = out.replacingOccurrences(of: "{", with: "(")
    out = out.replacingOccurrences(of: "}", with: ")")
    return out
}

private func renderMathText(_ text: String) -> String {
    var out = text
    out = out.replacingOccurrences(of: "$", with: "")
    out = out.replacingOccurrences(of: "\\left", with: "")
    out = out.replacingOccurrences(of: "\\right", with: "")
    let displayMap = [
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
        "\\leq": "≤",
        "\\geq": "≥",
        "\\neq": "≠",
        "\\approx": "≈",
        "\\infty": "∞",
    ]
    for (from, to) in displayMap {
        out = out.replacingOccurrences(of: from, with: to)
    }
    out = rewriteLatexFractions(in: out, numeratorPrefix: "(", separator: ")/(", denominatorSuffix: ")")
    out = rewriteLatexSqrts(in: out, prefix: "√(", suffix: ")")
    out = out.replacingOccurrences(of: "{", with: "(")
    out = out.replacingOccurrences(of: "}", with: ")")
    return out
}

private func rewriteLatexFractions(in text: String, numeratorPrefix: String, separator: String, denominatorSuffix: String) -> String {
    var output = text
    while let range = output.range(of: #"\\frac\{[^{}]*\}\{[^{}]*\}"#, options: .regularExpression) {
        let snippet = String(output[range])
        guard
            let regex = try? NSRegularExpression(pattern: #"\\frac\{([^{}]*)\}\{([^{}]*)\}"#),
            let match = regex.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)),
            let numRange = Range(match.range(at: 1), in: snippet),
            let denRange = Range(match.range(at: 2), in: snippet)
        else { break }
        let replacement = numeratorPrefix + String(snippet[numRange]) + separator + String(snippet[denRange]) + denominatorSuffix
        output.replaceSubrange(range, with: replacement)
    }
    return output
}

private func rewriteLatexSqrts(in text: String, prefix: String, suffix: String) -> String {
    var output = text
    while let range = output.range(of: #"\\sqrt\{[^{}]*\}"#, options: .regularExpression) {
        let snippet = String(output[range])
        guard
            let regex = try? NSRegularExpression(pattern: #"\\sqrt\{([^{}]*)\}"#),
            let match = regex.firstMatch(in: snippet, range: NSRange(snippet.startIndex..., in: snippet)),
            let innerRange = Range(match.range(at: 1), in: snippet)
        else { break }
        let replacement = prefix + String(snippet[innerRange]) + suffix
        output.replaceSubrange(range, with: replacement)
    }
    return output
}

private func replacePromptVariables(in promptTemplate: String, values: [String: Double]) -> String {
    var output = promptTemplate
    for (name, value) in values.sorted(by: { $0.key.count > $1.key.count }) {
        output = output.replacingOccurrences(of: "{{\(name)}}", with: formatTemplateValue(value))
        if let regex = try? NSRegularExpression(pattern: #"\{\{\s*\#(name)\s*\}\}"#) {
            let replacement = formatTemplateValue(value)
            let range = NSRange(output.startIndex..., in: output)
            output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: replacement)
        }
    }
    return output
}

private func substituteVariablesInExpression(_ expression: String, values: [String: Double]) -> String {
    var output = normalizeMathExpressionForEvaluation(expression)
    for (name, value) in values.sorted(by: { $0.key.count > $1.key.count }) {
        let escaped = NSRegularExpression.escapedPattern(for: name)
        let pattern = #"(?<![A-Za-z0-9_])\#(escaped)(?![A-Za-z0-9_])"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
        let range = NSRange(output.startIndex..., in: output)
        output = regex.stringByReplacingMatches(in: output, range: range, withTemplate: formatTemplateValue(value))
    }
    return output
}

private func formatTemplateValue(_ value: Double) -> String {
    if abs(value.rounded() - value) < 1e-9 {
        return formatNumber(value.rounded(), decimals: 0)
    }
    return formatNumber(value, decimals: 6)
}

private func parseVariableValueSpec(_ rawSpec: String) throws -> [Double] {
    let spec = rawSpec.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !spec.isEmpty else { throw CustomTemplateFailure(message: "Each variable needs a non-empty set or range.") }
    if let regex = try? NSRegularExpression(pattern: #"^\s*(-?\d+(?:\.\d+)?)\s*\.\.\s*(-?\d+(?:\.\d+)?)(?:\s+step\s+(-?\d+(?:\.\d+)?))?(?:\s+skip\s+(.+))?\s*$"#, options: [.caseInsensitive]),
       let match = regex.firstMatch(in: spec, range: NSRange(spec.startIndex..., in: spec)),
       let startRange = Range(match.range(at: 1), in: spec),
       let endRange = Range(match.range(at: 2), in: spec),
       let start = Double(spec[startRange]),
       let end = Double(spec[endRange]) {
        let explicitStep = Range(match.range(at: 3), in: spec).flatMap { Double(spec[$0]) }
        let skipPart = Range(match.range(at: 4), in: spec).map { String(spec[$0]) } ?? ""
        let stepMagnitude = explicitStep ?? (start <= end ? 1 : -1)
        guard stepMagnitude != 0 else { throw CustomTemplateFailure(message: "Range step cannot be zero.") }
        let step = start <= end ? abs(stepMagnitude) : -abs(stepMagnitude)
        let skipValues: [Double] = skipPart.isEmpty ? [] : try skipPart.split(separator: ",").map {
            guard let value = Double($0.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw CustomTemplateFailure(message: "Skip values must be numeric.")
            }
            return value
        }
        var values: [Double] = []
        var current = start
        let epsilon = 1e-9
        if step > 0 {
            while current <= end + epsilon {
                if !skipValues.contains(where: { abs($0 - current) < 1e-9 }) {
                    values.append(current)
                }
                current += step
            }
        } else {
            while current >= end - epsilon {
                if !skipValues.contains(where: { abs($0 - current) < 1e-9 }) {
                    values.append(current)
                }
                current += step
            }
        }
        guard !values.isEmpty else { throw CustomTemplateFailure(message: "That variable range produces no usable values.") }
        return values
    }

    let values = try spec.split(separator: ",").map { chunk -> Double in
        let trimmed = chunk.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(trimmed) else {
            throw CustomTemplateFailure(message: "Set values must be comma-separated numbers.")
        }
        return value
    }
    guard !values.isEmpty else { throw CustomTemplateFailure(message: "Each variable needs at least one possible value.") }
    return values
}

private func parseVariableDomains(variableSpecText: String, requiredVariableNames: [String]) throws -> [String: [Double]] {
    let normalizedRequired = Array(Set(requiredVariableNames.map { $0.lowercased() })).sorted()
    if normalizedRequired.isEmpty { return [:] }
    let lines = variableSpecText
        .split(whereSeparator: \.isNewline)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }
    var domains: [String: [Double]] = [:]
    for line in lines {
        let pieces = line.split(separator: "=", maxSplits: 1).map(String.init)
        guard pieces.count == 2 else {
            throw CustomTemplateFailure(message: "Use one variable per line in the form name = values.")
        }
        let name = pieces[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard name.range(of: #"^[A-Za-z][A-Za-z0-9_]*$"#, options: .regularExpression) != nil else {
            throw CustomTemplateFailure(message: "Variable names must start with a letter and then use letters, digits, or underscores.")
        }
        domains[name] = try parseVariableValueSpec(pieces[1])
    }
    for name in normalizedRequired where domains[name] == nil {
        throw CustomTemplateFailure(message: "Add a value line for variable \(name).")
    }
    return domains
}

func formatNumber(_ value: Double, decimals: Int) -> String {
    if !value.isFinite { return "n/a" }
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimals
    formatter.usesGroupingSeparator = false
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.\(decimals)f", value)
}

private func makeGeneratedQuestion(
    topicId: String,
    category: String,
    prompt: String,
    hint: String,
    inputMode: String,
    formatHint: String,
    answer: Double,
    mentalAnswer: Double,
    absTolerance: Double,
    relTolerance: Double = 0,
    explanation: String,
    difficulty: String,
    workedSolution: String,
    methodExplanation: String,
    visual: QuestionVisual? = nil
) -> Question {
    Question(
        topicId: topicId,
        category: category,
        prompt: prompt,
        hint: hint,
        inputMode: inputMode,
        formatHint: formatHint,
        answer: answer,
        mentalAnswer: mentalAnswer,
        absTolerance: absTolerance,
        relTolerance: relTolerance,
        explanation: explanation,
        workedSolution: workedSolution,
        methodExplanation: methodExplanation,
        difficulty: difficulty,
        source: nil,
        visual: visual
    )
}

private func randomChoice<T, R: RandomNumberGenerator>(_ items: [T], using rng: inout R) -> T {
    items.randomElement(using: &rng)!
}

private func randomBool<R: RandomNumberGenerator>(probability: Double, using rng: inout R) -> Bool {
    Double.random(in: 0..<1, using: &rng) < probability
}

private func harmonicNumberNative(_ n: Int) -> Double {
    (1...max(1, n)).reduce(0.0) { $0 + (1.0 / Double($1)) }
}

private func harmonicSquareNumberNative(_ n: Int) -> Double {
    (1...max(1, n)).reduce(0.0) { $0 + (1.0 / (Double($1) * Double($1))) }
}

private func couponCollectorExpectedNative(_ n: Int) -> Double {
    Double(n) * harmonicNumberNative(n)
}

private func couponCollectorVarianceNative(_ n: Int) -> Double {
    let dn = Double(n)
    return (dn * dn * harmonicSquareNumberNative(n)) - (dn * harmonicNumberNative(n))
}

private func couponCollectorVarianceApproximationNative(_ n: Int) -> Double {
    let dn = Double(n)
    return ((Double.pi * Double.pi) / 6.0) * dn * dn - dn * (log(dn) + 0.5)
}

private func couponCollectorIntervalValueNative(n: Int, z: Double, side: String, approximateVariance: Bool) -> Double {
    let mean = couponCollectorExpectedNative(n)
    let variance = approximateVariance ? couponCollectorVarianceApproximationNative(n) : couponCollectorVarianceNative(n)
    let sd = sqrt(max(variance, 0))
    if side == "lower" { return mean - z * sd }
    if side == "upper" { return mean + z * sd }
    return z * sd
}

private func generalizedKellyFractionNative(winProbability: Double, upReturn: Double, downReturn: Double) -> Double {
    (((winProbability * upReturn) - ((1 - winProbability) * downReturn)) / (upReturn * downReturn))
}

private func asymmetricGamblerRuinProbabilityNative(start: Int, upperBarrier: Int, rightProbability: Double) -> Double {
    let q = 1 - rightProbability
    if abs(rightProbability - q) < 1e-12 {
        return Double(start) / Double(upperBarrier)
    }
    let ratio = q / rightProbability
    return (1 - pow(ratio, Double(start))) / (1 - pow(ratio, Double(upperBarrier)))
}

private func averageNative(_ values: [Double]) -> Double {
    values.reduce(0, +) / Double(max(values.count, 1))
}

private func populationStandardDeviationNative(_ values: [Double]) -> Double {
    let mean = averageNative(values)
    return sqrt(values.reduce(0) { $0 + (($1 - mean) * ($1 - mean)) } / Double(max(values.count, 1)))
}

private func sampleStandardNormalNative<R: RandomNumberGenerator>(using rng: inout R) -> Double {
    let u1 = max(Double.random(in: 0..<1, using: &rng), 1e-12)
    let u2 = Double.random(in: 0..<1, using: &rng)
    return sqrt(-2 * log(u1)) * cos(2 * Double.pi * u2)
}

private func runtimeSharpeReturnSeries<R: RandomNumberGenerator>(cadence: String, rng: inout R) -> [Double] {
    switch cadence {
    case "daily":
        return (0..<Int.random(in: 10...14, using: &rng)).map { _ in randomChoice([-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3, 0.4, 0.5], using: &rng) }
    case "weekly":
        return (0..<Int.random(in: 8...12, using: &rng)).map { _ in randomChoice([-1.0, -0.5, 0.0, 0.5, 1.0, 1.5, 2.0], using: &rng) }
    default:
        return (0..<Int.random(in: 8...10, using: &rng)).map { _ in randomChoice([-1.0, 0.0, 1.0, 2.0, 3.0], using: &rng) }
    }
}

private func cumulativeSeries(from returns: [Double]) -> [Double] {
    var cumulative: [Double] = [0]
    for value in returns {
        cumulative.append(cumulative.last! + value)
    }
    return cumulative
}

struct LearningGuideWebView: UIViewRepresentable {
    @ObservedObject var store: QuizStore

    func makeCoordinator() -> Coordinator {
        Coordinator(store: store)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.websiteDataStore = .nonPersistent()
        configuration.userContentController.add(context.coordinator, name: "learningTopics")
        let webView = WKWebView(frame: .zero, configuration: configuration)
        let backgroundColor = UIColor(red: 0.05, green: 0.08, blue: 0.12, alpha: 1)
        webView.isOpaque = true
        webView.backgroundColor = backgroundColor
        webView.underPageBackgroundColor = backgroundColor
        webView.scrollView.backgroundColor = backgroundColor
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.automaticallyAdjustsScrollIndicatorInsets = false
        webView.scrollView.scrollIndicatorInsets = UIEdgeInsets(top: 16, left: 0, bottom: 24, right: 0)
        webView.scrollView.indicatorStyle = .white
        context.coordinator.webView = webView
        let topicsSnapshot = store.customLearningTopics
        let cacheKey = LearningGuideHTMLProvider.signature(for: topicsSnapshot)
        let cachedHTML = LearningGuideHTMLProvider.currentHTML(for: topicsSnapshot)
        let initialHTML = cachedHTML ?? learningGuidePlaceholderHTML
        context.coordinator.loadedTopicsSignature = cacheKey
        webView.loadHTMLString(initialHTML, baseURL: nil)
        LearningGuideHTMLProvider.fetch(customTopics: topicsSnapshot) { html in
            guard cachedHTML == nil || initialHTML != html else { return }
            context.coordinator.loadedTopicsSignature = cacheKey
            webView.loadHTMLString(html, baseURL: nil)
        }
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        let topicsSnapshot = store.customLearningTopics
        let signature = LearningGuideHTMLProvider.signature(for: topicsSnapshot)
        guard signature != context.coordinator.loadedTopicsSignature else { return }
        LearningGuideHTMLProvider.fetch(customTopics: topicsSnapshot) { html in
            guard signature != context.coordinator.loadedTopicsSignature else { return }
            context.coordinator.loadedTopicsSignature = signature
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: "learningTopics")
    }

    final class Coordinator: NSObject, WKScriptMessageHandler {
        let store: QuizStore
        weak var webView: WKWebView?
        var loadedTopicsSignature = ""

        init(store: QuizStore) {
            self.store = store
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == "learningTopics",
                  let body = message.body as? [String: Any],
                  (body["type"] as? String) == "replaceTopics",
                  let rawTopics = body["topics"] as? [Any]
            else {
                return
            }
            let topics = rawTopics.compactMap { payload -> CustomLearningTopic? in
                guard let record = payload as? [String: Any] else { return nil }
                let id = (record["id"] as? String).flatMap { $0.isEmpty ? nil : $0 } ?? UUID().uuidString
                let title = sanitizeCustomLearningTopicTitle(record["title"] as? String)
                let body = sanitizeCustomLearningTopicBody(record["body"] as? String)
                guard !title.isEmpty, !body.isEmpty else { return nil }
                let timestampMillis = (record["createdAt"] as? Double) ?? (record["createdAt"] as? Int).map(Double.init) ?? Date().timeIntervalSince1970 * 1000
                return CustomLearningTopic(
                    id: id,
                    createdAt: Date(timeIntervalSince1970: timestampMillis / 1000),
                    title: title,
                    body: body
                )
            }
            loadedTopicsSignature = LearningGuideHTMLProvider.signature(for: topics)
            store.replaceCustomLearningTopics(topics)
        }
    }
}

private let learningGuidePlaceholderHTML = """
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
    <style>
      html, body { margin: 0; padding: 0; min-height: 100%; background: #0d141f; color: #f3f7fb; font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif; }
      body { display: flex; align-items: center; justify-content: center; }
      .box { padding: 18px 20px; border-radius: 18px; background: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.08); color: rgba(243,247,251,0.78); }
    </style>
  </head>
  <body>
    <div class="box">Loading learning center…</div>
  </body>
</html>
"""

private enum LearningGuideHTMLProvider {
    private static var cachedHTML: String?
    private static var cachedSignature = ""
    private static var cacheGeneration = 0
    private static let lock = NSLock()

    static func signature(for customTopics: [CustomLearningTopic]) -> String {
        let payload = customTopics.map {
            [$0.id, Int(($0.createdAt.timeIntervalSince1970 * 1000).rounded()), $0.title, $0.body]
        }
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }

    static func fetch(customTopics: [CustomLearningTopic], completion: @escaping (String) -> Void) {
        let signature = signature(for: customTopics)
        lock.lock()
        if let cachedHTML, cachedSignature == signature {
            lock.unlock()
            DispatchQueue.main.async {
                completion(cachedHTML)
            }
            return
        }
        let generation = cacheGeneration
        lock.unlock()

        DispatchQueue.global(qos: .utility).async {
            let html = buildLearningGuideHTML(customTopics: customTopics) ?? learningGuidePlaceholderHTML
            lock.lock()
            if cacheGeneration == generation {
                cachedHTML = html
                cachedSignature = signature
            }
            lock.unlock()
            DispatchQueue.main.async {
                completion(html)
            }
        }
    }

    static func currentHTML(for customTopics: [CustomLearningTopic]) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return cachedSignature == signature(for: customTopics) ? cachedHTML : nil
    }

    static func invalidate() {
        lock.lock()
        cacheGeneration += 1
        cachedHTML = nil
        cachedSignature = ""
        lock.unlock()
    }
}

func prewarmLearningGuideHTML(_ completion: (() -> Void)? = nil) {
    LearningGuideHTMLProvider.fetch(customTopics: []) { _ in
        completion?()
    }
}

private func buildLearningGuideHTML(customTopics: [CustomLearningTopic]) -> String? {
    guard let url = Bundle.main.url(forResource: "LearningGuideContent", withExtension: "html"),
          let section = try? String(contentsOf: url, encoding: .utf8)
    else {
        return nil
    }

    var content = section
    content = removeAll(in: content, pattern: #"<div class="panel-heading">[\s\S]*?</div>\s*"#)
    content = removeAll(in: content, pattern: #"<div class="hero-actions">[\s\S]*?</div>\s*"#)
    content = appendAppWorkedExamples(to: content)
    let customLearningSection = customLearningTopicsWorkshopHTML(customTopics: customTopics)

    return """
    <!DOCTYPE html>
    <html lang="en">
      <head>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1.0, viewport-fit=cover" />
        <title>Learning Center</title>
        <style>
          :root {
            color-scheme: dark;
          }
          * {
            box-sizing: border-box;
          }
          html, body {
            margin: 0;
            padding: 0;
            min-height: 100%;
            background:
              radial-gradient(circle at 100% 0%, rgba(46, 140, 199, 0.22), transparent 52%),
              linear-gradient(135deg, #0d141f 0%, #051f2b 52%, #030d17 100%);
            background-attachment: fixed;
          }
          body {
            color: #f3f7fb;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "Helvetica Neue", sans-serif;
            -webkit-font-smoothing: antialiased;
            -moz-osx-font-smoothing: grayscale;
            text-rendering: optimizeLegibility;
            background: transparent;
          }
          main.page-shell {
            width: 100%;
            max-width: none;
            margin: 0;
            padding: 16px 16px 24px;
            overflow-x: clip;
          }
          .guide-screen-header {
            display: flex;
            flex-direction: column;
            gap: 8px;
            margin-bottom: 16px;
            padding: 20px;
            content-visibility: visible;
            contain: none;
            border-radius: 26px;
          }
          .guide-screen-title {
            margin: 0;
            color: #ffffff;
            font-size: 32px;
            font-weight: 700;
            line-height: 1;
            letter-spacing: -0.02em;
          }
          .guide-screen-copy {
            margin: 0;
            color: rgba(243,247,251,0.74);
            font-size: 15px;
            line-height: 1.55;
          }
          #learning-guide,
          #learning-guide * {
            box-sizing: border-box;
          }
          .learning-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 16px;
            margin: 0;
          }
          .guide-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 26px;
            box-shadow: none;
            padding: 20px;
            -webkit-backdrop-filter: none;
            backdrop-filter: none;
            content-visibility: auto;
            contain-intrinsic-size: 240px;
          }
          .guide-card h3,
          .guide-example strong,
          .guide-details summary {
            color: #ffffff;
          }
          .guide-card h3 {
            margin: 0 0 10px;
            font-size: 21px;
            line-height: 1.2;
            letter-spacing: -0.01em;
          }
          .guide-card p,
          .guide-details p {
            margin: 0 0 12px;
            color: rgba(243,247,251,0.78);
            font-size: 15px;
            line-height: 1.6;
          }
          .guide-example {
            margin-top: 12px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(73, 208, 255, 0.22);
            color: #f3f7fb;
            border-radius: 18px;
            padding: 14px 16px;
          }
          .guide-details {
            margin-top: 12px;
            padding: 12px 14px;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.06);
            border-radius: 18px;
          }
          .guide-details summary {
            cursor: pointer;
            font-size: 15px;
            line-height: 1.4;
          }
          .guide-topic-card {
            padding: 20px;
          }
          .guide-topic-summary {
            display: block;
            cursor: pointer;
            list-style: none;
          }
          .guide-topic-summary::-webkit-details-marker {
            display: none;
          }
          .guide-topic-summary::after {
            content: "+";
            float: right;
            color: #49d0ff;
            font-size: 18px;
            font-weight: 700;
          }
          .guide-topic-card[open] .guide-topic-summary::after {
            content: "−";
          }
          .guide-topic-title {
            display: block;
            padding-right: 26px;
            color: #ffffff;
            font-size: 18px;
            font-weight: 700;
            line-height: 1.35;
            letter-spacing: -0.01em;
          }
          .guide-topic-body {
            margin-top: 14px;
            contain: layout paint style;
          }
          .guide-card,
          .guide-example,
          .guide-details,
          .guide-topic-body,
          .guide-table-wrap,
          .guide-fact-grid,
          .guide-fact-card,
          .guide-fact-row,
          .guide-fact-value {
            min-width: 0;
            max-width: 100%;
          }
          .guide-fact-grid {
            display: grid;
            grid-template-columns: 1fr;
            gap: 12px;
            margin-top: 12px;
          }
          .guide-fact-card {
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.06);
            border-radius: 18px;
            padding: 14px 14px 12px;
          }
          .guide-fact-card h4 {
            margin: 0 0 10px;
            color: #ffffff;
            font-size: 15px;
            line-height: 1.35;
            letter-spacing: -0.01em;
          }
          .guide-fact-list {
            display: grid;
            gap: 8px;
          }
          .guide-fact-row {
            display: grid;
            gap: 3px;
          }
          .guide-fact-label {
            color: rgba(155, 231, 255, 0.88);
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
          }
          .guide-fact-value {
            color: rgba(243,247,251,0.84);
            font-size: 14px;
            line-height: 1.45;
            overflow-wrap: anywhere;
          }
          .guide-fact-value code {
            white-space: normal;
          }
          .guide-table-wrap {
            margin-top: 12px;
            overflow-x: visible;
            background: rgba(255,255,255,0.05);
            border: 1px solid rgba(255,255,255,0.06);
            border-radius: 18px;
            padding: 12px;
            contain: layout paint style;
          }
          .guide-table {
            width: 100%;
            min-width: 0;
            border-collapse: collapse;
            table-layout: fixed;
            font-size: 12px;
            color: rgba(243,247,251,0.9);
          }
          .guide-table th,
          .guide-table td {
            padding: 8px 8px;
            border: 1px solid rgba(255,255,255,0.08);
            vertical-align: top;
            text-align: left;
            overflow-wrap: anywhere;
            word-break: break-word;
          }
          .guide-table th {
            background: rgba(73, 208, 255, 0.12);
            color: #ffffff;
            font-weight: 700;
          }
          .guide-table code {
            white-space: normal;
            overflow-wrap: anywhere;
            word-break: break-word;
          }
          .guide-custom-builder-note {
            margin: 0 0 12px;
            color: rgba(243,247,251,0.72);
            font-size: 14px;
            line-height: 1.55;
          }
          .guide-custom-workshop {
            margin-top: 16px;
          }
          .guide-custom-builder-form {
            display: grid;
            gap: 12px;
          }
          .guide-custom-builder-label {
            display: block;
            margin: 0 0 6px;
            color: rgba(155, 231, 255, 0.88);
            font-size: 11px;
            font-weight: 700;
            letter-spacing: 0.04em;
            text-transform: uppercase;
          }
          .guide-custom-builder-input,
          .guide-custom-builder-textarea {
            width: 100%;
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 18px;
            background: rgba(255,255,255,0.05);
            color: #f3f7fb;
            padding: 13px 14px;
            font: inherit;
            box-shadow: none;
            outline: none;
          }
          .guide-custom-builder-textarea {
            min-height: 132px;
            resize: vertical;
          }
          .guide-custom-builder-input::placeholder,
          .guide-custom-builder-textarea::placeholder {
            color: rgba(243,247,251,0.42);
          }
          .guide-custom-builder-actions {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin-top: 2px;
          }
          .guide-custom-builder-button {
            appearance: none;
            border: 1px solid rgba(255,255,255,0.08);
            border-radius: 18px;
            background: rgba(255,255,255,0.05);
            color: #ffffff;
            padding: 12px 16px;
            font: inherit;
            font-weight: 700;
            cursor: pointer;
          }
          .guide-custom-builder-button--primary {
            background: linear-gradient(135deg, rgba(73,208,255,0.28), rgba(43,154,223,0.24));
            border-color: rgba(73,208,255,0.26);
          }
          .guide-custom-builder-status {
            min-height: 20px;
            margin: 0;
            color: rgba(155, 231, 255, 0.88);
            font-size: 13px;
            line-height: 1.45;
          }
          .guide-custom-builder-status.is-error {
            color: #ff8d9b;
          }
          .guide-custom-topic-list {
            display: grid;
            gap: 16px;
            margin-top: 16px;
          }
          .guide-custom-topic-empty {
            margin: 0;
            color: rgba(243,247,251,0.72);
            font-size: 14px;
            line-height: 1.55;
          }
          .guide-custom-topic-article {
            padding: 20px;
          }
          .guide-custom-topic-title {
            margin: 0 0 10px;
            color: #ffffff;
            font-size: 18px;
            line-height: 1.25;
            letter-spacing: -0.01em;
          }
          .guide-custom-topic-copy p:last-child {
            margin-bottom: 0;
          }
          code {
            background: rgba(255,255,255,0.08);
            color: #9be7ff;
            padding: 0.1rem 0.35rem;
            border-radius: 6px;
            font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace;
            font-size: 0.95em;
            white-space: normal;
            overflow-wrap: anywhere;
            word-break: break-word;
          }
          @media (max-width: 560px) {
            main.page-shell {
              padding: 16px 16px 24px;
            }
            .guide-example,
            .guide-details,
            .guide-table-wrap,
            .guide-fact-card {
              padding-left: 12px;
              padding-right: 12px;
            }
            .guide-card p,
            .guide-details p,
            .guide-fact-value {
              font-size: 14px;
              line-height: 1.52;
            }
            .guide-table {
              font-size: 11px;
            }
            .guide-table th,
            .guide-table td {
              padding: 6px 6px;
            }
          }
          @media (min-width: 900px) {
            .learning-grid {
              grid-template-columns: 1fr 1fr;
            }
            .guide-fact-grid {
              grid-template-columns: 1fr 1fr;
            }
          }
        </style>
      </head>
      <body>
        <main class="page-shell">
          <section class="guide-card guide-screen-header">
            <h1 class="guide-screen-title">Learning Center</h1>
            <p class="guide-screen-copy">Worked examples, formulas, and reference notes for the deck.</p>
          </section>
          <section id="learning-guide">\(content)</section>
          \(customLearningSection)
        </main>
      </body>
    </html>
    """
}

private func appendAppWorkedExamples(to content: String) -> String {
    let card = """
<details class="guide-card guide-topic-card"><summary class="guide-topic-summary"><span class="guide-topic-title">Fully Worked Examples</span></summary><div class="guide-topic-body">
<details class="guide-details">
<summary>Ito / GBM example: drift and volatility of S²</summary>
<p>Suppose <code>S_t</code> follows geometric Brownian motion
<code>dS_t = 0.08 S_t dt + 0.30 S_t dW_t</code>.
Define <code>X_t = S_t²</code>. We want the stochastic differential for <code>X_t</code>, and in particular its drift and its diffusion coefficient.</p>
<p>Apply Ito's lemma to <code>f(S) = S²</code>. Then
<code>f'(S) = 2S</code> and
<code>f''(S) = 2</code>.
Ito's lemma says
<code>df(S_t) = f'(S_t)dS_t + 0.5 f''(S_t)(dS_t)²</code>.
So
<code>dX_t = 2S_t dS_t + (dS_t)²</code>.</p>
<p>Now substitute the GBM form for <code>dS_t</code>. The first term becomes
<code>2S_t(0.08 S_t dt + 0.30 S_t dW_t) = 0.16 S_t² dt + 0.60 S_t² dW_t</code>.
For the quadratic-variation term, only the Brownian part survives, so
<code>(dS_t)² = (0.30 S_t)² (dW_t)² = 0.09 S_t² dt</code>.</p>
<p>Add the pieces:
<code>dX_t = (0.16 + 0.09) S_t² dt + 0.60 S_t² dW_t = 0.25 X_t dt + 0.60 X_t dW_t</code>.</p>
<p>Therefore the drift of <code>X_t</code> is <code>0.25 X_t</code>, and the diffusion coefficient is <code>0.60 X_t</code>. If a prompt asks for the volatility parameter of the GBM satisfied by <code>X_t</code>, that parameter is <code>0.60</code>.</p>
</details>
<details class="guide-details">
<summary>Fisher / large-sample MLE example: Bernoulli standard error</summary>
<p>Suppose <code>X_1, ..., X_100</code> are iid <code>Bernoulli(p)</code>, and the prompt says to use the large-sample MLE formula at <code>p = 0.4</code>. The MLE is
<code>p-hat = sample proportion</code>. For large samples,
<code>Var(p-hat) ≈ p(1-p)/n</code>.</p>
<p>Plug in the given numbers:
<code>Var(p-hat) ≈ 0.4 × 0.6 / 100 = 0.24 / 100 = 0.0024</code>.</p>
<p>The standard error is the square root:
<code>SE(p-hat) ≈ sqrt(0.0024) ≈ 0.049</code>.</p>
<p>The same answer can be written from Fisher information. One Bernoulli observation has information
<code>I_1(p) = 1 / (p(1-p))</code>.
So for <code>n = 100</code>,
<code>I_n(p) = 100 / (0.4 × 0.6) = 416.67</code>.
The Cramer-Rao / large-sample variance scale is then
<code>1 / I_n(p) ≈ 0.0024</code>,
and the standard error is again
<code>1 / sqrt(I_n(p)) ≈ 0.049</code>.</p>
</details>
<details class="guide-details">
<summary>Sharpe / Cantelli example: bound probability of a negative return</summary>
<p>Suppose a monthly return has Sharpe ratio <code>S = 0.5</code> and monthly volatility <code>σ = 2%</code>. We want an upper bound on the probability of a negative monthly return when no distribution is assumed.</p>
<p>First recover the mean from Sharpe:
<code>μ = Sσ = 0.5 × 2% = 1%</code>.</p>
<p>The event of a negative return is
<code>{R &lt; 0}</code>.
Rewrite that around the mean:
<code>R &lt; 0</code> means
<code>R - μ ≤ -μ</code>.
So this is a one-sided deviation of size <code>a = μ = 1%</code> below the mean.</p>
<p>Cantelli's inequality says
<code>P(R - μ ≤ -a) ≤ σ² / (σ² + a²)</code>.
Here
<code>σ² = (2%)² = 4</code> in squared-percentage units and
<code>a² = (1%)² = 1</code>.
Therefore
<code>P(R &lt; 0) ≤ 4 / (4 + 1) = 4/5 = 0.80</code>.</p>
<p>So the correct conclusion is not that the probability of a loss is about <code>80%</code>. The conclusion is that, using only mean and variance information, Cantelli gives the upper bound
<code>P(R &lt; 0) ≤ 0.80</code>. It is a worst-case bound, not an estimate of the actual probability.</p>
</details>
<details class="guide-details">
<summary>Conditional probability example: choose a coin, observe HH, predict the next toss</summary>
<p>One of three coins is selected uniformly. Their probabilities of heads are <code>1/4</code>, <code>1/2</code>, and <code>3/4</code>. The selected coin is tossed twice and both tosses are heads. We want the conditional probability that the next toss is also heads.</p>
<p>Let <code>C_1</code>, <code>C_2</code>, and <code>C_3</code> denote the three possible coins. Before observing any tosses, each coin has prior probability <code>1/3</code>. The likelihoods of observing <code>HH</code> are
<code>P(HH | C_1) = (1/4)² = 1/16</code>,
<code>P(HH | C_2) = (1/2)² = 1/4</code>, and
<code>P(HH | C_3) = (3/4)² = 9/16</code>.</p>
<p>Because the prior probabilities are equal, the posterior weights are proportional to the likelihoods:
<code>1/16 : 1/4 : 9/16 = 1 : 4 : 9</code>.
Their sum is <code>14</code>, so the posterior probabilities are
<code>1/14</code>, <code>4/14</code>, and <code>9/14</code>.</p>
<p>The next-toss probability is the posterior-weighted average of the three head probabilities:
<code>P(H next | HH) = (1/14)(1/4) + (4/14)(1/2) + (9/14)(3/4)</code>.</p>
<p>Putting everything over denominator <code>56</code> gives
<code>1/56 + 8/56 + 27/56 = 36/56 = 9/14 ≈ 0.6429</code>.
Therefore the probability that the next toss is heads is <code>9/14</code>, or about <code>64.3%</code>.</p>
</details>
<details class="guide-details">
<summary>Fixed-income example: price a coupon bond</summary>
<p>Consider a three-year bond with face value <code>$1,000</code>, an annual coupon rate of <code>6%</code>, annual coupon payments, and an annual yield of <code>5%</code>. The coupon payment is
<code>0.06 × 1,000 = $60</code> each year.</p>
<p>The cash flows are <code>$60</code> after year 1, <code>$60</code> after year 2, and <code>$1,060</code> after year 3 because the final coupon and principal arrive together. Discount each cash flow at the yield:
<code>P = 60/1.05 + 60/1.05² + 1,060/1.05³</code>.</p>
<p>Compute the discount factors:
<code>1.05² = 1.1025</code> and <code>1.05³ = 1.157625</code>. Therefore
<code>60/1.05 ≈ 57.14</code>,
<code>60/1.1025 ≈ 54.42</code>, and
<code>1,060/1.157625 ≈ 915.69</code>.</p>
<p>Add the present values:
<code>P ≈ 57.14 + 54.42 + 915.69 = $1,027.25</code>.
The price is above face value because the bond pays a <code>6%</code> coupon while the market yield is only <code>5%</code>.</p>
</details>
<details class="guide-details">
<summary>Kelly example: asymmetric gain and loss</summary>
<p>A bet wins with probability <code>p = 0.60</code>. A winning dollar of bankroll earns <code>50%</code>, while a loss removes <code>25%</code> of the amount bet. If fraction <code>f</code> of bankroll is wagered, wealth is multiplied by <code>1 + 0.50f</code> after a win and by <code>1 - 0.25f</code> after a loss.</p>
<p>The Kelly fraction maximizes expected log growth:
<code>g(f) = 0.60 ln(1 + 0.50f) + 0.40 ln(1 - 0.25f)</code>.</p>
<p>Differentiate and set the derivative equal to zero:
<code>g'(f) = 0.60(0.50)/(1 + 0.50f) - 0.40(0.25)/(1 - 0.25f) = 0</code>.</p>
<p>Thus
<code>0.30/(1 + 0.50f) = 0.10/(1 - 0.25f)</code>.
Cross-multiplying gives
<code>0.30(1 - 0.25f) = 0.10(1 + 0.50f)</code>, so
<code>0.30 - 0.075f = 0.10 + 0.05f</code>.</p>
<p>Therefore <code>0.20 = 0.125f</code>, which gives
<code>f = 1.6</code>. The unconstrained Kelly solution is to wager <code>160%</code> of bankroll. If borrowing is forbidden and the feasible range is <code>0 ≤ f ≤ 1</code>, the constrained optimum is the boundary value <code>f = 1</code>.</p>
</details>
<details class="guide-details">
<summary>Order-statistics example: expected maximum of exponentials</summary>
<p>Let <code>X_1, ..., X_5</code> be independent exponential random variables with rate <code>λ = 2</code>. We want <code>E[max(X_1, ..., X_5)]</code>.</p>
<p>For exponential samples, the gaps between successive order statistics are independent. The first gap, from zero to the minimum, has rate <code>5λ</code> and mean <code>1/(5λ)</code>. After the first observation occurs, four exponential clocks remain, so the next gap has mean <code>1/(4λ)</code>. Continuing this way, the expected maximum is
<code>1/(5λ) + 1/(4λ) + 1/(3λ) + 1/(2λ) + 1/λ</code>.</p>
<p>Factor out <code>1/λ</code>:
<code>E[max] = H_5/λ</code>, where
<code>H_5 = 1 + 1/2 + 1/3 + 1/4 + 1/5</code>.</p>
<p>Using denominator <code>60</code>,
<code>H_5 = (60 + 30 + 20 + 15 + 12)/60 = 137/60</code>.
Therefore
<code>E[max] = (137/60)/2 = 137/120 ≈ 1.1417</code>.</p>
</details>
<details class="guide-details">
<summary>Biased gambler's ruin example: hit the upper boundary first</summary>
<p>A random walk moves right with probability <code>p = 0.60</code> and left with probability <code>q = 0.40</code>. It starts at <code>i = 2</code> and stops when it reaches either <code>0</code> or <code>N = 5</code>. We want the probability of reaching <code>5</code> before <code>0</code>.</p>
<p>For <code>p ≠ q</code>, the upper-boundary hitting probability is
<code>h(i) = [1 - (q/p)^i] / [1 - (q/p)^N]</code>.</p>
<p>Here
<code>q/p = 0.40/0.60 = 2/3</code>. Substitute <code>i = 2</code> and <code>N = 5</code>:
<code>h(2) = [1 - (2/3)²] / [1 - (2/3)^5]</code>.</p>
<p>The numerator is
<code>1 - 4/9 = 5/9</code>.
The denominator is
<code>1 - 32/243 = 211/243</code>.
Thus
<code>h(2) = (5/9)/(211/243) = (5/9)(243/211) = 135/211 ≈ 0.6398</code>.</p>
<p>Therefore the probability of reaching <code>5</code> before <code>0</code> is about <code>64.0%</code>.</p>
</details>
<details class="guide-details">
<summary>Normal order statistics: expected maximum and minimum of two standard normals</summary>
<p>Let <code>X</code> and <code>Y</code> be independent <code>N(0,1)</code> random variables. We want
<code>E[max(X,Y)]</code> and <code>E[min(X,Y)]</code>.</p>
<p>Use the identities
<code>max(X,Y) = (X + Y + |X - Y|)/2</code> and
<code>min(X,Y) = (X + Y - |X - Y|)/2</code>.
Because both variables have mean zero,
<code>E[X + Y] = 0</code>. Thus
<code>E[max(X,Y)] = 0.5 E[|X-Y|]</code>.</p>
<p>The difference of two independent normal variables is normal. Its mean is
<code>0 - 0 = 0</code>, and its variance is
<code>1 + 1 = 2</code>, so
<code>X-Y ~ N(0,2)</code>.
If <code>Z ~ N(0,s²)</code>, then
<code>E[|Z|] = s sqrt(2/pi)</code>.
Here <code>s = sqrt(2)</code>, so
<code>E[|X-Y|] = sqrt(2)sqrt(2/pi) = 2/sqrt(pi)</code>.</p>
<p>Therefore
<code>E[max(X,Y)] = 0.5(2/sqrt(pi)) = 1/sqrt(pi) ≈ 0.5642</code>.
Similarly,
<code>E[min(X,Y)] = -0.5 E[|X-Y|] = -1/sqrt(pi) ≈ -0.5642</code>.
The minimum is the negative of the maximum because the joint distribution is symmetric about zero.</p>
</details>
<details class="guide-details">
<summary>Minimum-variance hedge: choose how many shares of B to short</summary>
<p>Suppose one share of stock A has return variance <code>Var(r_A) = 0.04</code>.
Stock B has return variance <code>Var(r_B) = 0.09</code>, and the correlation between the two returns is <code>0.50</code>.
We hold one share of A and short <code>h</code> shares of B, so the hedged return is
<code>r_A - h r_B</code>.</p>
<p>First convert correlation to covariance. The standard deviations are
<code>sqrt(0.04) = 0.20</code> and
<code>sqrt(0.09) = 0.30</code>. Hence
<code>Cov(r_A,r_B) = Corr(r_A,r_B) SD(r_A) SD(r_B)</code>
<code>= 0.50 × 0.20 × 0.30 = 0.03</code>.</p>
<p>The portfolio variance is
<code>V(h) = Var(r_A - h r_B)</code>
<code>= 0.04 + 0.09h² - 2h(0.03)</code>
<code>= 0.04 + 0.09h² - 0.06h</code>.</p>
<p>Differentiate:
<code>V'(h) = 0.18h - 0.06</code>.
Set the derivative equal to zero:
<code>0.18h - 0.06 = 0</code>, so
<code>h = 0.06/0.18 = 1/3</code>.
Because <code>V''(h) = 0.18 &gt; 0</code>, this is the variance-minimizing hedge.</p>
<p>Thus we should short <code>1/3</code> share of B for each share of A.
The minimized variance is
<code>V(1/3) = 0.04 + 0.09(1/9) - 0.06(1/3)</code>
<code>= 0.04 + 0.01 - 0.02 = 0.03</code>.</p>
</details>
<details class="guide-details">
<summary>Coupon collector: variance and a rough 95% interval for 20 coupons</summary>
<p>There are <code>n = 20</code> equally likely coupon types. Draw with replacement until every type has appeared, and let <code>T</code> be the number of draws. We will compute the mean, variance, standard deviation, and a rough central <code>95%</code> interval.</p>
<p>After <code>20-i</code> types have been collected, exactly <code>i</code> unseen types remain. The probability that the next draw finds a new type is <code>i/20</code>. The waiting time for that next new type is geometric, so the total collection time is a sum of independent geometric stage times.</p>
<p>The mean is
<code>E[T] = nH_n</code>.
Using
<code>H_20 = 1 + 1/2 + ... + 1/20 ≈ 3.59774</code>,
we get
<code>E[T] = 20(3.59774) ≈ 71.95</code>.</p>
<p>The exact variance is
<code>Var(T) = n² sum(i=1 to n, 1/i²) - nH_n</code>.
For <code>n = 20</code>,
<code>sum(i=1 to 20, 1/i²) ≈ 1.59616</code>. Therefore
<code>Var(T) ≈ 20²(1.59616) - 20(3.59774)</code>
<code>= 638.46 - 71.95 = 566.51</code>.</p>
<p>The standard deviation is
<code>SD(T) = sqrt(566.51) ≈ 23.80</code>.
A quick normal-style central <code>95%</code> interval is
<code>mean ± 1.96 SD</code>, giving
<code>71.95 ± 1.96(23.80) = 71.95 ± 46.65</code>.
This produces the interval
<code>[25.30, 118.60]</code>.</p>
<p>The interval is an approximation, not an exact coupon-collector confidence statement, because the stopping-time distribution is right-skewed. The exact mean and variance calculations above do not depend on that approximation.</p>
</details>
<details class="guide-details">
<summary>Rao-Blackwell example: improve an estimator of a Bernoulli probability</summary>
<p>Let <code>X_1</code> and <code>X_2</code> be independent <code>Bernoulli(p)</code> observations, and take <code>p = 0.30</code> for the numerical comparison. The estimator
<code>U = X_1</code> is unbiased because
<code>E[U] = E[X_1] = p</code>, but it ignores the second observation.</p>
<p>The total
<code>T = X_1 + X_2</code> is sufficient for <code>p</code>. Rao-Blackwellization replaces <code>U</code> by
<code>U* = E[U | T] = E[X_1 | X_1 + X_2]</code>.</p>
<p>Conditional on <code>T = 0</code>, both observations are zero, so <code>E[X_1 | T=0] = 0</code>.
Conditional on <code>T = 2</code>, both are one, so <code>E[X_1 | T=2] = 1</code>.
Conditional on <code>T = 1</code>, the outcomes <code>(1,0)</code> and <code>(0,1)</code> have equal conditional probability, so
<code>E[X_1 | T=1] = 1/2</code>.
In all three cases,
<code>E[X_1 | T] = T/2</code>.</p>
<p>Thus the improved estimator is
<code>U* = (X_1 + X_2)/2</code>, the sample proportion.
It remains unbiased:
<code>E[U*] = E[T]/2 = 2p/2 = p</code>.</p>
<p>The original variance is
<code>Var(U) = p(1-p)</code>, which at <code>p = 0.30</code> is
<code>0.30(0.70) = 0.21</code>.
The improved variance is
<code>Var(U*) = Var(T)/4 = 2p(1-p)/4 = p(1-p)/2</code>,
which is
<code>0.21/2 = 0.105</code>.
Rao-Blackwellization cuts the variance in half while preserving unbiasedness.</p>
</details>
<details class="guide-details">
<summary>Lognormal example: compute the mean and variance from normal parameters</summary>
<p>Suppose
<code>ln(X) ~ N(μ,σ²)</code> with
<code>μ = 0.10</code> and
<code>σ = 0.30</code>. We want <code>E[X]</code> and <code>Var(X)</code>.</p>
<p>Write <code>X = exp(Y)</code>, where
<code>Y ~ N(μ,σ²)</code>. The normal moment-generating identity is
<code>E[exp(tY)] = exp(tμ + 0.5t²σ²)</code>.</p>
<p>For the first moment, set <code>t = 1</code>:
<code>E[X] = E[exp(Y)] = exp(μ + 0.5σ²)</code>
<code>= exp(0.10 + 0.5(0.30²))</code>
<code>= exp(0.10 + 0.045) = exp(0.145) ≈ 1.1560</code>.</p>
<p>For the second moment, use <code>X² = exp(2Y)</code> and set <code>t = 2</code>:
<code>E[X²] = exp(2μ + 0.5(2²)σ²)</code>
<code>= exp(2μ + 2σ²)</code>
<code>= exp(0.20 + 2(0.09)) = exp(0.38) ≈ 1.4623</code>.</p>
<p>Now subtract the square of the mean:
<code>Var(X) = E[X²] - E[X]²</code>.
Since
<code>E[X]² = exp(2 × 0.145) = exp(0.29) ≈ 1.3364</code>,
we obtain
<code>Var(X) ≈ 1.4623 - 1.3364 = 0.1259</code>.</p>
</details>
</div></details>
"""

    guard let gridCloseRange = content.range(of: "</div>", options: .backwards) else {
        return content + card
    }
    var updated = content
    updated.insert(contentsOf: card, at: gridCloseRange.lowerBound)
    return updated
}

private func customLearningTopicsWorkshopHTML(customTopics: [CustomLearningTopic]) -> String {
    let payload = customTopics.map { topic in
        [
            "id": topic.id,
            "createdAt": Int((topic.createdAt.timeIntervalSince1970 * 1000).rounded()),
            "title": topic.title,
            "body": topic.body,
        ]
    }
    let topicsJSON: String = {
        guard let data = try? JSONSerialization.data(withJSONObject: payload, options: []),
              let string = String(data: data, encoding: .utf8)
        else {
            return "[]"
        }
        return string
    }()
    return #"""
<details class="guide-card guide-topic-card guide-custom-workshop" open>
  <summary class="guide-topic-summary"><span class="guide-topic-title">Your Custom Learning Topics</span></summary>
  <div class="guide-topic-body">
    <p class="guide-custom-builder-note">Write your own Learn-topic pills here. Use <code>$...$</code>, <code>\(...\)</code>, <code>\[...\]</code>, or backticks for highlighted math-style snippets. Saved topics stay in the app and in recovery codes.</p>
    <div class="guide-custom-builder-form">
      <div>
        <label class="guide-custom-builder-label" for="custom-learning-topic-title">Topic title</label>
        <input id="custom-learning-topic-title" class="guide-custom-builder-input" type="text" placeholder="Example: Coupon Collector Variance Shortcut" />
      </div>
      <div>
        <label class="guide-custom-builder-label" for="custom-learning-topic-body">Topic text</label>
        <textarea id="custom-learning-topic-body" class="guide-custom-builder-textarea" placeholder="Write the explanation you want to keep in the Learning Center."></textarea>
      </div>
      <div class="guide-custom-builder-actions">
        <button id="custom-learning-topic-save" class="guide-custom-builder-button guide-custom-builder-button--primary" type="button">Save topic</button>
        <button id="custom-learning-topic-clear" class="guide-custom-builder-button" type="button">Clear form</button>
      </div>
      <p id="custom-learning-topic-status" class="guide-custom-builder-status" aria-live="polite"></p>
    </div>
    <div id="custom-learning-topic-list" class="guide-custom-topic-list"></div>
  </div>
</details>
<script>
  (function () {
    var initialTopics = \#(topicsJSON);
    var state = {
      topics: Array.isArray(initialTopics) ? initialTopics.slice().sort(function (a, b) {
        return Number(b.createdAt || 0) - Number(a.createdAt || 0);
      }) : [],
      editingId: null
    };

    var elements = {
      title: document.getElementById("custom-learning-topic-title"),
      body: document.getElementById("custom-learning-topic-body"),
      save: document.getElementById("custom-learning-topic-save"),
      clear: document.getElementById("custom-learning-topic-clear"),
      status: document.getElementById("custom-learning-topic-status"),
      list: document.getElementById("custom-learning-topic-list")
    };

    function escapeHTML(text) {
      return String(text == null ? "" : text)
        .replace(/&/g, "&amp;")
        .replace(/</g, "&lt;")
        .replace(/>/g, "&gt;")
        .replace(/"/g, "&quot;")
        .replace(/'/g, "&#39;");
    }

    function rewriteFractions(text) {
      var output = text;
      var regex = /\\frac\{([^{}]*)\}\{([^{}]*)\}/g;
      var previous = null;
      while (output !== previous) {
        previous = output;
        output = output.replace(regex, "($1)/($2)");
      }
      return output;
    }

    function rewriteSqrts(text) {
      var output = text;
      var regex = /\\sqrt\{([^{}]*)\}/g;
      var previous = null;
      while (output !== previous) {
        previous = output;
        output = output.replace(regex, "√($1)");
      }
      return output;
    }

    function normalizeMathDisplay(text) {
      var output = String(text == null ? "" : text);
      output = output.replace(/\$+/g, "");
      output = output.replace(/\\left/g, "").replace(/\\right/g, "");
      var displayMap = {
        "\\\\lambda": "λ",
        "\\\\sigma": "σ",
        "\\\\mu": "μ",
        "\\\\theta": "θ",
        "\\\\alpha": "α",
        "\\\\beta": "β",
        "\\\\gamma": "γ",
        "\\\\rho": "ρ",
        "\\\\tau": "τ",
        "\\\\pi": "π",
        "\\\\cdot": "·",
        "\\\\times": "×",
        "\\\\leq": "≤",
        "\\\\geq": "≥",
        "\\\\neq": "≠",
        "\\\\approx": "≈",
        "\\\\infty": "∞"
      };
      Object.keys(displayMap).forEach(function (key) {
        output = output.split(key).join(displayMap[key]);
      });
      output = rewriteFractions(output);
      output = rewriteSqrts(output);
      output = output.replace(/\{/g, "(").replace(/\}/g, ")");
      return output;
    }

    function renderInlineHighlightedText(text) {
      var source = String(text == null ? "" : text);
      var output = "";
      var pattern = /(`[^`]+`|\$\$[\s\S]+?\$\$|\$[^$\n]+\$|\\\([\s\S]+?\\\)|\\\[[\s\S]+?\\\])/g;
      var lastIndex = 0;
      var match;
      while ((match = pattern.exec(source)) !== null) {
        if (match.index > lastIndex) {
          output += escapeHTML(source.slice(lastIndex, match.index));
        }
        var token = match[0];
        if (token.startsWith("`")) {
          token = token.slice(1, -1);
        } else if (token.startsWith("$$")) {
          token = token.slice(2, -2);
        } else if (token.startsWith("$")) {
          token = token.slice(1, -1);
        } else if (token.startsWith("\\(")) {
          token = token.slice(2, -2);
        } else if (token.startsWith("\\[")) {
          token = token.slice(2, -2);
        }
        output += "<code>" + escapeHTML(normalizeMathDisplay(token)) + "</code>";
        lastIndex = pattern.lastIndex;
      }
      if (lastIndex < source.length) {
        output += escapeHTML(source.slice(lastIndex));
      }
      return output;
    }

    function renderBodyHTML(text) {
      var normalized = String(text == null ? "" : text).replace(/\r\n/g, "\n").replace(/\r/g, "\n").trim();
      if (!normalized) {
        return "";
      }
      return normalized
        .split(/\n\s*\n/)
        .map(function (paragraph) {
          return "<p>" + renderInlineHighlightedText(paragraph).replace(/\n/g, "<br />") + "</p>";
        })
        .join("");
    }

    function clearStatus() {
      elements.status.textContent = "";
      elements.status.classList.remove("is-error");
    }

    function setStatus(text, isError) {
      elements.status.textContent = text || "";
      elements.status.classList.toggle("is-error", !!isError);
    }

    function syncToNative() {
      var handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.learningTopics;
      if (handler && typeof handler.postMessage === "function") {
        handler.postMessage({ type: "replaceTopics", topics: state.topics });
      }
    }

    function resetForm(clearMessage) {
      state.editingId = null;
      elements.title.value = "";
      elements.body.value = "";
      elements.save.textContent = "Save topic";
      if (clearMessage !== false) {
        clearStatus();
      }
    }

    function beginEdit(id) {
      var topic = state.topics.find(function (entry) { return entry.id === id; });
      if (!topic) {
        return;
      }
      state.editingId = topic.id;
      elements.title.value = topic.title || "";
      elements.body.value = topic.body || "";
      elements.save.textContent = "Update topic";
      clearStatus();
      elements.title.focus();
    }

    function deleteTopic(id) {
      state.topics = state.topics.filter(function (topic) { return topic.id !== id; });
      renderTopicList();
      syncToNative();
      if (state.editingId === id) {
        resetForm(false);
      } else {
        setStatus("Topic deleted.", false);
      }
    }

    function renderTopicList() {
      if (!state.topics.length) {
        elements.list.innerHTML = '<p class="guide-custom-topic-empty">No custom learning topics saved yet.</p>';
        return;
      }
      elements.list.innerHTML = state.topics.map(function (topic) {
        return '<article class="guide-card guide-custom-topic-article">' +
          '<h3 class="guide-custom-topic-title">' + renderInlineHighlightedText(topic.title || "") + '</h3>' +
          '<div class="guide-custom-topic-copy">' + renderBodyHTML(topic.body || "") + '</div>' +
          '<div class="guide-custom-builder-actions">' +
            '<button class="guide-custom-builder-button" type="button" data-custom-learning-edit="' + escapeHTML(topic.id) + '">Edit</button>' +
            '<button class="guide-custom-builder-button" type="button" data-custom-learning-delete="' + escapeHTML(topic.id) + '">Delete</button>' +
          '</div>' +
        '</article>';
      }).join("");
    }

    function handleSave() {
      var title = String(elements.title.value || "").replace(/\s+/g, " ").trim();
      var body = String(elements.body.value || "").replace(/\r\n/g, "\n").replace(/\r/g, "\n").trim();
      if (!title) {
        setStatus("Add a topic title first.", true);
        elements.title.focus();
        return;
      }
      if (!body) {
        setStatus("Add some topic text first.", true);
        elements.body.focus();
        return;
      }
      if (state.editingId) {
        state.topics = state.topics.map(function (topic) {
          if (topic.id !== state.editingId) {
            return topic;
          }
          return {
            id: topic.id,
            createdAt: topic.createdAt,
            title: title,
            body: body
          };
        });
        setStatus("Topic updated.", false);
      } else {
        state.topics.unshift({
          id: "learn-" + Math.random().toString(36).slice(2, 11),
          createdAt: Date.now(),
          title: title,
          body: body
        });
        if (state.topics.length > 200) {
          state.topics = state.topics.slice(0, 200);
        }
        setStatus("Topic saved.", false);
      }
      state.topics.sort(function (a, b) {
        return Number(b.createdAt || 0) - Number(a.createdAt || 0);
      });
      renderTopicList();
      syncToNative();
      resetForm(false);
    }

    elements.save.addEventListener("click", handleSave);
    elements.clear.addEventListener("click", function () { resetForm(true); });
    elements.list.addEventListener("click", function (event) {
      var editButton = event.target.closest("[data-custom-learning-edit]");
      if (editButton) {
        beginEdit(editButton.getAttribute("data-custom-learning-edit"));
        return;
      }
      var deleteButton = event.target.closest("[data-custom-learning-delete]");
      if (deleteButton) {
        deleteTopic(deleteButton.getAttribute("data-custom-learning-delete"));
      }
    });

    renderTopicList();
  })();
</script>
"""#
}

private func captureFirst(in text: String, pattern: String) -> String? {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
    let nsrange = NSRange(text.startIndex..., in: text)
    guard let match = regex.firstMatch(in: text, options: [], range: nsrange),
          match.numberOfRanges > 1,
          let range = Range(match.range(at: 1), in: text) else { return nil }
    return String(text[range])
}

private func removeAll(in text: String, pattern: String) -> String {
    guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return text }
    let nsrange = NSRange(text.startIndex..., in: text)
    return regex.stringByReplacingMatches(in: text, options: [], range: nsrange, withTemplate: "")
}

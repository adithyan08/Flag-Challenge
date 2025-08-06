import Foundation
import CoreData
import SwiftUI


class FlagsChallengeViewModel: ObservableObject {
    private let context: NSManagedObjectContext

    @Published var questions: [QuizQuestion] = []
    @Published var currentQuestionIndex = 0
    @Published var selectedIndex: Int? = nil
    @Published var isResultShown = false
    @Published var score = 0

    @Published var scheduledDate = Date().addingTimeInterval(60)
    @Published var countdownToStart = 0
    @Published var phase: Phase = .waitingForSchedule

    @Published var hours: Int = 0
    @Published var minutes: Int = 0
    @Published var seconds: Int = 10
    @Published var isCountingDown = false

    private var timer: Timer?

    private let countdownDuration = 20
    private let questionDuration = 30
    private let intervalDuration = 10

    @Published var questionTimer = 0
    @Published var intervalTimer = 0

    enum Phase: String {
        case waitingForSchedule
        case countdownToStart
        case question
        case interval
        case finished
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        restoreStateIfNeeded()
        loadPersistedOrJsonData()
        NotificationCenter.default.addObserver(self, selector: #selector(saveState), name: UIApplication.willResignActiveNotification, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        stopTimer()
    }

    // MARK: - Coredata

    @objc func saveState() {
        let defaults = UserDefaults.standard
        defaults.set(currentQuestionIndex, forKey: "currentQuestionIndex")
        defaults.set(selectedIndex, forKey: "selectedIndex")
        defaults.set(isResultShown, forKey: "isResultShown")
        defaults.set(score, forKey: "score")
        defaults.set(phase.rawValue, forKey: "phase")
        defaults.set(Date().timeIntervalSince1970, forKey: "timeSaved")

        switch phase {
        case .question:
            defaults.set(questionTimer, forKey: "timerRemaining")
        case .interval:
            defaults.set(intervalTimer, forKey: "timerRemaining")
        default:
            defaults.set(0, forKey: "timerRemaining")
        }
        defaults.set(hours, forKey: "hours")
        defaults.set(minutes, forKey: "minutes")
        defaults.set(seconds, forKey: "seconds")
        defaults.set(isCountingDown, forKey: "isCountingDown")
        defaults.synchronize()
    }

    func restoreStateIfNeeded() {
        let defaults = UserDefaults.standard
        guard let savedPhaseRaw = defaults.string(forKey: "phase"),
              let savedPhase = Phase(rawValue: savedPhaseRaw) else {
            return
        }
        
        let savedTime = defaults.double(forKey: "timeSaved")
        let elapsed = Int(Date().timeIntervalSince1970 - savedTime)
        
        currentQuestionIndex = defaults.integer(forKey: "currentQuestionIndex")
        selectedIndex = defaults.object(forKey: "selectedIndex") as? Int
        isResultShown = defaults.bool(forKey: "isResultShown")
        score = defaults.integer(forKey: "score")
        phase = savedPhase
        hours = defaults.integer(forKey: "hours")
        minutes = defaults.integer(forKey: "minutes")
        seconds = defaults.integer(forKey: "seconds")
        isCountingDown = defaults.bool(forKey: "isCountingDown")
        
        let savedTimer = defaults.integer(forKey: "timerRemaining")
        let remaining = savedTimer - elapsed
        
        switch phase {
        case .question:
            if remaining > 0 {
                questionTimer = remaining
                startQuestionTimer()
            } else {
                questionTimer = 0
                evaluateAnswer()
            }
        case .interval:
            if remaining > 0 {
                intervalTimer = remaining
                startIntervalTimer()
            } else {
                intervalTimer = 0
                moveToNextQuestion()
            }
        case .countdownToStart:
            if isCountingDown {
                countdownToStart = max(countdownDuration - elapsed, 0)
                if countdownToStart > 0 {
                    startCountdownTimer()
                } else {
                    isCountingDown = false
                    startQuestion()
                }
            }
        default:
            questionTimer = 0
            intervalTimer = 0
        }
    }

    // MARK: - Core Data Load and Save

    private func loadPersistedOrJsonData() {
        let fetch = NSFetchRequest<QuestionEntity>(entityName: "QuestionEntity")
        do {
            let stored = try context.fetch(fetch)
            if !stored.isEmpty {
                DispatchQueue.main.async {
                    self.questions = stored.map { $0.toQuizQuestion() }
                }
                return
            }
        } catch {
            print("CoreData fetch error: \(error)")
        }
        loadFromJsonAndSave()
    }

    private func loadFromJsonAndSave() {
        let jsonString = """
        {
          "questions": [
            {
              "answer_id": 160,
              "countries": [
                { "country_name": "Bosnia and Herzegovina", "id": 29 },
                { "country_name": "Mauritania", "id": 142 },
                { "country_name": "Chile", "id": 45 },
                { "country_name": "New Zealand", "id": 160 }
              ],
              "country_code": "NZ"
            },
            {
              "answer_id": 13,
              "countries": [
                { "country_name": "Aruba", "id": 13 },
                { "country_name": "Serbia", "id": 184 },
                { "country_name": "Montenegro", "id": 150 },
                { "country_name": "Moldova", "id": 147 }
              ],
              "country_code": "AW"
            },
            {
              "answer_id": 66,
              "countries": [
                { "country_name": "Kenya", "id": 117 },
                { "country_name": "Montenegro", "id": 150 },
                { "country_name": "Ecuador", "id": 66 },
                { "country_name": "Bhutan", "id": 26 }
              ],
              "country_code": "EC"
            },
            {
              "answer_id": 174,
              "countries": [
                { "country_name": "Niue", "id": 164 },
                { "country_name": "Paraguay", "id": 174 },
                { "country_name": "Tuvalu", "id": 232 },
                { "country_name": "Indonesia", "id": 105 }
              ],
              "country_code": "PY"
            },
            {
              "answer_id": 122,
              "countries": [
                { "country_name": "Kyrgyzstan", "id": 122 },
                { "country_name": "Zimbabwe", "id": 250 },
                { "country_name": "Saint Lucia", "id": 190 },
                { "country_name": "Ireland", "id": 108 }
              ],
              "country_code": "KG"
            },
            {
              "answer_id": 192,
              "countries": [
                { "country_name": "Saint Pierre and Miquelon", "id": 192 },
                { "country_name": "Namibia", "id": 155 },
                { "country_name": "Greece", "id": 87 },
                { "country_name": "Anguilla", "id": 8 }
              ],
              "country_code": "PM"
            },
            {
              "answer_id": 113,
              "countries": [
                { "country_name": "Belarus", "id": 21 },
                { "country_name": "Falkland Islands", "id": 73 },
                { "country_name": "Japan", "id": 113 },
                { "country_name": "Iraq", "id": 107 }
              ],
              "country_code": "JP"
            },
            {
              "answer_id": 230,
              "countries": [
                { "country_name": "Barbados", "id": 20 },
                { "country_name": "Italy", "id": 111 },
                { "country_name": "Turkmenistan", "id": 230 },
                { "country_name": "Cocos Island", "id": 48 }
              ],
              "country_code": "TM"
            },
            {
              "answer_id": 81,
              "countries": [
                { "country_name": "Maldives", "id": 137 },
                { "country_name": "Aruba", "id": 13 },
                { "country_name": "Monaco", "id": 148 },
                { "country_name": "Gabon", "id": 81 }
              ],
              "country_code": "GA"
            },
            {
              "answer_id": 141,
              "countries": [
                { "country_name": "Martinique", "id": 141 },
                { "country_name": "Montenegro", "id": 150 },
                { "country_name": "Barbados", "id": 20 },
                { "country_name": "Monaco", "id": 148 }
              ],
              "country_code": "MQ"
            },
            {
              "answer_id": 23,
              "countries": [
                { "country_name": "Germany", "id": 84 },
                { "country_name": "Dominica", "id": 63 },
                { "country_name": "Belize", "id": 23 },
                { "country_name": "Tuvalu", "id": 232 }
              ],
              "country_code": "BZ"
            },
            {
              "answer_id": 60,
              "countries": [
                { "country_name": "Falkland Islands", "id": 73 },
                { "country_name": "Czech Republic", "id": 60 },
                { "country_name": "Mauritania", "id": 142 },
                { "country_name": "British Indian Ocean Territory", "id": 33 }
              ],
              "country_code": "CZ"
            },
            {
              "answer_id": 235,
              "countries": [
                { "country_name": "United Arab Emirates", "id": 235 },
                { "country_name": "United Arab Emirates", "id": 235 },
                { "country_name": "Macedonia", "id": 133 },
                { "country_name": "Guernsey", "id": 93 }
              ],
              "country_code": "AE"
            },
            {
              "answer_id": 114,
              "countries": [
                { "country_name": "Turks and Caicos Islands", "id": 231 },
                { "country_name": "Myanmar", "id": 154 },
                { "country_name": "Jersey", "id": 114 },
                { "country_name": "Ethiopia", "id": 72 }
              ],
              "country_code": "JE"
            },
            {
              "answer_id": 126,
              "countries": [
                { "country_name": "Malawi", "id": 135 },
                { "country_name": "Trinidad and Tobago", "id": 227 },
                { "country_name": "Nepal", "id": 157 },
                { "country_name": "Lesotho", "id": 126 }
              ],
              "country_code": "LS"
            }
          ]
        }
        """
        guard let data = jsonString.data(using: .utf8) else { return }
        do {
            let response = try JSONDecoder().decode(ApiResponse.self, from: data)
            let mapped = response.questions.compactMap { q -> QuizQuestion? in
                let opts = q.countries.map(\.country_name)
                guard let correctIdx = q.countries.firstIndex(where: { $0.id == q.answer_id }) else { return nil }
                return QuizQuestion(id: q.answer_id,
                                    flagImageName: q.country_code.uppercased(),
                                    options: opts,
                                    correctOptionIndex: correctIdx)
            }
            DispatchQueue.main.async {
                self.questions = mapped
                try? self.saveQuestionsToCoreData(mapped)
            }
        } catch {
            print("JSON decode error: \(error.localizedDescription)")
        }
    }

    private func saveQuestionsToCoreData(_ questions: [QuizQuestion]) throws {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "QuestionEntity")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try context.execute(deleteRequest)
        for q in questions {
            _ = q.toEntity(in: context)
        }
        try context.save()
    }

    // MARK: - Timer and Game Logic

    func saveScheduledDuration(hours: Int, minutes: Int, seconds: Int) {
        let validHours = max(0, min(23, hours))
        let validMinutes = max(0, min(59, minutes))
        let validSeconds = max(0, min(59, seconds))

        self.hours = validHours
        self.minutes = validMinutes
        self.seconds = validSeconds

        let duration = (validHours * 3600) + (validMinutes * 60) + validSeconds
        if duration <= 0 { return }
        scheduledDate = Date().addingTimeInterval(TimeInterval(duration))
        startCountdown()
    }

    private func startCountdown() {
        stopTimer()
        let diff = Int(scheduledDate.timeIntervalSinceNow)

        if diff > countdownDuration {
            countdownToStart = countdownDuration
            phase = .waitingForSchedule
            isCountingDown = false
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(diff - countdownDuration)) {
                self.phase = .countdownToStart
                self.isCountingDown = true
                self.startCountdownTimer()
            }
        } else if diff > 0 {
            countdownToStart = diff
            phase = .countdownToStart
            isCountingDown = true
            startCountdownTimer()
        } else {
            isCountingDown = false
            startQuestion()
        }
    }

    private func startCountdownTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if self.countdownToStart > 0 {
                self.countdownToStart -= 1
            } else {
                self.stopTimer()
                self.isCountingDown = false
                self.startQuestion()
            }
        })
    }

    private func startQuestion() {
        stopTimer()
        phase = .question
        questionTimer = questionDuration
        selectedIndex = nil
        isResultShown = false
        startQuestionTimer()
    }

    private func startQuestionTimer() {
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if self.questionTimer > 0 {
                self.questionTimer -= 1
            } else {
                self.stopTimer()
                self.evaluateAnswer()
            }
        })
    }

    func selectOption(_ index: Int) {
        guard !isResultShown && phase == .question else { return }
        selectedIndex = index
        isResultShown = true
        stopTimer()
        evaluateAnswer()
        print("Selected option: \(index), isResultShown: \(isResultShown)")
    }


    private func evaluateAnswer() {
        guard currentQuestionIndex < questions.count else {
            phase = .finished
            stopTimer()
            return
        }
        
        if selectedIndex == questions[currentQuestionIndex].correctOptionIndex {
            score += 1
        }
        
        stopTimer()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
            guard let self = self else { return }
            self.phase = .interval
            self.intervalTimer = self.intervalDuration
            self.startIntervalTimer()
        }
    }


    private func startIntervalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
            guard let self = self else { return }
            if self.intervalTimer > 0 {
                self.intervalTimer -= 1
            } else {
                self.stopTimer()
                self.moveToNextQuestion()
            }
        })
    }

    private func moveToNextQuestion() {
        if currentQuestionIndex + 1 < questions.count {
            currentQuestionIndex += 1
            startQuestion()
        } else {
            phase = .finished
            stopTimer()
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    func resetGameData() {
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = QuestionEntity.fetchRequest()
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        do {
            try context.execute(batchDeleteRequest)
            try context.save()
            loadFromJsonAndSave()
            resetState()
        } catch {
            print("Failed to reset data: \(error)")
        }
    }
    func resetState() {
        score = 0
        currentQuestionIndex = 0
        selectedIndex = nil
        isResultShown = false
        phase = .waitingForSchedule
        
    }

    func resetGame() {
        stopTimer()
        currentQuestionIndex = 0
        selectedIndex = nil
        isResultShown = false
        score = 0
        phase = .waitingForSchedule
        isCountingDown = false
        hours = 0
        minutes = 0
        seconds = 10
    }
}

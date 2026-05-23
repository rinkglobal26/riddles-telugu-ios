import Foundation

enum AnswerValidator {
    static func isCorrect(_ input: String, for riddle: Riddle, mode: LanguageMode) -> Bool {
        let submitted = normalized(input)
        guard !submitted.isEmpty else { return false }

        return answerOptions(for: riddle, mode: mode)
            .map(normalized)
            .contains(submitted)
    }

    private static func answerOptions(for riddle: Riddle, mode: LanguageMode) -> [String] {
        let primary = riddle.answer(for: mode)
        let answers = [primary, riddle.answer, riddle.englishAnswer]
        let separators = CharacterSet(charactersIn: "/,;|")

        return answers.flatMap { answer in
            answer
                .components(separatedBy: separators)
                .flatMap { $0.components(separatedBy: " లేదా ") }
                .flatMap { $0.components(separatedBy: " or ") }
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        }
    }

    private static func normalized(_ value: String) -> String {
        let folded = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(
                of: #"^(a|an|the)\s+"#,
                with: "",
                options: .regularExpression
            )

        let allowed = CharacterSet.letters.union(.decimalDigits)
        return String(folded.unicodeScalars.filter { allowed.contains($0) })
    }
}

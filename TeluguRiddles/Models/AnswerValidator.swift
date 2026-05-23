import Foundation

enum AnswerValidator {
    static func isCorrect(_ input: String, for riddle: Riddle, mode: LanguageMode) -> Bool {
        let submittedPhrase = normalizedPhrase(input)
        let submittedTokens = normalizedTokens(input)
        guard !submittedPhrase.isEmpty else { return false }

        return answerOptions(for: riddle, mode: mode).contains { answer in
            let answerPhrase = normalizedPhrase(answer)
            let answerTokens = normalizedTokens(answer)

            return submittedPhrase == answerPhrase
                || isMeaningfulPartial(submittedPhrase, answerPhrase)
                || hasTokenOverlap(submittedTokens, answerTokens)
                || hasClosePhraseMatch(submittedPhrase, answerPhrase)
                || hasEquivalentToken(submittedTokens, answerTokens)
        }
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

    private static func normalizedPhrase(_ value: String) -> String {
        String(normalizedText(value).unicodeScalars.filter { searchableCharacters.contains($0) })
    }

    private static func normalizedTokens(_ value: String) -> [String] {
        var tokens: [String] = []
        var current = ""

        for scalar in normalizedText(value).unicodeScalars {
            if searchableCharacters.contains(scalar) {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                tokens.append(current)
                current = ""
            }
        }

        if !current.isEmpty {
            tokens.append(current)
        }

        return tokens.filter { $0.count >= 2 }
    }

    private static func normalizedText(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .folding(options: [.caseInsensitive, .diacriticInsensitive, .widthInsensitive], locale: .current)
            .lowercased()
            .replacingOccurrences(
                of: #"^(a|an|the)\s+"#,
                with: "",
                options: .regularExpression
            )
    }

    private static func isMeaningfulPartial(_ submitted: String, _ answer: String) -> Bool {
        guard submitted.count >= 4 || answer.count >= 4 else { return false }
        return (submitted.count >= 4 && answer.contains(submitted))
            || (answer.count >= 4 && submitted.contains(answer))
    }

    private static func hasTokenOverlap(_ submittedTokens: [String], _ answerTokens: [String]) -> Bool {
        for submitted in submittedTokens where submitted.count >= 3 {
            for answer in answerTokens where answer.count >= 3 {
                if submitted == answer || submitted.contains(answer) || answer.contains(submitted) {
                    return true
                }
            }
        }
        return false
    }

    private static func hasClosePhraseMatch(_ submitted: String, _ answer: String) -> Bool {
        let shorter = min(submitted.count, answer.count)
        let longer = max(submitted.count, answer.count)
        guard shorter >= 4 else { return false }

        let distance = levenshteinDistance(submitted, answer)
        if longer <= 5 {
            return distance <= 1
        }
        if longer <= 10 {
            return distance <= 2
        }

        let similarity = Double(longer - distance) / Double(longer)
        return similarity >= 0.78
    }

    private static func hasEquivalentToken(_ submittedTokens: [String], _ answerTokens: [String]) -> Bool {
        for group in equivalentAnswerGroups {
            let normalizedGroup = Set(group.flatMap(normalizedTokens))
            guard !normalizedGroup.isDisjoint(with: submittedTokens) else { continue }
            if !normalizedGroup.isDisjoint(with: answerTokens) {
                return true
            }
        }
        return false
    }

    private static func levenshteinDistance(_ left: String, _ right: String) -> Int {
        let source = Array(left)
        let target = Array(right)
        guard !source.isEmpty else { return target.count }
        guard !target.isEmpty else { return source.count }

        var previous = Array(0...target.count)
        var current = Array(repeating: 0, count: target.count + 1)

        for sourceIndex in 1...source.count {
            current[0] = sourceIndex

            for targetIndex in 1...target.count {
                let cost = source[sourceIndex - 1] == target[targetIndex - 1] ? 0 : 1
                current[targetIndex] = min(
                    previous[targetIndex] + 1,
                    current[targetIndex - 1] + 1,
                    previous[targetIndex - 1] + cost
                )
            }

            swap(&previous, &current)
        }

        return previous[target.count]
    }

    private static var searchableCharacters: CharacterSet {
        CharacterSet.letters
            .union(.decimalDigits)
            .union(.nonBaseCharacters)
    }

    private static let equivalentAnswerGroups = [
        ["అమ్మ", "తల్లి", "mother", "mom"],
        ["నాన్న", "తండ్రి", "father", "dad"],
        ["చంద్రుడు", "చందమామ", "నెల", "moon"],
        ["సూర్యుడు", "భానుడు", "sun"],
        ["నీరు", "జలం", "water"],
        ["అగ్ని", "మంట", "fire"],
        ["భూమి", "నేల", "earth", "ground"],
        ["గాలి", "వాయువు", "air", "wind"],
        ["ఇల్లు", "గృహం", "home", "house"],
        ["పిల్లి", "cat"],
        ["కుక్క", "dog"]
    ]
}

private extension Set where Element == String {
    func isDisjoint(with values: [String]) -> Bool {
        isDisjoint(with: Set(values))
    }
}

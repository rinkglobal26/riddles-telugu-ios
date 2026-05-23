import XCTest
@testable import TeluguRiddles

final class AnswerValidatorTests: XCTestCase {
    func testAcceptsTeluguAnswerWithExtraSpacing() {
        XCTAssertTrue(AnswerValidator.isCorrect("  కొబ్బరి  కాయ ", for: sampleRiddle, mode: .telugu))
    }

    func testAcceptsEnglishAnswerInEnglishMode() {
        XCTAssertTrue(AnswerValidator.isCorrect("the coconut", for: sampleRiddle, mode: .english))
    }

    func testRejectsWrongAnswer() {
        XCTAssertFalse(AnswerValidator.isCorrect("మామిడి", for: sampleRiddle, mode: .hybrid))
    }

    private var sampleRiddle: Riddle {
        Riddle(
            id: 1,
            category: "ఇల్లు",
            englishCategory: "Home",
            difficulty: "సులువు",
            englishDifficulty: "Easy",
            question: "ప్రశ్న",
            englishQuestion: "Question",
            answer: "కొబ్బరి కాయ",
            englishAnswer: "Coconut",
            hint: "సూచన",
            englishHint: "Hint"
        )
    }
}

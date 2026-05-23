import XCTest
@testable import TeluguRiddles

final class AnswerValidatorTests: XCTestCase {
    func testAcceptsTeluguAnswerWithExtraSpacing() {
        XCTAssertTrue(AnswerValidator.isCorrect("  కొబ్బరి  కాయ ", for: sampleRiddle, mode: .telugu))
    }

    func testAcceptsEnglishAnswerInEnglishMode() {
        XCTAssertTrue(AnswerValidator.isCorrect("the coconut", for: sampleRiddle, mode: .english))
    }

    func testAcceptsPartialAnswer() {
        XCTAssertTrue(AnswerValidator.isCorrect("కొబ్బరి", for: sampleRiddle, mode: .telugu))
    }

    func testAcceptsCloseTypo() {
        XCTAssertTrue(AnswerValidator.isCorrect("cocnut", for: sampleRiddle, mode: .english))
    }

    func testAcceptsEquivalentMeaning() {
        let riddle = Riddle(
            id: 2,
            category: "ప్రకృతి",
            englishCategory: "Nature",
            difficulty: "సులువు",
            englishDifficulty: "Easy",
            question: "ప్రశ్న",
            englishQuestion: "Question",
            answer: "చంద్రుడు",
            englishAnswer: "Moon",
            hint: "సూచన",
            englishHint: "Hint"
        )

        XCTAssertTrue(AnswerValidator.isCorrect("చందమామ", for: riddle, mode: .telugu))
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

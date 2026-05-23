import XCTest
@testable import TeluguRiddles

final class RiddleLoadingTests: XCTestCase {
    func testBundledRiddleJSONDecodesCleanly() throws {
        let url = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "riddles", withExtension: "json"))
        let data = try Data(contentsOf: url)
        let riddles = try JSONDecoder().decode([Riddle].self, from: data)

        XCTAssertGreaterThanOrEqual(riddles.count, 1000)
        XCTAssertEqual(Set(riddles.map(\.id)).count, riddles.count)
        XCTAssertTrue(riddles.allSatisfy {
            !$0.question.isEmpty &&
            !$0.answer.isEmpty &&
            !$0.hint.isEmpty &&
            !$0.englishQuestion.isEmpty &&
            !$0.englishAnswer.isEmpty &&
            !$0.englishHint.isEmpty
        })
    }
}

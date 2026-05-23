import XCTest
@testable import TeluguRiddles

final class GameSessionTests: XCTestCase {
    func testCorrectAnswerAwardsPointAndRotatesTeam() {
        var session = GameSession(
            riddles: sampleRiddles,
            gameLength: .ten,
            teams: [GameTeam(name: "జట్టు 1"), GameTeam(name: "జట్టు 2")]
        )

        session.advance(scored: true)

        XCTAssertEqual(session.teams[0].score, 1)
        XCTAssertEqual(session.teams[1].score, 0)
        XCTAssertEqual(session.activeTeamIndex, 1)
        XCTAssertEqual(session.currentRiddle?.id, 2)
    }

    func testPassDoesNotAwardPoint() {
        var session = GameSession(
            riddles: sampleRiddles,
            gameLength: .ten,
            teams: [GameTeam(name: "జట్టు 1"), GameTeam(name: "జట్టు 2")]
        )

        session.advance(scored: false)

        XCTAssertEqual(session.teams.map(\.score), [0, 0])
        XCTAssertEqual(session.completedRounds, 1)
    }

    func testFixedLengthGameFinishesAtRoundLimit() {
        var session = GameSession(
            riddles: sampleRiddles,
            gameLength: .ten,
            teams: [GameTeam(name: "జట్టు 1")]
        )

        for _ in 0..<10 {
            session.advance(scored: false)
        }

        XCTAssertTrue(session.isFinished)
        XCTAssertEqual(session.completedRounds, 10)
    }

    func testSoloModeCanAdvanceWithoutTeams() {
        var session = GameSession(
            riddles: sampleRiddles,
            gameLength: .ten,
            teams: []
        )

        session.advance(scored: false)

        XCTAssertEqual(session.teams.count, 0)
        XCTAssertEqual(session.currentRiddle?.id, 2)
        XCTAssertEqual(session.progressText(for: .english), "Round 2 / 10")
    }

    private var sampleRiddles: [Riddle] {
        [
            Riddle(
                id: 1,
                category: "ఇల్లు",
                englishCategory: "Home",
                difficulty: "సులువు",
                englishDifficulty: "Easy",
                question: "ప్రశ్న 1",
                englishQuestion: "Question 1",
                answer: "జవాబు 1",
                englishAnswer: "Answer 1",
                hint: "సూచన 1",
                englishHint: "Hint 1"
            ),
            Riddle(
                id: 2,
                category: "ఇల్లు",
                englishCategory: "Home",
                difficulty: "సులువు",
                englishDifficulty: "Easy",
                question: "ప్రశ్న 2",
                englishQuestion: "Question 2",
                answer: "జవాబు 2",
                englishAnswer: "Answer 2",
                hint: "సూచన 2",
                englishHint: "Hint 2"
            )
        ]
    }
}

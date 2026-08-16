//
//  RankingEngineTests.swift
//  Gym TrakerTests
//
//  The worked examples in design/RANKING.md §5 are the contract. If these
//  drift, the ladder is lying to the user.
//

import Testing
@testable import Gym_Traker

private let lifter = LifterProfile(sex: .male, age: 27, bodyweightKg: 78)

struct RankingEngineTests {

    @Test func epleyEstimate() {
        #expect(abs(RankingEngine.e1RM(weightKg: 72.5, reps: 8) - 91.833) < 0.01)
        #expect(abs(RankingEngine.e1RM(weightKg: 115, reps: 6) - 138.0) < 0.01)
    }

    @Test func repsAreCappedAtTenForScoring() {
        // A 20-rep set must not score higher than a 10-rep set of the same load.
        #expect(RankingEngine.e1RM(weightKg: 100, reps: 20) == RankingEngine.e1RM(weightKg: 100, reps: 10))
    }

    @Test func benchWorkedExample() throws {
        let result = try #require(RankingEngine.rank(anchor: .bench, weightKg: 72.5, reps: 8, lifter: lifter))
        #expect(abs(result.value - 91.83) < 0.01)
        #expect(result.tier == .intermediate)
        #expect(result.division == 1)
        #expect(abs(result.score - 41.8) < 0.1)
        #expect(result.label == "Intermediate I")
    }

    @Test func squatWorkedExample() throws {
        let result = try #require(RankingEngine.rank(anchor: .squat, weightKg: 115, reps: 6, lifter: lifter))
        #expect(abs(result.value - 138.0) < 0.01)
        #expect(abs(result.score - 48.8) < 0.1)
        #expect(result.tier == .intermediate)
        #expect(result.division == 2)
    }

    @Test func meetingAStandardExactlyLandsAtTheBottomOfThatTier() throws {
        // 1.15 x 78 = 89.7 kg e1RM is the Intermediate threshold on bench.
        let result = try #require(RankingEngine.rank(anchor: .bench, weightKg: 89.7, reps: 0, lifter: lifter))
        #expect(result.tier == .intermediate)
        #expect(abs(result.score - 40.0) < 0.001)
        #expect(result.progressInTier < 0.001)
    }

    @Test func belowBeginnerScalesLinearlyFromZero() throws {
        // Half of the Beginner threshold (39 kg) should score half of 20.
        let result = try #require(RankingEngine.rank(anchor: .bench, weightKg: 19.5, reps: 0, lifter: lifter))
        #expect(result.tier == .beginner)
        #expect(abs(result.score - 10.0) < 0.001)
    }

    @Test func eliteBandCapsAtOneHundred() throws {
        // Elite bench threshold is 1.75 x 78 = 136.5 kg; +25 % reaches 100.
        let result = try #require(RankingEngine.rank(anchor: .bench, weightKg: 136.5 * 1.25, reps: 0, lifter: lifter))
        #expect(result.tier == .elite)
        #expect(abs(result.score - 100.0) < 0.001)

        let beyond = try #require(RankingEngine.rank(anchor: .bench, weightKg: 300, reps: 0, lifter: lifter))
        #expect(beyond.score == 100)
    }

    @Test func ageFactorLowersTheThresholds() throws {
        let masters = LifterProfile(sex: .male, age: 55, bodyweightKg: 78)
        let young = try #require(RankingEngine.rank(anchor: .bench, weightKg: 90, reps: 5, lifter: lifter))
        let older = try #require(RankingEngine.rank(anchor: .bench, weightKg: 90, reps: 5, lifter: masters))
        // Same lift, easier standard at 55 — the older lifter scores higher.
        #expect(older.score > young.score)
    }

    @Test func femaleStandardsUseTheirOwnTable() throws {
        let she = LifterProfile(sex: .female, age: 27, bodyweightKg: 60)
        // Intermediate bench for women is 0.70 x 60 = 42 kg e1RM.
        let result = try #require(RankingEngine.rank(anchor: .bench, weightKg: 42, reps: 0, lifter: she))
        #expect(result.tier == .intermediate)
        #expect(abs(result.score - 40.0) < 0.001)
    }

    @Test func bodyweightExercisesAreScoredOnReps() throws {
        // Male pull-up: Intermediate at 10 reps.
        let result = try #require(
            RankingEngine.rank(anchor: .bw, weightKg: 0, reps: 10, lifter: lifter, exerciseID: "pull-up")
        )
        #expect(result.isRepBased)
        #expect(result.tier == .intermediate)
        #expect(abs(result.score - 40.0) < 0.001)
    }

    @Test func addedLoadConvertsToEffectiveReps() throws {
        // 8 reps with +19.5 kg on a 78 kg lifter = 8 x 97.5/78 = 10 effective reps.
        let result = try #require(
            RankingEngine.rank(anchor: .bw, weightKg: 19.5, reps: 8, lifter: lifter, exerciseID: "pull-up")
        )
        #expect(abs(result.value - 10.0) < 0.001)
        #expect(result.tier == .intermediate)
    }

    @Test func globalLevelAveragesTheBigFourAndAddsConsistency() throws {
        // Four lifts at 40 with a full consistency bonus of 5.
        let result = try #require(
            RankingEngine.globalLevel(anchorScores: [.bench: 40, .squat: 40, .deadlift: 40, .ohp: 40],
                                      sessionsLast4Weeks: 16)
        )
        #expect(abs(result.score - 45.0) < 0.001)
        #expect(result.tier == .intermediate)
    }

    @Test func globalLevelIgnoresUntrainedLifts() throws {
        let result = try #require(
            RankingEngine.globalLevel(anchorScores: [.bench: 50, .squat: 30], sessionsLast4Weeks: 0)
        )
        #expect(abs(result.score - 40.0) < 0.001)
    }

    @Test func globalLevelIsUnrankedBelowTwoLifts() {
        #expect(RankingEngine.globalLevel(anchorScores: [.bench: 50], sessionsLast4Weeks: 8) == nil)
        #expect(RankingEngine.globalLevel(anchorScores: [:], sessionsLast4Weeks: 8) == nil)
    }

    @Test func consistencyBonusIsCappedAtFive() throws {
        let result = try #require(
            RankingEngine.globalLevel(anchorScores: [.bench: 40, .squat: 40], sessionsLast4Weeks: 40)
        )
        #expect(abs(result.score - 45.0) < 0.001)
    }

    @Test func divisionsSplitTheTierIntoThirds() throws {
        // Tier 2 spans 40–60. 40–46.67 is I, 46.67–53.33 is II, above is III.
        let first = try #require(RankingEngine.result(forScore: 41))
        let second = try #require(RankingEngine.result(forScore: 48))
        let third = try #require(RankingEngine.result(forScore: 58))
        #expect(first.division == 1)
        #expect(second.division == 2)
        #expect(third.division == 3)
    }
}

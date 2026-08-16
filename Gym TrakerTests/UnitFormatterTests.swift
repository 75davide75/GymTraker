//
//  UnitFormatterTests.swift
//  Gym TrakerTests
//
//  Switching kg/lb must never change a stored value.
//

import Testing
@testable import Gym_Traker

struct UnitFormatterTests {

    @Test func kilogramsPrintPlainly() {
        #expect(UnitFormatter.weight(72.5, in: .kg) == "72.5 kg")
        #expect(UnitFormatter.weight(70, in: .kg) == "70 kg")
    }

    @Test func poundsRoundToTheNearestHalf() {
        // 72.5 kg = 159.83 lb → 160
        #expect(UnitFormatter.weight(72.5, in: .lb) == "160 lb")
        // 20 kg = 44.09 lb → 44
        #expect(UnitFormatter.weight(20, in: .lb) == "44 lb")
    }

    @Test func displayConversionRoundTripsThroughKilograms() {
        #expect(UnitFormatter.kg(fromDisplay: 160, in: .lb) == 72.5)
        #expect(UnitFormatter.kg(fromDisplay: 72.5, in: .kg) == 72.5)
    }

    @Test func clockFormatsMinutesAndSeconds() {
        #expect(UnitFormatter.clock(105) == "1:45")
        #expect(UnitFormatter.clock(60) == "1:00")
        #expect(UnitFormatter.clock(9) == "0:09")
        #expect(UnitFormatter.clock(-5) == "0:00")
    }

    @Test func restPillsReadNaturally() {
        #expect(UnitFormatter.rest(45) == "45s")
        #expect(UnitFormatter.rest(120) == "2m")
        #expect(UnitFormatter.rest(90) == "1m 30s")
    }
}

//
//  ChangeRecord.swift
//  Gym Traker
//
//  The change registry. Append-only: nothing here is ever edited or deleted,
//  which is what makes "when did this last move" answerable.
//

import Foundation
import SwiftData

@Model
final class ChangeRecord {
    var date: Date = Date.now
    var exerciseID: String = ""
    var exerciseName: String = ""
    var fieldRaw: String = ChangeField.weight.rawValue
    /// Display strings, already formatted in the user's units at write time.
    var fromValue: String = ""
    var toValue: String = ""
    var directionRaw: String = ChangeDirection.neutral.rawValue
    var sessionUUID: UUID?

    init(
        date: Date = .now,
        exerciseID: String,
        exerciseName: String,
        field: ChangeField,
        fromValue: String,
        toValue: String,
        direction: ChangeDirection,
        sessionUUID: UUID? = nil
    ) {
        self.date = date
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.fieldRaw = field.rawValue
        self.fromValue = fromValue
        self.toValue = toValue
        self.directionRaw = direction.rawValue
        self.sessionUUID = sessionUUID
    }

    var field: ChangeField { ChangeField(rawValue: fieldRaw) ?? .weight }
    var direction: ChangeDirection { ChangeDirection(rawValue: directionRaw) ?? .neutral }

    /// "Weight · 70 kg → 72.5 kg"
    var summary: String {
        switch field {
        case .added, .removed:
            return "\(field.displayName) · \(toValue)"
        default:
            return "\(field.displayName) · \(fromValue) → \(toValue)"
        }
    }
}

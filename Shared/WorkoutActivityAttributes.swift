//
//  WorkoutActivityAttributes.swift
//  Shared between the app and the widget extension
//
//  The shape of the Live Activity. It lives in its own folder because both the
//  app and the widget extension compile it — the app starts and updates the
//  activity, the extension draws it.
//

import Foundation
import ActivityKit

struct WorkoutActivityAttributes: ActivityAttributes {

    /// What changes while the session runs.
    struct ContentState: Codable, Hashable {
        /// When the running phase ends. Nil while working, since work has no
        /// deadline — only rest counts down.
        var restEndsAt: Date?
        /// When the session itself started, for the elapsed clock.
        var sessionStartedAt: Date
        var exerciseName: String
        var nextSetNumber: Int
        var completedSets: Int
        var totalSets: Int

        var isResting: Bool {
            guard let restEndsAt else { return false }
            return restEndsAt > .now
        }
    }

    /// Fixed for the life of the activity.
    var dayTitle: String
}

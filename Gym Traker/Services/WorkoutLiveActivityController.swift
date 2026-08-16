//
//  WorkoutLiveActivityController.swift
//  Gym Traker
//
//  Puts the running session in the Dynamic Island and on the Lock Screen.
//
//  The activity carries dates rather than counts: the rest deadline and the
//  session start. The system draws the moving digits from those, so the timer
//  stays right while the app is asleep in a pocket — which is exactly when you
//  need to see it.
//

import Foundation
import ActivityKit

@Observable
final class WorkoutLiveActivityController {

    private var activity: Activity<WorkoutActivityAttributes>?

    var isRunning: Bool { activity != nil }

    /// True when the device allows Live Activities at all.
    var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    // MARK: - Lifecycle

    func start(dayTitle: String, state: WorkoutActivityAttributes.ContentState) {
        guard isAvailable, activity == nil else { return }
        do {
            activity = try Activity.request(
                attributes: WorkoutActivityAttributes(dayTitle: dayTitle),
                content: ActivityContent(state: state, staleDate: nil)
            )
        } catch {
            // A refused activity is not worth interrupting a workout over.
            activity = nil
        }
    }

    func update(_ state: WorkoutActivityAttributes.ContentState) {
        guard let activity else { return }
        Task {
            await activity.update(ActivityContent(state: state, staleDate: nil))
        }
    }

    func end() {
        guard let activity else { return }
        self.activity = nil
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}

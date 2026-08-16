//
//  WorkoutLiveActivity.swift
//  GymTrakerWidgets
//
//  The session in the Dynamic Island and on the Lock Screen.
//
//  Two states share one layout: resting counts a rest down, working counts the
//  session up. Both use `Text(timerInterval:)` so the numbers keep moving
//  without the app being awake to push them.
//

import ActivityKit
import SwiftUI
import WidgetKit

@main
struct GymTrakerWidgetsBundle: WidgetBundle {
    var body: some Widget {
        WorkoutLiveActivity()
    }
}

struct WorkoutLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
            lockScreen(context)
                .activityBackgroundTint(Color.black.opacity(0.55))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    label(context.state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    clock(context.state)
                        .font(.system(size: 26, weight: .heavy))
                        .monospacedDigit()
                        .foregroundStyle(accent(context.state))
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(context.state.exerciseName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                        progress(context.state)
                    }
                }
            } compactLeading: {
                Image(systemName: context.state.isResting ? "hourglass" : "figure.strengthtraining.traditional")
                    .foregroundStyle(accent(context.state))
            } compactTrailing: {
                clock(context.state)
                    .font(.system(size: 13, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accent(context.state))
                    .frame(maxWidth: 54)
            } minimal: {
                Image(systemName: context.state.isResting ? "hourglass" : "flame.fill")
                    .foregroundStyle(accent(context.state))
            }
            .keylineTint(accent(context.state))
        }
    }

    // MARK: - Pieces

    private func lockScreen(_ context: ActivityViewContext<WorkoutActivityAttributes>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                label(context.state)
                Spacer()
                clock(context.state)
                    .font(.system(size: 30, weight: .heavy))
                    .monospacedDigit()
                    .foregroundStyle(accent(context.state))
            }

            Text(context.state.isResting
                 ? "Next · \(context.state.exerciseName) set \(context.state.nextSetNumber)"
                 : context.state.exerciseName)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)

            progress(context.state)
        }
        .padding(16)
    }

    private func label(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(state.isResting ? "RESTING" : "WORKING")
                .font(.system(size: 10, weight: .bold))
                .tracking(1.1)
                .foregroundStyle(accent(state))
            Text("\(state.completedSets)/\(state.totalSets) sets")
                .font(.system(size: 12, weight: .semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }

    /// Rest counts down to its end; work counts up from the session start.
    /// Either way the system keeps the digits moving on its own.
    @ViewBuilder
    private func clock(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        if let restEndsAt = state.restEndsAt, restEndsAt > .now {
            Text(timerInterval: Date.now...restEndsAt, countsDown: true)
                .multilineTextAlignment(.trailing)
        } else {
            Text(state.sessionStartedAt, style: .timer)
                .multilineTextAlignment(.trailing)
        }
    }

    private func progress(_ state: WorkoutActivityAttributes.ContentState) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.16))
                Capsule()
                    .fill(accent(state))
                    .frame(width: geometry.size.width * fraction(state))
            }
        }
        .frame(height: 6)
    }

    private func fraction(_ state: WorkoutActivityAttributes.ContentState) -> Double {
        guard state.totalSets > 0 else { return 0 }
        return min(1, Double(state.completedSets) / Double(state.totalSets))
    }

    /// Red while working, cool while resting — the same sport-mode split the
    /// session screen uses.
    private func accent(_ state: WorkoutActivityAttributes.ContentState) -> Color {
        state.isResting
            ? Color(red: 0.176, green: 0.702, blue: 0.847)
            : Color(red: 0.949, green: 0.278, blue: 0.271)
    }
}

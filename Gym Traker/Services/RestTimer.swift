//
//  RestTimer.swift
//  Gym Traker
//
//  The rest countdown. Time is derived from a stored fire date rather than
//  counted down in memory, so backgrounding the app — which is what happens
//  when you put the phone in your pocket between sets — never loses time.
//

import Foundation
import Observation
import UserNotifications
import AudioToolbox

@Observable
final class RestTimer {

    /// When the current rest ends. Nil when not resting.
    /// Read by the Live Activity so the system can count the rest down.
    private(set) var fireDate: Date?
    private(set) var totalSeconds: Int = 0
    private(set) var exerciseName: String = ""
    private(set) var nextSetNumber: Int = 1

    /// Ticks once a second purely to refresh the UI; the value shown is always
    /// recomputed from `fireDate`.
    private(set) var now: Date = .now
    private var timer: Timer?

    private let notificationID = "gym-traker.rest"

    var isResting: Bool {
        guard let fireDate else { return false }
        return fireDate > now
    }

    var remainingSeconds: Int {
        guard let fireDate else { return 0 }
        return max(0, Int(fireDate.timeIntervalSince(now).rounded(.up)))
    }

    /// 1 at the start of the rest, 0 when it ends.
    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return max(0, min(1, Double(remainingSeconds) / Double(totalSeconds)))
    }

    /// The last five seconds pulse the ring.
    var isFinishing: Bool { isResting && remainingSeconds <= 5 }

    /// Seconds served in the rest currently running.
    var elapsedInCurrentRest: Int {
        guard isResting else { return 0 }
        return max(0, totalSeconds - remainingSeconds)
    }

    /// Length of the rest that just ended, for the session's work/rest split.
    private(set) var lastRestDuration: Int = 0

    // MARK: - Control

    /// How the end of a rest announces itself.
    var alert: RestAlert = .soundAndHaptics

    func start(seconds: Int, exerciseName: String, nextSetNumber: Int, notify: Bool) {
        guard seconds > 0 else { return }
        self.totalSeconds = seconds
        self.exerciseName = exerciseName
        self.nextSetNumber = nextSetNumber
        self.fireDate = Date.now.addingTimeInterval(TimeInterval(seconds))
        self.now = .now

        startTicking()
        if notify { scheduleNotification(in: seconds, exerciseName: exerciseName, setNumber: nextSetNumber) }
    }

    func skip() {
        stop()
    }

    func stop() {
        lastRestDuration = fireDate == nil ? 0 : totalSeconds
        fireDate = nil
        totalSeconds = 0
        timer?.invalidate()
        timer = nil
        cancelNotification()
    }

    /// Called when the app returns to the foreground so the readout catches up
    /// with real time immediately.
    func refresh() {
        now = .now
        if let fireDate, fireDate <= now { stop() }
    }

    private func startTicking() {
        timer?.invalidate()
        let timer = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                self.now = .now
                if let fire = self.fireDate, fire <= self.now {
                    self.stop()
                    self.announceEnd()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    /// Rest is over. What that sounds like is the user's choice: a chime with
    /// vibration, vibration alone, or nothing at all for a quiet gym.
    private func announceEnd() {
        switch alert {
        case .soundAndHaptics:
            AudioServicesPlaySystemSound(1057)
            Haptics.play(.success)
        case .hapticsOnly:
            Haptics.play(.success)
        case .silent:
            break
        }
    }

    // MARK: - Notifications

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(in seconds: Int, exerciseName: String, setNumber: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest over"
        content.body = "\(exerciseName) · set \(setNumber)"
        content.sound = alert.playsSound ? .default : nil

        let request = UNNotificationRequest(
            identifier: notificationID,
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(seconds), repeats: false)
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func cancelNotification() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [notificationID])
    }
}

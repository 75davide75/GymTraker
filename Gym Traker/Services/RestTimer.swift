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

@Observable
final class RestTimer {

    /// When the current rest ends. Nil when not resting.
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

    // MARK: - Control

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
                    Haptics.success()
                }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    // MARK: - Notifications

    static func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func scheduleNotification(in seconds: Int, exerciseName: String, setNumber: Int) {
        let content = UNMutableNotificationContent()
        content.title = "Rest over"
        content.body = "\(exerciseName) · set \(setNumber)"
        content.sound = .default

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

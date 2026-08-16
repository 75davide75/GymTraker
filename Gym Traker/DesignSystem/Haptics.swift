//
//  Haptics.swift
//  Gym Traker
//
//  design/SPEC.md §3 asked for haptics on set completion, weight changes and
//  session milestones. This covers the rest of the app too: anything that
//  commits a change, moves you somewhere, or completes something gets a tap.
//
//  Generators are prepared before use so the first tap of a run is not late.
//

import UIKit

enum Haptics {

    /// Named intents rather than raw styles, so call sites read as what they
    /// mean and the feel can be tuned in one place.
    enum Style {
        /// A control was pressed down.
        case press
        /// A value moved by one step.
        case step
        /// A selection changed between discrete options.
        case selection
        /// Something meaningful was committed.
        case commit
        /// A destructive action went through.
        case remove
        /// Something finished successfully.
        case success
        /// Something could not be done.
        case failure

        func fire() {
            switch self {
            case .press: impact(.light, intensity: 0.55)
            case .step: impact(.light)
            case .selection: Haptics.selectionGenerator.selectionChanged()
            case .commit: impact(.medium)
            case .remove: impact(.rigid)
            case .success: Haptics.notificationGenerator.notificationOccurred(.success)
            case .failure: Haptics.notificationGenerator.notificationOccurred(.warning)
            }
        }

        private func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle, intensity: CGFloat = 1) {
            let generator = Haptics.impactGenerator(style)
            generator.impactOccurred(intensity: intensity)
        }
    }

    static func play(_ style: Style) { style.fire() }

    // MARK: - Legacy shorthands used across the app

    static func light() { Style.step.fire() }
    static func medium() { Style.commit.fire() }
    static func soft() { Style.press.fire() }
    static func success() { Style.success.fire() }
    static func selection() { Style.selection.fire() }

    // MARK: - Prepared generators

    private static let selectionGenerator: UISelectionFeedbackGenerator = {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        return generator
    }()

    private static let notificationGenerator: UINotificationFeedbackGenerator = {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        return generator
    }()

    private static var impactGenerators: [UIImpactFeedbackGenerator.FeedbackStyle: UIImpactFeedbackGenerator] = [:]

    private static func impactGenerator(_ style: UIImpactFeedbackGenerator.FeedbackStyle) -> UIImpactFeedbackGenerator {
        if let existing = impactGenerators[style] { return existing }
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        impactGenerators[style] = generator
        return generator
    }
}

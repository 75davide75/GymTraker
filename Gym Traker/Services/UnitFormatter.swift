//
//  UnitFormatter.swift
//  Gym Traker
//
//  Weights are stored in kilograms everywhere. This is the only place that
//  turns them into something the user reads, so switching kg/lb can never
//  change a stored value.
//

import Foundation

enum UnitFormatter {

    /// "72.5 kg" / "160 lb"
    static func weight(_ kg: Double, in units: Units) -> String {
        "\(number(kg, in: units)) \(units.rawValue)"
    }

    /// "72.5" — the number alone, for steppers and hero readouts that draw
    /// their own unit label.
    static func number(_ kg: Double, in units: Units) -> String {
        trim(display(kg, in: units))
    }

    /// The numeric value in the display unit, rounded to the nearest 0.5.
    static func display(_ kg: Double, in units: Units) -> Double {
        (kg * units.factor * 2).rounded() / 2
    }

    /// Converts a value the user sees back into stored kilograms.
    static func kg(fromDisplay value: Double, in units: Units) -> Double {
        let raw = value / units.factor
        return (raw * 2).rounded() / 2
    }

    /// "1,240 kg" — volume totals, rounded to whole units.
    static func volume(_ kg: Double, in units: Units) -> String {
        let value = (kg * units.factor).rounded()
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let text = formatter.string(from: NSNumber(value: value)) ?? "\(Int(value))"
        return "\(text) \(units.rawValue)"
    }

    /// "1:45" for a duration in seconds.
    static func clock(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%d:%02d", s / 60, s % 60)
    }

    /// "90s" / "1m 30s" for rest pills.
    static func rest(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds)s" : (seconds % 60 == 0 ? "\(seconds / 60)m" : "\(seconds / 60)m \(seconds % 60)s")
    }

    /// Drops a trailing ".0" so 160.0 reads as "160" but 72.5 stays "72.5".
    private static func trim(_ value: Double) -> String {
        value == value.rounded()
            ? String(Int(value.rounded()))
            : String(format: "%.1f", value)
    }
}

extension Date {
    /// "now · 8s · 12m · 3h · 2d", then a plain date past a week. Fixed-width
    /// enough that a registry row never truncates it.
    var compactRelative: String {
        let seconds = Int(Date.now.timeIntervalSince(self))
        switch seconds {
        case ..<5: return "now"
        case ..<60: return "\(seconds)s"
        case ..<3600: return "\(seconds / 60)m"
        case ..<86_400: return "\(seconds / 3600)h"
        case ..<604_800: return "\(seconds / 86_400)d"
        default: return formatted(.dateTime.day().month(.abbreviated))
        }
    }
}

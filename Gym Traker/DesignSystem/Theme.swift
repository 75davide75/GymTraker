//
//  Theme.swift
//  Gym Traker
//
//  The design tokens from design/SPEC.md §4, converted from oklch to sRGB.
//  Nothing else in the app hard-codes a colour, a radius or a font size.
//

import SwiftUI

enum Theme {

    // MARK: - Palette

    enum Palette {
        /// Primary accent — oklch(0.68 0.17 268)
        static let violet = Color(red: 0.421, green: 0.566, blue: 1.000)
        /// Deeper violet used in the gradient blooms — oklch(0.58 0.19 288)
        static let violetDeep = Color(red: 0.474, green: 0.374, blue: 0.886)
        /// Secondary accent — oklch(0.72 0.15 200)
        static let cyan = Color(red: 0.000, green: 0.750, blue: 0.790)
        /// Increases — oklch(0.8 0.14 145)
        static let increase = Color(red: 0.504, green: 0.837, blue: 0.518)
        /// Decreases — oklch(0.78 0.15 30)
        static let decrease = Color(red: 1.000, green: 0.562, blue: 0.489)

        /// Sport mode. A session is the one screen where the app stops being
        /// calm: the accents run hot, the way a car's dashboard does when you
        /// put it in the aggressive setting.
        static let sportRed = Color(red: 0.949, green: 0.278, blue: 0.271)
        static let sportEmber = Color(red: 0.976, green: 0.478, blue: 0.180)
        /// Rest is the cool half of that dashboard.
        static let sportCool = Color(red: 0.176, green: 0.702, blue: 0.847)

        static let backgroundDark = Color(red: 0.027, green: 0.027, blue: 0.039)   // #07070A
        static let backgroundLight = Color(red: 0.937, green: 0.941, blue: 0.961)  // #EFF0F5

        static func background(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? backgroundDark : backgroundLight
        }

        /// Hairline stroke: 12 % white on dark, 9 % black on light.
        static func stroke(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.09)
        }

        /// The inset highlight along the top edge of a glass surface.
        static func topHighlight(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.22) : Color.white.opacity(0.90)
        }

        static func separator(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.09) : Color.black.opacity(0.08)
        }

        static func track(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.12) : Color.black.opacity(0.10)
        }

        static func fill(_ scheme: ColorScheme) -> Color {
            scheme == .dark ? Color.white.opacity(0.16) : Color.black.opacity(0.13)
        }

        /// Turns an archive glyph hue into a colour, so every diagram in the
        /// library is tinted from the same generator.
        static func glyph(hue: Int, scheme: ColorScheme = .dark) -> Color {
            Color(
                hue: Double(hue % 360) / 360,
                saturation: scheme == .dark ? 0.62 : 0.70,
                brightness: scheme == .dark ? 0.92 : 0.80
            )
        }

        static func direction(_ direction: ChangeDirection) -> Color {
            switch direction {
            case .up: increase
            case .down: decrease
            case .neutral: .secondary
            }
        }
    }

    // MARK: - Corner radii

    enum Radius {
        static let hero: CGFloat = 30
        static let card: CGFloat = 26
        static let bar: CGFloat = 26
        static let row: CGFloat = 22
        static let control: CGFloat = 18
        static let smallControl: CGFloat = 16
        static let chip: CGFloat = 14
    }

    enum Spacing {
        /// Matches the inset iOS gives a large navigation title, so a heading
        /// and the content under it share one left edge instead of missing each
        /// other by four points.
        static let screenMargin: CGFloat = 16
        static let cardPadding: CGFloat = 18
        static let stack: CGFloat = 14
    }

    // MARK: - Motion

    enum Motion {
        /// Card expand/collapse and screen transitions.
        static let spring = Animation.spring(response: 0.42, dampingFraction: 0.86)
        /// Steppers and other immediate controls.
        static let snappy = Animation.snappy(duration: 0.24, extraBounce: 0.02)
        /// Entry stagger, capped at eight children.
        static let entryDuration: Double = 0.4
        static let entryOffset: CGFloat = 14
        static let staggerStep: Double = 0.03
        static let staggerCap = 8

        static func stagger(_ index: Int) -> Double {
            Double(min(index, staggerCap)) * staggerStep
        }
    }
}

// MARK: - Typography

extension Font {
    /// 30 / bold — hero numbers and screen titles.
    static let displayL = Font.system(size: 30, weight: .bold).monospacedDigit()
    /// 22 / bold — card titles.
    static let titleL = Font.system(size: 22, weight: .bold)
    /// 17 / semibold — row titles.
    static let titleS = Font.system(size: 17, weight: .semibold)
    /// 15 / semibold — body copy.
    static let bodyM = Font.system(size: 15, weight: .semibold)
    /// 13 / medium — supporting copy.
    static let bodyS = Font.system(size: 13, weight: .medium)
    /// 12 / semibold — captions.
    static let captionM = Font.system(size: 12, weight: .semibold)
    /// 11 / semibold — uppercase section labels, needs `.tracking(1.2)`.
    static let overline = Font.system(size: 11, weight: .semibold)

    /// Tabular variants for anything numeric.
    static let numberL = Font.system(size: 30, weight: .bold).monospacedDigit()
    static let numberM = Font.system(size: 20, weight: .bold).monospacedDigit()
    static let numberS = Font.system(size: 15, weight: .semibold).monospacedDigit()
}

extension View {
    /// Uppercase section label: 11 pt, 1.2 pt tracking, secondary.
    func overlineStyle() -> some View {
        self.font(.overline)
            .tracking(1.2)
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
    }
}

//
//  ContentView.swift
//  Gym Traker
//
//  Temporary design-system gallery. Replaced by the tab bar in Task 10.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var exercises: [Exercise]
    @State private var weight: Double = 72.5
    @State private var reps = 8
    @State private var selectedChip = "Barbell"

    private let shapes = ["bar", "dumbbell", "frame", "cable", "ring", "bell", "wave", "arc"]
    private let hues = [268, 200, 260, 150, 40, 20, 330, 100]

    var body: some View {
        ZStack {
            AuroraBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Text("Gym Tracker")
                        .font(.displayL)
                        .entryTransition(0)

                    Text("\(exercises.count) exercises in the archive")
                        .font(.bodyS)
                        .foregroundStyle(.secondary)
                        .entryTransition(1)

                    GlassSection(title: "Glyph grammar") {
                        VStack(spacing: 16) {
                            ForEach(0..<2) { row in
                                HStack(spacing: 14) {
                                    ForEach(0..<4) { column in
                                        let index = row * 4 + column
                                        ExerciseGlyph(shape: shapes[index], hue: hues[index], size: 56)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .entryTransition(2)

                    GlassSection(title: "Working weight") {
                        WeightStepper(weightKg: weight, stepKg: 2.5, units: .kg, isSuggested: true) {
                            weight = $0
                        }
                    }
                    .entryTransition(3)

                    GlassSection(title: "Set 3") {
                        HStack {
                            Text("8 reps target").font(.bodyM)
                            Spacer()
                            RepsStepper(reps: reps) { reps = $0 }
                        }
                    }
                    .entryTransition(4)

                    GlassSection(title: "Filters") {
                        HStack(spacing: 8) {
                            ForEach(["All", "Barbell", "Cable"], id: \.self) { name in
                                GlassChip(title: name, isSelected: selectedChip == name) {
                                    selectedChip = name
                                }
                            }
                        }
                    }
                    .entryTransition(5)

                    GlassSection(title: "Progress to Advanced") {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Intermediate I").font(.titleL)
                            GlassProgressBar(value: 0.42, tint: Tier.intermediate.tint)
                        }
                    }
                    .entryTransition(6)
                }
                .padding(Theme.Spacing.screenMargin)
            }
        }
    }
}

#Preview {
    ContentView()
}

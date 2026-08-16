//
//  ContentView.swift
//  Gym Traker
//
//  Created by Davide Sogos on 16/08/2026.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query private var exercises: [Exercise]

    var body: some View {
        VStack(spacing: 8) {
            Text("Gym Tracker")
                .font(.largeTitle.bold())
            Text("\(exercises.count) exercises in the archive")
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}

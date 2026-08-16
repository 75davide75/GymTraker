//
//  ContentView.swift
//  Gym Traker
//
//  Created by Davide Sogos on 16/08/2026.
//
//  Root: onboarding until a profile exists, then the five-tab bar.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(HealthStore.self) private var health
    @Environment(\.scenePhase) private var scenePhase
    @Query private var profiles: [UserProfile]

    private var profile: UserProfile? { profiles.first }

    var body: some View {
        Group {
            if profile == nil {
                OnboardingView()
                    .transition(.opacity.combined(with: .scale(scale: 1.02)))
            } else {
                RootTabView()
                    .transition(.opacity)
            }
        }
        .animation(Theme.Motion.spring, value: profile == nil)
        // Watch workouts land in Health when they end, so pull on foreground.
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, health.availability == .ready else { return }
            Task { await health.importWorkouts(into: context) }
        }
        .preferredColorScheme(profile?.appearance.colorScheme ?? .dark)
        .tint(Theme.Palette.violet)
    }
}

struct RootTabView: View {
    /// Named AppSection rather than Tab so it does not shadow SwiftUI's Tab.
    enum AppSection: Hashable {
        case home, plan, library, registry, you
    }

    @State private var selection: AppSection = .home

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "house.fill", value: AppSection.home) {
                NavigationStack {
                    HomeView(onOpenPlan: { selection = .plan })
                }
            }

            Tab("Plan", systemImage: "calendar", value: AppSection.plan) {
                NavigationStack { PlanEditorView() }
            }

            Tab("Library", systemImage: "square.grid.2x2.fill", value: AppSection.library) {
                NavigationStack { LibraryView() }
            }

            Tab("Registry", systemImage: "clock.arrow.circlepath", value: AppSection.registry) {
                NavigationStack { RegistryView() }
            }

            Tab("You", systemImage: "person.fill", value: AppSection.you) {
                NavigationStack { YouView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    ContentView()
}

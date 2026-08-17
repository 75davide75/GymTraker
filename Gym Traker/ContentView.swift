//
//  ContentView.swift
//  Gym Traker
//
//  Created by Davide Sogos on 16/08/2026.
//
//  Root: onboarding until a profile exists, then the five sections.
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
    enum AppSection: String, Hashable, Identifiable, CaseIterable {
        case home, plan, library, registry, you

        var id: String { rawValue }

        var title: String {
            switch self {
            case .home: "Home"
            case .plan: "Plan"
            case .library: "Library"
            case .registry: "Log"
            case .you: "You"
            }
        }

        var symbol: String {
            switch self {
            case .home: "house"
            case .plan: "calendar"
            case .library: "square.grid.2x2"
            case .registry: "clock.arrow.circlepath"
            case .you: "person"
            }
        }

        var aurora: AuroraVariant {
            switch self {
            case .home: .home
            case .plan: .plan
            case .library: .library
            case .registry: .registry
            case .you: .profile
            }
        }
    }

    @State private var selection: AppSection = .home
    @State private var chrome = ChromeState()

    /// The system tab view, on top of the one aurora.
    ///
    /// A bespoke bar and pager were tried first, to get swiping between
    /// sections. Every version cost more than it bought: a drag gesture stole
    /// horizontal scrolls, then delayed every tap; a paging scroll view never
    /// turned a page, because the vertical scroll on each screen wins the
    /// gesture; a page-style TabView finally swiped, but it is backed by a page
    /// controller whose children get no layout margins and no scroll edge
    /// behaviour — large titles came out flush against the left edge, the bar
    /// sat on top of the last row of every list, and the hand-rolled glass was
    /// a flat panel next to the real thing.
    ///
    /// The system bar is actual Liquid Glass, minimises itself on scroll, and
    /// reserves the space its own height needs. What it does not do is swipe,
    /// which is why the gradient behind it animates instead: moving between
    /// sections is a change of light, not a slide.
    var body: some View {
        TabView(selection: $selection) {
            Tab(AppSection.home.title, systemImage: AppSection.home.symbol, value: .home) {
                NavigationStack { HomeView(onOpenPlan: { selection = .plan }) }
            }
            Tab(AppSection.plan.title, systemImage: AppSection.plan.symbol, value: .plan) {
                NavigationStack { PlanEditorView() }
            }
            Tab(AppSection.library.title, systemImage: AppSection.library.symbol, value: .library) {
                NavigationStack { LibraryView() }
            }
            Tab(AppSection.registry.title, systemImage: AppSection.registry.symbol, value: .registry) {
                NavigationStack { RegistryView() }
            }
            Tab(AppSection.you.title, systemImage: AppSection.you.symbol, value: .you) {
                NavigationStack { YouView() }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .environment(chrome)
    }
}

#Preview {
    ContentView()
}

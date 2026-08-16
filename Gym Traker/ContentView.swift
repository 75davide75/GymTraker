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
            case .registry: "Registry"
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
    }

    @State private var selection: AppSection = .home
    @State private var isBarCompact = false

    var body: some View {
        ZStack(alignment: .bottom) {
            pages
            GlassTabBar(
                selection: $selection,
                items: AppSection.allCases.map {
                    GlassTabBar.Item(section: $0, title: $0.title, symbol: $0.symbol)
                },
                isCompact: isBarCompact
            )
        }
        .onPreferenceChange(ScrollDirectionKey.self) { goingDown in
            guard isBarCompact != goingDown else { return }
            isBarCompact = goingDown
        }
    }

    /// Paging TabView, with the system bar hidden and our own drawn on top.
    ///
    /// Three approaches got here. A drag gesture on the standard TabView stole
    /// horizontal scrolls as a simultaneous gesture and delayed every tap as a
    /// plain one. A horizontal paging ScrollView fixed the taps but swallowed
    /// the swipe: with a vertical scroll view on each page, the inner one wins
    /// the gesture and the page never turns. A page-style TabView is backed by
    /// UIPageViewController, which is built for exactly this nesting — so the
    /// swipe lands, the slide is interactive, and each screen carries its own
    /// gradient across with it.
    private var pages: some View {
        TabView(selection: $selection) {
            ForEach(AppSection.allCases) { section in
                screen(section)
                    .tag(section)
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .ignoresSafeArea()
        .background(Theme.Palette.backgroundDark.ignoresSafeArea())
    }

    @ViewBuilder
    private func screen(_ section: AppSection) -> some View {
        switch section {
        case .home:
            NavigationStack { HomeView(onOpenPlan: { selection = .plan }) }
        case .plan:
            NavigationStack { PlanEditorView() }
        case .library:
            NavigationStack { LibraryView() }
        case .registry:
            NavigationStack { RegistryView() }
        case .you:
            NavigationStack { YouView() }
        }
    }
}

#Preview {
    ContentView()
}

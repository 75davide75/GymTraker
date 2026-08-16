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
    /// Where the pager actually sits, which trails `selection` during a drag.
    @State private var scrolled: AppSection?

    var body: some View {
        ZStack(alignment: .bottom) {
            pages
            GlassTabBar(
                selection: $selection,
                items: AppSection.allCases.map {
                    GlassTabBar.Item(section: $0, title: $0.title, symbol: $0.symbol)
                }
            )
        }
        .onChange(of: selection) { _, section in
            guard scrolled != section else { return }
            withAnimation(.snappy(duration: 0.35, extraBounce: 0.05)) { scrolled = section }
        }
        .onChange(of: scrolled) { _, section in
            guard let section, selection != section else { return }
            selection = section
        }
        .task { scrolled = selection }
    }

    /// A paging scroll rather than a TabView.
    ///
    /// Swiping anywhere moves between sections and each screen carries its own
    /// gradient across as it slides. It also fixes two problems a hand-rolled
    /// drag gesture caused: as a simultaneous gesture it stole horizontal
    /// scrolls from chip rows, and as a plain gesture it delayed every tap in
    /// the app. Nested scroll views are something UIKit already arbitrates.
    private var pages: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(AppSection.allCases) { section in
                    screen(section)
                        .containerRelativeFrame(.horizontal)
                        .id(section)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolled)
        .scrollIndicators(.hidden)
        .ignoresSafeArea(edges: .bottom)
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

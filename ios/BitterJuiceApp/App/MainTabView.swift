import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0
    /// Only mount a tab’s root after it has been opened once — avoids 5× `.task`/network at cold start.
    @State private var loadedTabs: Set<Int> = [0]

    /// Ensures `loadedTabs` is updated in the same transaction as `selectedTab` (avoids one blank frame).
    private var tabSelection: Binding<Int> {
        Binding(
            get: { selectedTab },
            set: { newValue in
                loadedTabs.insert(newValue)
                selectedTab = newValue
            }
        )
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Group {
                if loadedTabs.contains(0) {
                    DashboardView()
                } else {
                    Color.clear
                }
            }
            .tag(0)
            .tabItem {
                Label("Today", systemImage: "sparkles")
            }

            Group {
                if loadedTabs.contains(1) {
                    ActivityLogView()
                } else {
                    Color.clear
                }
            }
            .tag(1)
            .tabItem {
                Label("Log", systemImage: "bolt.badge.clock")
            }

            Group {
                if loadedTabs.contains(2) {
                    SquadFeedView()
                } else {
                    Color.clear
                }
            }
            .tag(2)
            .tabItem {
                Label("Crew", systemImage: "person.3.sequence.fill")
            }

            Group {
                if loadedTabs.contains(3) {
                    RewardsVaultView()
                } else {
                    Color.clear
                }
            }
            .tag(3)
            .tabItem {
                Label("Rewards", systemImage: "trophy.fill")
            }

            Group {
                if loadedTabs.contains(4) {
                    ProfileView()
                } else {
                    Color.clear
                }
            }
            .tag(4)
            .tabItem {
                Label("Me", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(.pink)
        .onAppear {
            loadedTabs.insert(selectedTab)
        }
    }
}

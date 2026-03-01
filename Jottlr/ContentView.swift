import SwiftUI
import SwiftData

enum AppTab: String, CaseIterable {
    case capture = "Capture"
    case jotlog = "Jotlog"
}

struct ContentView: View {
    @State private var selectedTab: AppTab = .capture

    var body: some View {
        VStack(spacing: 0) {
            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(AppTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 8)

            Divider()

            // Tab content
            switch selectedTab {
            case .capture:
                QuickCaptureView()
            case .jotlog:
                JotlogView()
                    .frame(height: 400)
            }
        }
        .frame(width: 400)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Jotting.self, inMemory: true)
}

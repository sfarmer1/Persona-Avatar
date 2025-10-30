import SwiftUI
import Combine
import AVKit

@MainActor
final class FocusCoordinator: ObservableObject {
    
    static let shared = FocusCoordinator()
    @Published var currentWindowID: String? = nil
    private init() {}
    func focus(windowID: String) { currentWindowID = windowID }
    func isFocused(windowID: String) -> Bool { currentWindowID == windowID }
}

struct CameraLauncherView: View {
    let windowID: String
    @StateObject private var coordinator = FocusCoordinator.shared
    @Environment(\.openWindow) private var openWindow
    @State private var didLaunch = false
    @FocusState private var isFocused: Bool

    var body: some View {
        CameraView()
            .focusable(true)
            .focused($isFocused)
            .cameraAnchor(isActive: coordinator.isFocused(windowID: windowID))
            .onTapGesture { isFocused = true; coordinator.focus(windowID: windowID) }
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isFocused = true
                coordinator.focus(windowID: windowID)
                // Defer to the next runloop to ensure the first window is ready
                DispatchQueue.main.async {
                    openWindow(id: "camera.window.2")
                }
            }
    }
}

struct CameraAnchorWindowView: View {
    let windowID: String
    @StateObject private var coordinator = FocusCoordinator.shared
    @FocusState private var isFocused: Bool

    var body: some View {
        Color.clear
            .frame(minWidth: 1, minHeight: 1)
            .contentShape(Rectangle())
            .focusable(true)
            .focused($isFocused)
            .cameraAnchor(isActive: coordinator.isFocused(windowID: windowID))
            .onTapGesture { isFocused = true; coordinator.focus(windowID: windowID) }
    }
}

struct DebugFocusView: View {
    @StateObject private var coordinator = FocusCoordinator.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Focus Debug")
                .font(.headline)
            HStack {
                Text("currentWindowID:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(coordinator.currentWindowID ?? "nil")
                    .font(.system(.body, design: .monospaced))
            }
        }
        .padding()
        .frame(minWidth: 260, alignment: .leading)
    }
}

@main
struct Persona_AvatarApp: App {
    var body: some Scene {
        // Define three separate windows, each showing its own CameraView
        Window("Camera 1", id: "camera.window.1") {
            CameraLauncherView(windowID: "camera.window.1")
        }
        Window("Camera 2", id: "camera.window.2") {
            CameraAnchorWindowView(windowID: "camera.window.2")
        }
    }
}

#Preview("Camera 1 Window") {
    CameraLauncherView(windowID: "camera.window.preview")
}


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

let DEGREE_RESOLUTION:Float = 15

struct CameraLauncherView: View {
    let windowID: String
    let nextWindowID: String?
    @StateObject private var coordinator = FocusCoordinator.shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State private var didLaunch = false
    @FocusState private var isFocused: Bool

    var body: some View {
        CameraView()//EmptyView()
            .focusable(true)
            .focused($isFocused)
            .cameraAnchor(isActive: coordinator.isFocused(windowID: windowID))
            .onTapGesture { isFocused = true; coordinator.focus(windowID: windowID) }
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isFocused = true
                coordinator.focus(windowID: windowID)
                if let nextWindow = nextWindowID {
                    DispatchQueue.main.async {
                        openWindow(id: nextWindow)
                    }
                }
            }
    }
}

struct CameraAnchorWindowView: View {
    let windowID: String
    let nextWindowID: String?
    let immersiveSpaceID: String?
    @StateObject private var coordinator = FocusCoordinator.shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @FocusState private var isFocused: Bool

    var body: some View {
        Color.clear
            .frame(minWidth: 1, minHeight: 1)
            .contentShape(Rectangle())
            .focusable(true)
            .focused($isFocused)
            .cameraAnchor(isActive: coordinator.isFocused(windowID: windowID))
            .onTapGesture { isFocused = true; coordinator.focus(windowID: windowID) }
            .onAppear {
                // Defer to the next runloop to ensure the first window is ready
                if let nextWindow = nextWindowID {
                    DispatchQueue.main.async {
                        openWindow(id: nextWindow)
                    }
                }
                if let immersiveID = immersiveSpaceID {
                    DispatchQueue.main.async {
                        Task { await openImmersiveSpace(id: immersiveID) }
                    }
                }
            }
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
        .contentShape(Rectangle())
        .padding()
        .frame(minWidth: 260, minHeight: 100, alignment: .leading)
    }
}

@main
struct Persona_AvatarApp: App {
    var body: some Scene {
        let cameraID = "anchor.0"
        let anchorID_1 = "anchor.1"
        let anchorID_2 = "anchor.2"
        let anchorID_3 = "anchor.3"
        let anchorID_4 = "anchor.4"
        let anchorID_5 = "anchor.5"
        let anchorID_6 = "anchor.6"
        let anchorID_7 = "anchor.7"
        let anchorID_8 = "anchor.8"
        let anchorID_9 = "anchor.9"
        let anchorID_10 = "anchor.10"
        let anchorID_FINAL = "anchor.11"
        let immersiveSceneID = "headtracker.immersive"
        
        
        
        
        
        // Define three separate windows, each showing its own CameraView
        Window("Camera", id: cameraID) {
            CameraLauncherView(windowID: cameraID, nextWindowID: anchorID_1)
        }
        .defaultSize(width: 825, height: 500)
        
        Window(anchorID_1, id: anchorID_1) {
            CameraAnchorWindowView(windowID: anchorID_1, nextWindowID: anchorID_2, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == cameraID }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
                
        Window(anchorID_2, id: anchorID_2) {
            CameraAnchorWindowView(windowID: anchorID_2, nextWindowID: anchorID_3, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_1 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
           
        Window(anchorID_3, id: anchorID_3) {
            CameraAnchorWindowView(windowID: anchorID_3, nextWindowID: anchorID_4, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_2 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        Window(anchorID_4, id: anchorID_4) {
            CameraAnchorWindowView(windowID: anchorID_4, nextWindowID: anchorID_5, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_3 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        Window(anchorID_5, id: anchorID_5) {
            CameraAnchorWindowView(windowID: anchorID_5, nextWindowID: anchorID_6, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_4 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        Window(anchorID_6, id: anchorID_6) {
            CameraAnchorWindowView(windowID: anchorID_6, nextWindowID: anchorID_7, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_5 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        Window(anchorID_7, id: anchorID_7) {
            CameraAnchorWindowView(windowID: anchorID_7, nextWindowID: anchorID_8, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_6 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        Window(anchorID_8, id: anchorID_8) {
            CameraAnchorWindowView(windowID: anchorID_8, nextWindowID: anchorID_9, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_7 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        
        Window(anchorID_9, id: anchorID_9) {
            CameraAnchorWindowView(windowID: anchorID_9, nextWindowID: anchorID_10, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_8 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        
        Window(anchorID_10, id: anchorID_10) {
            CameraAnchorWindowView(windowID: anchorID_10, nextWindowID: anchorID_FINAL, immersiveSpaceID: nil)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == anchorID_9 }) {
                return WindowPlacement(.leading(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        
        
        
        
        Window("Final Anchor", id: anchorID_FINAL) {
            CameraAnchorWindowView(windowID: anchorID_FINAL, nextWindowID: nil, immersiveSpaceID: immersiveSceneID)
        }
        .defaultSize(width: 825, height: 500)
        .defaultWindowPlacement { _, context in
            if let targetWindow = context.windows.first(where: { $0.id == cameraID }) {
                return WindowPlacement(.trailing(targetWindow))
            }
            return WindowPlacement(.none)
        }
        
        ImmersiveSpace(id: "headtracker.immersive") {
            ImmersiveHUDView()
        }
    }
}


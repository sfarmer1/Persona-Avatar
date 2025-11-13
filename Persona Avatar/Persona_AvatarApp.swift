import SwiftUI
import Combine
import AVKit
import RealityKit

@MainActor
final class FocusCoordinator: ObservableObject {
    
    static let shared = FocusCoordinator()
    @Published var cameraFlipper: Bool = false
    private init() {}
}

let DEGREE_RESOLUTION:Float = 15

struct CameraLauncherView: View {
    let windowID: String
    let nextWindowID: String?
    let immersiveSpaceID: String?
    @StateObject private var coordinator = FocusCoordinator.shared
    @Environment(\.openWindow) private var openWindow
    @Environment(\.openImmersiveSpace) private var openImmersiveSpace
    @State private var didLaunch = false
    @FocusState private var isFocused: Bool

    var body: some View {
        EmptyView()
            .focusable(true)
            .focused($isFocused)
            //.cameraAnchor(isActive: false)
            .onAppear {
                guard !didLaunch else { return }
                didLaunch = true
                isFocused = true
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
            //.cameraAnchor(isActive: coordinator.isFocused(windowID: windowID))
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
            }
        }
        .contentShape(Rectangle())
        .padding()
        .frame(minWidth: 260, minHeight: 100, alignment: .leading)
    }
}

@main
struct Persona_AvatarApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openWindow) private var openWindow
    
    var body: some SwiftUI.Scene {
        let cameraID = "anchor.0"
        let immersiveSceneID = "headtracker.immersive"
        
        // Define three separate windows, each showing its own CameraView
        Window("Camera", id: cameraID) {
            CameraLauncherView(windowID: cameraID, nextWindowID: nil, immersiveSpaceID: immersiveSceneID)
            .task({
                WindowCameraKillerSystem.registerSystem()
            })
        }
        .defaultSize(width: 825, height: 500)
        
        ImmersiveSpace(id: immersiveSceneID) {
            ImmersiveHUDView()
        }
        .onChange(of: scenePhase) {
            switch scenePhase {
            case .background:
                /*DispatchQueue.main.async {
                    openWindow(id: cameraID)
                }*/
                break
            case .inactive:
                // Scene inactive, currently no action for this
                break
            case .active:
                /*DispatchQueue.main.async {
                    openWindow(id: cameraID)
                }*/
                break
            @unknown default:
                break
            }
        }
    }
}

